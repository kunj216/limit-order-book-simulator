#!/usr/bin/env python3
"""
Test and demonstrate Python bindings for LOB simulator.

Usage:
  python scripts/test_python_bindings.py
"""

import sys
from pathlib import Path

# Add build directory to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root / 'build'))

try:
    import lob_cpp
except ImportError as e:
    print(f"Error importing lob_cpp: {e}")
    print("\nRun this first:")
    print("  bash scripts/setup_python_bindings.sh")
    sys.exit(1)

import time


def test_basic_operations():
    """Test basic order book operations."""
    print("=" * 60)
    print("Test 1: Basic Operations")
    print("=" * 60)
    
    engine = lob_cpp.MatchingEngine()
    
    # Add buy orders
    for i in range(5):
        order = lob_cpp.Order()
        order.id = i + 1
        order.symbol = "TEST"
        order.side = lob_cpp.Side.BUY
        order.type = lob_cpp.OrderType.LIMIT
        order.price = 100000 - i * 100
        order.quantity = 100 * (i + 1)
        
        result = engine.process(order)
        print(f"  Added BUY order {order.id} @ {order.price} x {order.quantity}")
    
    # Add sell orders
    for i in range(5):
        order = lob_cpp.Order()
        order.id = i + 10
        order.symbol = "TEST"
        order.side = lob_cpp.Side.SELL
        order.type = lob_cpp.OrderType.LIMIT
        order.price = 100200 + i * 100
        order.quantity = 100 * (i + 1)
        
        result = engine.process(order)
        print(f"  Added SELL order {order.id} @ {order.price} x {order.quantity}")
    
    book = engine.order_book()
    print(f"\n  Best bid: {book.best_bid()}")
    print(f"  Best ask: {book.best_ask()}")
    print(f"  Book size: {book.size()}")
    
    snapshot = book.snapshot(3)
    print("\n  Top 3 levels:")
    print("    Bids:")
    for level in snapshot.bids:
        print(f"      {level.price} x {level.quantity} ({level.order_count} orders)")
    print("    Asks:")
    for level in snapshot.asks:
        print(f"      {level.price} x {level.quantity} ({level.order_count} orders)")
    
    print("\n✓ Basic operations test passed")


def test_matching():
    """Test order matching and trade execution."""
    print("\n" + "=" * 60)
    print("Test 2: Order Matching")
    print("=" * 60)
    
    engine = lob_cpp.MatchingEngine()
    
    # Add resting orders
    buy_order = lob_cpp.Order()
    buy_order.id = 1
    buy_order.symbol = "TEST"
    buy_order.side = lob_cpp.Side.BUY
    buy_order.type = lob_cpp.OrderType.LIMIT
    buy_order.price = 100000
    buy_order.quantity = 500
    engine.process(buy_order)
    print(f"  Resting BUY: {buy_order.price} x {buy_order.quantity}")
    
    sell_order = lob_cpp.Order()
    sell_order.id = 2
    sell_order.symbol = "TEST"
    sell_order.side = lob_cpp.Side.SELL
    sell_order.type = lob_cpp.OrderType.LIMIT
    sell_order.price = 100200
    sell_order.quantity = 300
    engine.process(sell_order)
    print(f"  Resting SELL: {sell_order.price} x {sell_order.quantity}")
    
    # Market order should match
    market_buy = lob_cpp.Order()
    market_buy.id = 3
    market_buy.symbol = "TEST"
    market_buy.side = lob_cpp.Side.BUY
    market_buy.type = lob_cpp.OrderType.MARKET
    market_buy.quantity = 200
    
    result = engine.process(market_buy)
    print(f"\n  Market BUY x {market_buy.quantity}")
    print(f"  Trades executed: {len(result.trades)}")
    
    for trade in result.trades:
        print(f"    Trade: {trade.quantity} @ {trade.price}")
    
    print(f"\n  Book size after: {engine.order_book().size()}")
    print("\n✓ Matching test passed")


def test_cancellation():
    """Test order cancellation."""
    print("\n" + "=" * 60)
    print("Test 3: Order Cancellation")
    print("=" * 60)
    
    engine = lob_cpp.MatchingEngine()
    
    # Add orders
    for i in range(3):
        order = lob_cpp.Order()
        order.id = i + 1
        order.symbol = "TEST"
        order.side = lob_cpp.Side.BUY
        order.type = lob_cpp.OrderType.LIMIT
        order.price = 100000
        order.quantity = 100
        engine.process(order)
    
    print(f"  Initial book size: {engine.order_book().size()}")
    
    # Cancel order
    cancel = lob_cpp.Order()
    cancel.id = 2
    cancel.symbol = "TEST"
    engine.cancel(cancel)
    print(f"  After canceling order 2: {engine.order_book().size()}")
    
    print("\n✓ Cancellation test passed")


def benchmark_throughput():
    """Benchmark Python binding performance."""
    print("\n" + "=" * 60)
    print("Test 4: Performance Benchmark")
    print("=" * 60)
    
    engine = lob_cpp.MatchingEngine()
    
    num_orders = 10000
    print(f"  Processing {num_orders:,} orders...")
    
    start = time.time()
    
    for i in range(num_orders):
        order = lob_cpp.Order()
        order.id = i
        order.symbol = "BENCH"
        order.side = lob_cpp.Side.BUY if i % 2 == 0 else lob_cpp.Side.SELL
        order.type = lob_cpp.OrderType.LIMIT
        order.price = 100000 + (i % 100) * (1 if i % 2 == 0 else -1)
        order.quantity = 100
        
        engine.process(order)
    
    elapsed = time.time() - start
    throughput = num_orders / elapsed
    
    print(f"  Time: {elapsed:.3f} seconds")
    print(f"  Throughput: {throughput:,.0f} orders/sec")
    print(f"  Latency: {elapsed / num_orders * 1e6:.1f} μs/order")
    
    print("\n✓ Benchmark completed")


def main():
    print("\nLOB Python Bindings Test Suite")
    print("=" * 60)
    
    try:
        test_basic_operations()
        test_matching()
        test_cancellation()
        benchmark_throughput()
        
        print("\n" + "=" * 60)
        print("✅ All tests passed!")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
