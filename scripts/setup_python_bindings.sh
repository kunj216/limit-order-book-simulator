#!/bin/bash
# Setup Python bindings for LOB simulator

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Python Bindings Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python3 not found${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version)
echo -e "${GREEN}✓ Found $PYTHON_VERSION${NC}"

# Install pybind11
echo -e "\n${YELLOW}Installing pybind11...${NC}"

if python3 -c "import pybind11" 2>/dev/null; then
    echo -e "${GREEN}✓ pybind11 already installed${NC}"
    PYBIND_VERSION=$(python3 -c "import pybind11; print(pybind11.__version__)")
    echo -e "  Version: $PYBIND_VERSION"
else
    echo "Installing via pip..."
    python3 -m pip install pybind11 || {
        echo -e "${RED}✗ Failed to install pybind11${NC}"
        echo "Try: python3 -m pip install --user pybind11"
        exit 1
    }
    echo -e "${GREEN}✓ pybind11 installed${NC}"
fi

# Rebuild with Python bindings
echo -e "\n${YELLOW}Rebuilding with Python bindings enabled...${NC}"

cd "$BUILD_DIR"
cmake .. -DLOB_BUILD_PYTHON=ON -DPython3_EXECUTABLE=$(which python3)

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ CMake configuration failed${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Building Python module...${NC}"
cmake --build . --target lob_cpp -j4

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

# Find the built module
MODULE_PATH=$(find "$BUILD_DIR" -name "lob_cpp*.so" | head -1)

if [ -z "$MODULE_PATH" ]; then
    echo -e "${RED}✗ Python module not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Module built: $MODULE_PATH${NC}"

# Test the module
echo -e "\n${YELLOW}Testing Python module...${NC}"

cd "$PROJECT_DIR"

python3 << 'EOF'
import sys
sys.path.insert(0, 'build')

try:
    import lob_cpp
    print("✓ Module imported successfully")
    
    # Test basic functionality
    engine = lob_cpp.MatchingEngine()
    print("✓ MatchingEngine created")
    
    order = lob_cpp.Order()
    order.id = 1
    order.symbol = "TEST"
    order.side = lob_cpp.Side.BUY
    order.type = lob_cpp.OrderType.LIMIT
    order.price = 100000
    order.quantity = 100
    
    result = engine.process(order)
    print("✓ Order processed")
    
    print(f"✓ Best bid: {engine.order_book().best_bid()}")
    print(f"✓ Order book size: {engine.order_book().size()}")
    
    print("\n✅ All tests passed!")
    
except Exception as e:
    print(f"✗ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Python bindings ready!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "\nUsage in Python:"
    echo -e "  ${YELLOW}import sys${NC}"
    echo -e "  ${YELLOW}sys.path.insert(0, 'build')${NC}"
    echo -e "  ${YELLOW}import lob_cpp${NC}"
    echo ""
    echo -e "See ${BLUE}scripts/test_python_bindings.py${NC} for examples"
else
    echo -e "\n${RED}✗ Python bindings test failed${NC}"
    exit 1
fi
