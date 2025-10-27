# Scripts Directory

Utility scripts for the LOB simulator.

## 📜 Available Scripts

### 1. **`generate_sample_data.py`** - Generate Synthetic Order Data
Creates realistic synthetic order streams for testing.

```bash
# Generate 10K events
python3 scripts/generate_sample_data.py --events 10000 --out data/test.csv

# Generate 1M events with specific seed
python3 scripts/generate_sample_data.py --events 1000000 --out data/stress.csv --seed 42
```

**Parameters:**
- `--events`: Number of events to generate
- `--out`: Output CSV file path
- `--seed`: Random seed for reproducibility

---

### 2. **`run_scenarios.sh`** - Quick-Start Menu
Interactive menu to run predefined scenarios.

```bash
bash scripts/run_scenarios.sh
```

**Scenarios:**
1. Basic test (sample data, 11 events)
2. Medium test (10K events, single-threaded)
3. Large test (100K events, 4 threads)
4. Latency simulation (10μs per event)
5. Stress test (100K events, 8 threads)
6. Run all scenarios
7. Run unit tests
8. Performance profiling
9. Custom parameters

---

### 3. **`profile.sh`** - Performance Profiling
Comprehensive performance analysis.

```bash
bash scripts/profile.sh
```

**Includes:**
- Time and memory profiling
- CPU sampling
- Statistical benchmarks (10 runs)
- Thread scaling analysis (1, 2, 4, 8 threads)
- Memory leak detection

**Outputs:**
- `/tmp/lob_profile_time.log` - Time/memory stats
- `/tmp/lob_cpu_profile.txt` - CPU profile
- `/tmp/lob_leaks.txt` - Memory leak report

---

### 4. **`benchmark_suite.sh`** - Comprehensive Benchmark Suite
Complete performance benchmarking with detailed metrics.

```bash
bash scripts/benchmark_suite.sh
```

**Features:**
- Peak single-threaded performance
- Thread scaling analysis
- Dataset size scaling
- Memory usage profiling
- Statistical analysis (5-run averages)

---

### 5. **`setup_python_bindings.sh`** - Python Bindings Setup
Installs dependencies and builds Python bindings.

```bash
bash scripts/setup_python_bindings.sh
```

**What it does:**
1. Checks Python installation
2. Installs `pybind11` via pip
3. Rebuilds CMake with `-DLOB_BUILD_PYTHON=ON`
4. Tests the Python module

---

### 6. **`test_python_bindings.py`** - Python API Tests
Test suite for Python bindings (requires setup first).

```bash
python3 scripts/test_python_bindings.py
```

**Tests:**
- Basic order book operations
- Order matching and trade execution
- Order cancellation
- Performance benchmark

---

### 7. **`binance_depth_capture.py`** - Real Market Data Capture
Captures live order book data from Binance WebSocket API.

```bash
# Install dependencies first
pip3 install aiohttp websockets orjson certifi

# Capture BTCUSDT depth data
python3 scripts/binance_depth_capture.py --symbol BTCUSDT --out data/btc_depth.csv.gz
```

**Parameters:**
- `--symbol`: Trading pair (e.g., BTCUSDT, ETHUSDT)
- `--limit`: Depth snapshot limit (default: 1000)
- `--out`: Output file (supports .gz compression)
- `--flush`: Flush interval in seconds (default: 1.0)

---

### 8. **`cleanup.sh`** - Clean Project for Git
Removes temporary files and build artifacts.

```bash
bash scripts/cleanup.sh
```

---

## 🚀 Quick Start

```bash
# 1. Generate test data
python3 scripts/generate_sample_data.py --events 100000 --out data/test.csv

# 2. Run interactive scenarios
bash scripts/run_scenarios.sh

# 3. Profile performance
bash scripts/profile.sh

# 4. (Optional) Setup Python bindings
bash scripts/setup_python_bindings.sh
python3 scripts/test_python_bindings.py
```

---

## 📦 Dependencies

Install Python dependencies:
```bash
pip3 install -r requirements.txt
```

Or install only what you need:
```bash
# For Python bindings only
pip3 install pybind11

# For Binance data capture
pip3 install aiohttp websockets orjson certifi

# For analysis
pip3 install pandas numpy matplotlib
```
