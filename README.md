# C++ Limit Order Book Simulator

A multi-threaded limit order book implementation in C++20 for modeling electronic market microstructure and evaluating matching engine performance.

## Overview

Electronic exchanges use limit order books as the core data structure for order matching. This implementation provides a realistic matching engine with price-time priority, supporting limit orders, market orders, and standard order lifecycle operations (new, cancel, modify).

The simulator processes order streams and maintains consistent bid-ask state while tracking execution statistics and market microstructure metrics.

## Design Goals

- Deterministic matching with O(log n) insertion and deletion complexity
- Process order streams at 915K+ events/sec with sub-microsecond latency
- Maintain full order book depth and compute microstructure analytics
- Provide Python bindings for quantitative analysis and strategy development
- Benchmark performance across different threading configurations and workload patterns

## Architecture

```
src/
├── analytics.cpp        # Microstructure metrics (spread, depth, imbalance)
├── matching_engine.cpp  # Core matching logic and order lifecycle
├── order_book.cpp       # Price-level management with price-time priority
├── simulator.cpp        # Multi-threaded event processing
└── main.cpp             # CLI interface

include/                 # Public API headers
tests/                   # Unit tests (Catch2 framework)
benchmarks/              # Performance microbenchmarks
bindings/                # Python bindings (pybind11)
scripts/                 # Utilities for data generation and profiling
```

## Implementation Details

### Order Book
Uses `std::map` for price levels and `std::list` for intra-level ordering. Provides O(log n) insertion/deletion with constant-time best bid/ask access. Maintains price-time priority through sequential insertion into level queues.

### Matching Engine
Processes order events with immediate matching against resting orders. Supports:
- Limit orders with price-time priority
- Market orders with immediate execution
- Order cancellation and modification
- Trade generation and residual handling

### Simulator
Multi-threaded event processor using `std::thread` for concurrent order handling. Supports configurable threading models and latency simulation via `std::chrono`. Processes events from CSV files with nanosecond timestamp precision.

### Analytics Module
Computes real-time market microstructure metrics:
- Bid-ask spread (absolute and relative)
- Mid-price calculation
- Order book imbalance
- Depth at multiple price levels

## Performance Characteristics

The implementation achieves the following on MacBook Air M1:
- Single-threaded: 915K orders/sec, 1.09 µs average latency
- Dataset scaling: 10K-1M+ events with consistent throughput
- Memory efficient with price-level pooling

Theoretical peak on Intel i7-12700H: 1.2M orders/sec multi-threaded.

Technical features:
- Lock-based synchronization using `std::mutex` for order book access
- Nanosecond precision timestamps via `std::chrono::steady_clock`
- Zero-copy event processing where possible
- Configurable threading with `std::atomic` for coordination

## Usage

### Command Line Interface

```bash
./lob_simulator --events <path> [--threads <n>] [--latency-us <n>]

# Process sample data
./lob_simulator --events data/sample_orders.csv

# Single-threaded benchmark
./lob_simulator --events data/benchmark_1M.csv --threads 1

# Multi-threaded with artificial latency
./lob_simulator --events data/large_test.csv --threads 4 --latency-us 10
```

### Output Format

```
[INFO] Processed 1000000 events in 1.092 seconds
[INFO] Throughput: 915675 events/sec | Trades executed: 801265
[BOOK] Size: 197963 | Spread: 4620.000 | Mid: 97610.000 | Imbalance: 0.165
Top of book (5 levels):
  Bids:
    95300 x 21422 (44)
    95290 x 176626 (342)
  Asks:
    99920 x 784508 (1454)
    99930 x 773133 (1463)
```

### Utility Scripts

```bash
# Generate synthetic order data
python3 scripts/generate_sample_data.py --events 1000000 --out data/test.csv

# Run predefined test scenarios
bash scripts/run_scenarios.sh

# Comprehensive performance profiling
bash scripts/profile.sh
```

### Python Bindings

```python
import lob_cpp

engine = lob_cpp.MatchingEngine()
order = lob_cpp.Order()
order.id = 1
order.side = lob_cpp.Side.BUY
order.type = lob_cpp.OrderType.LIMIT
order.price = 100_500
order.quantity = 200

engine.process(order)
print(engine.order_book().best_bid())
```

## Benchmarks

### Measured Performance (MacBook Air M1, macOS)

| Configuration              | Throughput (orders/sec) | Latency per Order |
| -------------------------- | ----------------------: | ----------------: |
| Single-threaded (1M)       |                 915,675 |          1.09 µs |
| Sustained average (5 runs) |                 874,126 |          1.14 µs |
| Medium dataset (10K)       |                 485,266 |          2.06 µs |
| Large dataset (100K)       |                 443,686 |          2.25 µs |

### Reference Benchmarks (Intel i7-12700H, Ubuntu 22.04)

| Configuration              | Throughput (orders/sec) | Median Latency |
| -------------------------- | ----------------------: | -------------: |
| Python baseline            |                  45,000 |         8.1 ms |
| C++ single-thread          |                 915,000 |       1.09 µs |
| C++ multi-thread (4 cores) |               1,220,000 |         46 µs |

## Testing

### Unit Tests
Catch2 framework with 14 assertions across 3 test suites covering:
- Order book operations (insert, cancel, modify)
- Matching engine logic (limit/market orders, price-time priority)
- Analytics calculations (spread, imbalance, depth)

### Performance Testing
Automated profiling suite includes:
- Thread scaling analysis (1, 2, 4, 8 threads)
- Statistical benchmarking (10-run averages with variance)
- Memory profiling and leak detection
- CPU sampling and hotspot identification

### Validation
- Synthetic order streams up to 10^6 events
- Mid-price consistency checks
- Spread distribution analysis
- Order book depth verification

```bash
# Run unit tests
./build/lob_tests

# Performance profiling
bash scripts/profile.sh

# Test Python bindings
python3 scripts/test_python_bindings.py
```

## Build Instructions

### Requirements

* C++20 compiler (GCC 11+, Clang 13+, or MSVC 19.29+)
* CMake 3.16 or later
* Catch2 (vendored in `tests/`)
* pybind11 (optional, for Python bindings)

### Compilation

```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . -j$(nproc)
```

### Running Tests

```bash
cd build
./lob_tests

# or using CTest
ctest --output-on-failure
```

### Python Bindings (Optional)

```bash
# Install dependencies
pip3 install pybind11

# Build bindings
cd build
cmake .. -DLOB_BUILD_PYTHON=ON -DPython3_EXECUTABLE=$(which python3)
cmake --build . --target lob_cpp
```

### Data Generation

```bash
# Generate synthetic order stream
python3 scripts/generate_sample_data.py --events 100000 --out data/test.csv --seed 42
```

## Python Dependencies

Optional packages for extended functionality:

```bash
pip3 install -r requirements.txt
```

Includes:
- `pybind11` - C++ bindings
- `aiohttp`, `websockets`, `orjson` - Market data capture
- `pandas`, `numpy`, `matplotlib` - Analysis tools

## Possible Extensions

- Agent-based market simulation (market makers, informed traders)
- GPU acceleration for parallel order book updates
- Statistical calibration using Hawkes processes
- Real-time visualization via WebSocket streaming
- Reinforcement learning integration for strategy optimization


