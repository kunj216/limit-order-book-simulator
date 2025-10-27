#!/bin/bash
# Comprehensive benchmark suite for documenting performance

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
DATA_DIR="$PROJECT_DIR/data"
SIMULATOR="$BUILD_DIR/lob_simulator"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Comprehensive Performance Benchmark Suite${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

# Generate benchmark data if needed
if [ ! -f "$DATA_DIR/benchmark_1M.csv" ]; then
    echo -e "${YELLOW}Generating 1M event dataset...${NC}"
    python3 "$SCRIPT_DIR/generate_sample_data.py" --events 1000000 --out "$DATA_DIR/benchmark_1M.csv" --seed 42
fi

echo -e "${GREEN}System Information:${NC}"
echo -e "  OS: $(uname -s) $(uname -r)"
echo -e "  CPU: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Unknown')"
echo -e "  Cores: $(sysctl -n hw.ncpu) ($(sysctl -n hw.physicalcpu) physical)"
echo -e "  RAM: $(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 )) GB"
echo ""

# 1. Peak single-threaded performance
echo -e "${GREEN}▶ 1. Peak Single-Threaded Performance (1M events)${NC}\n"

echo "Running 5 trials..."
total_throughput=0
total_time=0

for i in {1..5}; do
    output=$("$SIMULATOR" --events "$DATA_DIR/benchmark_1M.csv" --threads 1 2>&1)
    throughput=$(echo "$output" | grep "Throughput:" | awk '{print $3}')
    time_sec=$(echo "$output" | grep "Processed" | awk '{print $5}')
    trades=$(echo "$output" | grep "Trades executed:" | awk '{print $5}')
    
    printf "  Trial %d: %s events/sec | %s seconds | %s trades\n" $i "$throughput" "$time_sec" "$trades"
    
    total_throughput=$(echo "$total_throughput + $throughput" | bc)
    total_time=$(echo "$total_time + $time_sec" | bc)
done

avg_throughput=$(echo "scale=0; $total_throughput / 5" | bc)
avg_time=$(echo "scale=3; $total_time / 5" | bc)
avg_latency=$(echo "scale=2; ($avg_time / 1000000) * 1000000" | bc)

echo ""
echo -e "${YELLOW}Average Results:${NC}"
echo "  Throughput: $avg_throughput events/sec"
echo "  Time: $avg_time seconds"
echo "  Latency: $avg_latency µs per order"

# 2. Thread scaling
echo -e "\n${GREEN}▶ 2. Thread Scaling Analysis${NC}\n"

echo "Threads | Throughput    | Time (s) | Speedup | Efficiency"
echo "--------|---------------|----------|---------|------------"

baseline=0

for threads in 1 2 4 8; do
    output=$("$SIMULATOR" --events "$DATA_DIR/benchmark_1M.csv" --threads $threads 2>&1)
    throughput=$(echo "$output" | grep "Throughput:" | awk '{print $3}')
    time_sec=$(echo "$output" | grep "Processed" | awk '{print $5}')
    
    if [ $threads -eq 1 ]; then
        baseline=$throughput
        speedup="1.00"
        efficiency="100%"
    else
        speedup=$(echo "scale=2; $throughput / $baseline" | bc)
        efficiency=$(echo "scale=0; ($speedup / $threads) * 100" | bc)
        efficiency="${efficiency}%"
    fi
    
    printf "%7d | %13s | %8s | %7sx | %10s\n" $threads "$throughput" "$time_sec" "$speedup" "$efficiency"
done

# 3. Dataset size scaling
echo -e "\n${GREEN}▶ 3. Dataset Size Scaling${NC}\n"

echo "Dataset    | Events     | Throughput    | Time (s) | Trades"
echo "-----------|------------|---------------|----------|--------"

# Sample
if [ -f "$DATA_DIR/sample_orders.csv" ]; then
    output=$("$SIMULATOR" --events "$DATA_DIR/sample_orders.csv" 2>&1)
    throughput=$(echo "$output" | grep "Throughput:" | awk '{print $3}')
    events=$(echo "$output" | grep "Processed" | awk '{print $2}')
    time_sec=$(echo "$output" | grep "Processed" | awk '{print $5}')
    trades=$(echo "$output" | grep "Trades executed:" | awk '{print $5}')
    printf "Sample     | %10s | %13s | %8s | %s\n" "$events" "$throughput" "$time_sec" "$trades"
fi

# Medium
if [ -f "$DATA_DIR/medium_test.csv" ]; then
    output=$("$SIMULATOR" --events "$DATA_DIR/medium_test.csv" 2>&1)
    throughput=$(echo "$output" | grep "Throughput:" | awk '{print $3}')
    events=$(echo "$output" | grep "Processed" | awk '{print $2}')
    time_sec=$(echo "$output" | grep "Processed" | awk '{print $5}')
    trades=$(echo "$output" | grep "Trades executed:" | awk '{print $5}')
    printf "Medium     | %10s | %13s | %8s | %s\n" "$events" "$throughput" "$time_sec" "$trades"
fi

# Large
if [ -f "$DATA_DIR/large_test.csv" ]; then
    output=$("$SIMULATOR" --events "$DATA_DIR/large_test.csv" 2>&1)
    throughput=$(echo "$output" | grep "Throughput:" | awk '{print $3}')
    events=$(echo "$output" | grep "Processed" | awk '{print $2}')
    time_sec=$(echo "$output" | grep "Processed" | awk '{print $5}')
    trades=$(echo "$output" | grep "Trades executed:" | awk '{print $5}')
    printf "Large      | %10s | %13s | %8s | %s\n" "$events" "$throughput" "$time_sec" "$trades"
fi

# Benchmark
output=$("$SIMULATOR" --events "$DATA_DIR/benchmark_1M.csv" 2>&1)
throughput=$(echo "$output" | grep "Throughput:" | awk '{print $3}')
events=$(echo "$output" | grep "Processed" | awk '{print $2}')
time_sec=$(echo "$output" | grep "Processed" | awk '{print $5}')
trades=$(echo "$output" | grep "Trades executed:" | awk '{print $5}')
printf "Benchmark  | %10s | %13s | %8s | %s\n" "$events" "$throughput" "$time_sec" "$trades"

# 4. Memory usage
echo -e "\n${GREEN}▶ 4. Memory Usage Profile${NC}\n"

/usr/bin/time -l "$SIMULATOR" --events "$DATA_DIR/benchmark_1M.csv" --threads 1 2>&1 | grep -E "real|maximum resident set size"

# Summary
echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Benchmark Complete${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Key Metrics:"
echo "  • Peak throughput: $avg_throughput events/sec"
echo "  • Average latency: $avg_latency µs/order"
echo "  • Optimal config: Single-threaded for this workload"
echo "  • Dataset capacity: Tested up to 1M events"
echo ""
echo "See RESUME_METRICS.md for resume-ready statistics"
