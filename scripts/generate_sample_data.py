#!/usr/bin/env python3
"""
Generate synthetic LOB order stream for testing.

Usage:
  python scripts/generate_sample_data.py --events 100000 --out data/large_test.csv
  python scripts/generate_sample_data.py --events 1000000 --out data/stress_test.csv --seed 42
"""

import argparse
import csv
import random
from pathlib import Path
from typing import List, Dict


def generate_order_stream(num_events: int, seed: int = None) -> List[Dict]:
    """Generate realistic order stream with Poisson arrivals."""
    if seed is not None:
        random.seed(seed)
    
    events = []
    timestamp = 1_000_000_000  # Start at 1 second
    next_id = 1
    active_orders = {}  # Track active order IDs for cancellations
    
    # Initial mid-price
    mid_price = 100_000
    tick_size = 10
    
    # Market parameters
    spread_ticks = 10
    volatility = 0.0005  # Price drift
    cancel_prob = 0.0  # Disabled for simplicity
    modify_prob = 0.0  # Disabled for simplicity
    market_order_prob = 0.10
    
    for i in range(num_events):
        # Poisson-like time intervals (exponential)
        inter_arrival = int(random.expovariate(1.0 / 500))  # ~500 ns mean
        timestamp += max(100, inter_arrival)
        
        # Random walk mid-price
        if random.random() < 0.1:
            mid_price += random.choice([-tick_size, tick_size])
            mid_price = max(50_000, min(150_000, mid_price))
        
        event_type = random.random()
        
        # Cancel existing order
        if active_orders and event_type < cancel_prob:
            order_id = random.choice(list(active_orders.keys()))
            # For CANCEL: only timestamp, event, id needed
            # But we need 7 columns to match the format
            events.append({
                'timestamp': timestamp,
                'event': 'CANCEL',
                'id': order_id,
                'side': '',
                'type': '',
                'price': '',
                'quantity': ''
            })
            del active_orders[order_id]
        
        # Modify existing order
        elif active_orders and event_type < cancel_prob + modify_prob:
            order_id = random.choice(list(active_orders.keys()))
            old_order = active_orders[order_id]
            new_qty = random.randint(50, 1000)
            new_price = old_order['price'] + random.choice([-tick_size, 0, tick_size])
            
            # For MODIFY: timestamp,event,id,new_qty,new_price,side
            # But stored in the standard 7-column format (reuse columns)
            events.append({
                'timestamp': timestamp,
                'event': 'MODIFY',
                'id': order_id,
                'side': new_qty,  # new_quantity goes in side column
                'type': new_price,  # new_price goes in type column
                'price': old_order['side'],  # side goes in price column
                'quantity': ''
            })
            active_orders[order_id]['price'] = new_price
            active_orders[order_id]['quantity'] = new_qty
        
        # Market order
        elif event_type < cancel_prob + modify_prob + market_order_prob:
            side = random.choice(['BUY', 'SELL'])
            qty = random.randint(50, 500)
            
            events.append({
                'timestamp': timestamp,
                'event': 'NEW',
                'id': next_id,
                'side': side,
                'type': 'MARKET',
                'price': 0,
                'quantity': qty
            })
            next_id += 1
        
        # New limit order
        else:
            side = random.choice(['BUY', 'SELL'])
            
            # Generate prices around mid with realistic distribution
            if side == 'BUY':
                # Bids below mid
                offset_ticks = random.choices(
                    range(spread_ticks // 2, 100),
                    weights=[1 / (i + 1) for i in range(spread_ticks // 2, 100)]
                )[0]
                price = mid_price - offset_ticks * tick_size
            else:
                # Asks above mid
                offset_ticks = random.choices(
                    range(spread_ticks // 2, 100),
                    weights=[1 / (i + 1) for i in range(spread_ticks // 2, 100)]
                )[0]
                price = mid_price + offset_ticks * tick_size
            
            price = max(tick_size, price)
            qty = random.randint(50, 1000)
            
            events.append({
                'timestamp': timestamp,
                'event': 'NEW',
                'id': next_id,
                'side': side,
                'type': 'LIMIT',
                'price': price,
                'quantity': qty
            })
            
            active_orders[next_id] = {
                'side': side,
                'price': price,
                'quantity': qty
            }
            next_id += 1
    
    return events


def main():
    parser = argparse.ArgumentParser(description='Generate synthetic order stream')
    parser.add_argument('--events', type=int, default=10000, 
                       help='Number of events to generate')
    parser.add_argument('--out', type=str, default='data/generated_orders.csv',
                       help='Output CSV file path')
    parser.add_argument('--seed', type=int, default=None,
                       help='Random seed for reproducibility')
    args = parser.parse_args()
    
    print(f"Generating {args.events:,} events...")
    events = generate_order_stream(args.events, args.seed)
    
    output_path = Path(args.out)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    fieldnames = ['timestamp', 'event', 'id', 'side', 'type', 'price', 'quantity']
    
    with open(output_path, 'w', newline='') as f:
        # Write header with # prefix (matching sample_orders.csv format)
        f.write('#' + ','.join(fieldnames) + '\n')
        
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writerows(events)
    
    print(f"✓ Wrote {len(events):,} events to {output_path}")
    print(f"  File size: {output_path.stat().st_size / 1024:.1f} KB")


if __name__ == '__main__':
    main()
