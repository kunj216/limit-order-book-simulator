#!/bin/bash
# Quick-start script for running various LOB simulator scenarios

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
DATA_DIR="$PROJECT_DIR/data"
SIMULATOR="$BUILD_DIR/lob_simulator"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  LOB Simulator - Quick Start Scenarios${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

# Check if simulator exists
if [ ! -f "$SIMULATOR" ]; then
    echo -e "${YELLOW}⚠ Simulator not built. Building now...${NC}"
    cd "$BUILD_DIR"
    cmake --build . -j4
    cd "$PROJECT_DIR"
fi

# Function to run a scenario
run_scenario() {
    local name="$1"
    local data_file="$2"
    shift 2
    local args="$@"
    
    echo -e "\n${GREEN}▶ Scenario: $name${NC}"
    echo -e "${YELLOW}Command: $SIMULATOR --events $data_file $args${NC}\n"
    
    "$SIMULATOR" --events "$data_file" $args
    echo -e "${GREEN}✓ Completed${NC}"
}

# Generate test data if needed
if [ ! -f "$DATA_DIR/medium_test.csv" ]; then
    echo -e "${YELLOW}⚠ Generating test data...${NC}"
    python3 "$SCRIPT_DIR/generate_sample_data.py" --events 10000 --out "$DATA_DIR/medium_test.csv" --seed 42
    python3 "$SCRIPT_DIR/generate_sample_data.py" --events 100000 --out "$DATA_DIR/large_test.csv" --seed 123
fi

# Menu
echo "Select a scenario to run:"
echo "  1) Basic - Sample data (11 events)"
echo "  2) Medium - 10K events, single-threaded"
echo "  3) Large - 100K events, multi-threaded (4 cores)"
echo "  4) Latency Test - 10K events with 10μs simulated latency"
echo "  5) Stress Test - 100K events, 8 threads, latency simulation"
echo "  6) All scenarios"
echo "  7) Run tests"
echo "  8) Performance profiling (time + memory)"
echo "  9) Custom (enter your own parameters)"
echo ""
read -p "Choose [1-9]: " choice

case $choice in
    1)
        run_scenario "Basic Test" "$DATA_DIR/sample_orders.csv"
        ;;
    2)
        run_scenario "Medium Test" "$DATA_DIR/medium_test.csv" --threads 1
        ;;
    3)
        run_scenario "Large Multi-threaded" "$DATA_DIR/large_test.csv" --threads 4
        ;;
    4)
        run_scenario "Latency Test" "$DATA_DIR/medium_test.csv" --threads 1 --latency-us 10
        ;;
    5)
        run_scenario "Stress Test" "$DATA_DIR/large_test.csv" --threads 8 --latency-us 5
        ;;
    6)
        run_scenario "1. Basic" "$DATA_DIR/sample_orders.csv"
        run_scenario "2. Medium" "$DATA_DIR/medium_test.csv" --threads 1
        run_scenario "3. Large Multi-threaded" "$DATA_DIR/large_test.csv" --threads 4
        run_scenario "4. Latency" "$DATA_DIR/medium_test.csv" --threads 1 --latency-us 10
        run_scenario "5. Stress" "$DATA_DIR/large_test.csv" --threads 8 --latency-us 5
        ;;
    7)
        echo -e "\n${GREEN}▶ Running Unit Tests${NC}\n"
        cd "$BUILD_DIR"
        ./lob_tests
        echo -e "${GREEN}✓ All tests passed${NC}"
        ;;
    8)
        echo -e "\n${GREEN}▶ Performance Profiling${NC}\n"
        
        # Time profiling
        echo -e "${YELLOW}Time profile (large dataset):${NC}"
        /usr/bin/time -l "$SIMULATOR" --events "$DATA_DIR/large_test.csv" --threads 4
        
        echo -e "\n${YELLOW}Running with instruments (dtrace)...${NC}"
        echo "Note: May require sudo privileges for full profiling"
        ;;
    9)
        echo ""
        read -p "Data file (relative to $DATA_DIR): " datafile
        read -p "Number of threads [4]: " threads
        threads=${threads:-4}
        read -p "Latency in μs [0 = disabled]: " latency
        
        extra_args="--threads $threads"
        if [ "$latency" != "0" ] && [ -n "$latency" ]; then
            extra_args="$extra_args --latency-us $latency"
        fi
        
        run_scenario "Custom" "$DATA_DIR/$datafile" $extra_args
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Done!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
