#!/bin/bash
# Performance profiling script for LOB simulator

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
DATA_DIR="$PROJECT_DIR/data"
SIMULATOR="$BUILD_DIR/lob_simulator"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Generate data if needed
if [ ! -f "$DATA_DIR/large_test.csv" ]; then
    echo -e "${YELLOW}Generating test data...${NC}"
    python3 "$SCRIPT_DIR/generate_sample_data.py" --events 100000 --out "$DATA_DIR/large_test.csv" --seed 42
fi

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Performance Profiling Suite${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

# 1. Time and Memory profiling (macOS)
echo -e "${GREEN}▶ Time & Memory Profile${NC}"
echo -e "${YELLOW}Running with /usr/bin/time -l...${NC}\n"

/usr/bin/time -l "$SIMULATOR" --events "$DATA_DIR/large_test.csv" --threads 4 2>&1 | tee /tmp/lob_profile_time.log

echo -e "\n${GREEN}Time profile saved to /tmp/lob_profile_time.log${NC}"

# 2. CPU profiling with sample (macOS alternative to perf)
echo -e "\n${GREEN}▶ CPU Sampling Profile${NC}"
echo -e "${YELLOW}Running with sample (requires brief runtime)...${NC}\n"

# Run simulator in background and profile it
"$SIMULATOR" --events "$DATA_DIR/large_test.csv" --threads 4 &
SIM_PID=$!

# Sample for 2 seconds
sleep 0.5
if kill -0 $SIM_PID 2>/dev/null; then
    sample $SIM_PID 2 -file /tmp/lob_cpu_profile.txt 2>/dev/null || echo "Note: sample command may require additional permissions"
fi

wait $SIM_PID

if [ -f /tmp/lob_cpu_profile.txt ]; then
    echo -e "${GREEN}CPU profile saved to /tmp/lob_cpu_profile.txt${NC}"
    echo -e "${YELLOW}Top functions by sample count:${NC}"
    grep -A 20 "Call graph:" /tmp/lob_cpu_profile.txt 2>/dev/null | head -25 || true
fi

# 3. Multiple runs for statistical profiling
echo -e "\n${GREEN}▶ Statistical Benchmark (10 runs)${NC}\n"

echo "Run | Events/sec | Time (s) | Trades"
echo "----|------------|----------|-------"

sum_throughput=0
sum_time=0
runs=10

for i in $(seq 1 $runs); do
    output=$("$SIMULATOR" --events "$DATA_DIR/large_test.csv" --threads 4 2>&1)
    
    throughput=$(echo "$output" | grep "Throughput:" | awk '{print $3}')
    time_sec=$(echo "$output" | grep "Processed" | awk '{print $5}')
    trades=$(echo "$output" | grep "Trades executed:" | awk '{print $5}')
    
    printf "%3d | %10s | %8s | %s\n" $i "$throughput" "$time_sec" "$trades"
    
    sum_throughput=$(echo "$sum_throughput + $throughput" | bc)
    sum_time=$(echo "$sum_time + $time_sec" | bc)
done

avg_throughput=$(echo "scale=0; $sum_throughput / $runs" | bc)
avg_time=$(echo "scale=3; $sum_time / $runs" | bc)

echo "----|------------|----------|-------"
printf "AVG | %10s | %8s |\n" "$avg_throughput" "$avg_time"

# 4. Thread scaling analysis
echo -e "\n${GREEN}▶ Thread Scaling Analysis${NC}\n"

echo "Threads | Events/sec | Speedup"
echo "--------|------------|--------"

baseline_throughput=0

for threads in 1 2 4 8; do
    output=$("$SIMULATOR" --events "$DATA_DIR/large_test.csv" --threads $threads 2>&1)
    throughput=$(echo "$output" | grep "Throughput:" | awk '{print $3}')
    
    if [ $threads -eq 1 ]; then
        baseline_throughput=$throughput
        speedup="1.00x"
    else
        speedup=$(echo "scale=2; $throughput / $baseline_throughput" | bc)
        speedup="${speedup}x"
    fi
    
    printf "%7d | %10s | %s\n" $threads "$throughput" "$speedup"
done

# 5. Memory leak check (simple)
echo -e "\n${GREEN}▶ Memory Leak Detection${NC}"
echo -e "${YELLOW}Running multiple iterations to check for leaks...${NC}\n"

if command -v leaks &> /dev/null; then
    "$SIMULATOR" --events "$DATA_DIR/large_test.csv" --threads 1 &
    SIM_PID=$!
    sleep 0.5
    if kill -0 $SIM_PID 2>/dev/null; then
        leaks $SIM_PID > /tmp/lob_leaks.txt 2>&1 || true
        wait $SIM_PID
        if grep -q "0 leaks for 0 total leaked bytes" /tmp/lob_leaks.txt; then
            echo -e "${GREEN}✓ No memory leaks detected${NC}"
        else
            echo -e "${YELLOW}⚠ Potential leaks found. Check /tmp/lob_leaks.txt${NC}"
        fi
    else
        wait $SIM_PID
        echo "Process completed too quickly for leak detection"
    fi
else
    echo "leaks command not available"
fi

# Summary
echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Profiling Complete${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "\nProfile outputs:"
echo "  • Time/Memory: /tmp/lob_profile_time.log"
echo "  • CPU samples: /tmp/lob_cpu_profile.txt"
echo "  • Memory leaks: /tmp/lob_leaks.txt"
echo ""
echo "For deeper analysis, consider:"
echo "  • Instruments.app (Xcode)"
echo "  • Valgrind (via Homebrew)"
echo "  • Google pprof (via benchmark integration)"
