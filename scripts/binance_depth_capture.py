#!/usr/bin/env python3
"""
Binance depth stream capture utility.

Usage:
  python scripts/binance_depth_capture.py --symbol BTCUSDT --out data/btcusdt_depth.csv.gz

- Grabs an initial depth snapshot via REST.
- Subscribes to the <symbol>@depth@100ms WebSocket.
- Applies incremental updates while verifying sequence IDs.
- Writes normalized CSV rows: unix_nanos,event_type,side,price,quantity,first_update,last_update

Requires: python3.9+, aiohttp, websockets, orjson.
"""

import argparse
import asyncio
import csv
import gzip
import logging
import ssl
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import aiohttp
import certifi
import orjson
import websockets
from websockets.exceptions import ConnectionClosedError, ConnectionClosedOK, InvalidURI, InvalidStatusCode

BINANCE_REST_DEPTH = "https://api.binance.com/api/v3/depth"
BINANCE_WS_DEPTH = "wss://stream.binance.com:9443/ws/{symbol_lower}@depth@100ms"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)


@dataclass
class DepthSnapshot:
    last_update_id: int
    bids: List[Tuple[float, float]]
    asks: List[Tuple[float, float]]


async def fetch_snapshot(session: aiohttp.ClientSession, symbol: str, limit: int) -> DepthSnapshot:
    params = {"symbol": symbol.upper(), "limit": limit}
    async with session.get(BINANCE_REST_DEPTH, params=params, timeout=10) as resp:
        resp.raise_for_status()
        payload = await resp.json()
        return DepthSnapshot(
            last_update_id=int(payload["lastUpdateId"]),
            bids=[(float(price), float(size)) for price, size in payload["bids"]],
            asks=[(float(price), float(size)) for price, size in payload["asks"]],
        )


class SequenceGapError(RuntimeError):
    """Raised when websocket updates indicate a missed sequence."""


def normalize_events(message: Dict[str, Any], snapshot: DepthSnapshot) -> Optional[List[Dict[str, Any]]]:
    first_update_id = int(message["U"])
    final_update_id = int(message["u"])
    event_time_ms = int(message["E"])

    # Binance docs: ignore updates that are older than the snapshot.
    if final_update_id <= snapshot.last_update_id:
        return None

    expected = snapshot.last_update_id + 1
    if first_update_id > expected or expected > final_update_id:
        raise SequenceGapError(
            f"Sequence gap detected: snapshot={snapshot.last_update_id} update=({first_update_id},{final_update_id})"
        )

    snapshot.last_update_id = final_update_id

    rows: List[Dict[str, Any]] = []
    unix_nanos = event_time_ms * 1_000_000

    for side, updates in (("BUY", message["b"]), ("SELL", message["a"])):
        for price_str, qty_str in updates:
            price = float(price_str)
            quantity = float(qty_str)
            event_type = "DELETE" if quantity == 0 else "UPSERT"
            rows.append(
                {
                    "timestamp": unix_nanos,
                    "event": event_type,
                    "side": side,
                    "price": price,
                    "quantity": quantity,
                    "first_update": first_update_id,
                    "last_update": final_update_id,
                }
            )

    return rows


async def capture_depth(symbol: str, limit: int, output_path: Path, flush_interval: float):
    ssl_context = ssl.create_default_context(cafile=certifi.where())
    connector = aiohttp.TCPConnector(ssl=ssl_context)

    async with aiohttp.ClientSession(connector=connector) as session:
        snapshot = await fetch_snapshot(session, symbol, limit)
        logging.info("Fetched snapshot lastUpdateId=%s", snapshot.last_update_id)

        ws_url = BINANCE_WS_DEPTH.format(symbol_lower=symbol.lower())
        logging.info("Connecting to %s", ws_url)

        output_path.parent.mkdir(parents=True, exist_ok=True)
        fieldnames = ["timestamp", "event", "side", "price", "quantity", "first_update", "last_update"]

        if output_path.exists():
            logging.warning("Overwriting existing capture file %s", output_path)
        use_gzip = output_path.suffix == ".gz"
        open_func = gzip.open if use_gzip else open

        with open_func(output_path, "wt", newline="") as data_file:
            writer = csv.DictWriter(data_file, fieldnames=fieldnames)
            writer.writeheader()
            data_file.flush()

            while True:
                buffered_rows: List[Dict[str, Any]] = []
                last_flush = time.time()
                resync_needed = False

                try:
                    async with websockets.connect(ws_url, ping_interval=10, ping_timeout=10, ssl=ssl_context) as ws:
                        async for raw in ws:
                            message = orjson.loads(raw)
                        try:
                            normalized = normalize_events(message, snapshot)
                        except SequenceGapError as err:
                            logging.warning("%s; refreshing snapshot", err)
                            if buffered_rows:
                                writer.writerows(buffered_rows)
                                data_file.flush()
                                logging.info("Flushed %d updates prior to resync", len(buffered_rows))
                                buffered_rows.clear()

                            snapshot = await fetch_snapshot(session, symbol, limit)
                            logging.info("Resynced snapshot lastUpdateId=%s", snapshot.last_update_id)
                            resync_needed = True
                            break

                            if not normalized:
                                continue
                            buffered_rows.extend(normalized)

                            now = time.time()
                            if now - last_flush >= flush_interval:
                                writer.writerows(buffered_rows)
                                data_file.flush()
                                logging.info("Flushed %d updates (last u=%s)", len(buffered_rows), message["u"])
                                buffered_rows.clear()
                                last_flush = now

                        if not resync_needed and buffered_rows:
                            writer.writerows(buffered_rows)
                            data_file.flush()
                except (ConnectionClosedError, ConnectionClosedOK, InvalidStatusCode, InvalidURI) as err:
                    logging.warning("WebSocket connection issue (%s); reconnecting in 1s", err)
                    await asyncio.sleep(1)
                    continue
                if resync_needed:
                    await asyncio.sleep(0.5)
                    continue


async def main():
    parser = argparse.ArgumentParser(description="Capture Binance depth stream to CSV.")
    parser.add_argument("--symbol", default="BTCUSDT", help="Trading pair symbol (e.g., BTCUSDT)")
    parser.add_argument("--limit", type=int, default=1000, help="Depth snapshot limit (default 1000)")
    parser.add_argument("--out", default=None, help="Output gzipped CSV path.")
    parser.add_argument("--flush", type=float, default=1.0, help="Flush interval in seconds.")
    args = parser.parse_args()

    out_path = Path(args.out) if args.out else Path("data") / f"{args.symbol.lower()}_depth_{datetime.utcnow():%Y%m%dT%H%M%S}.csv.gz"
    logging.info("Writing events to %s", out_path)
    await capture_depth(args.symbol, args.limit, out_path, args.flush)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logging.info("Capture stopped by user.")
