#!/bin/bash
# Clean up project for professional Git repository

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🧹 Cleaning up LOB Simulator project..."
echo ""

# Remove temporary documentation files
echo "📄 Removing temporary documentation..."
rm -f "$PROJECT_DIR/QUICKSTART.md"
rm -f "$PROJECT_DIR/RESUME_METRICS.md"
rm -f "$PROJECT_DIR/SETUP_COMPLETE.md"
rm -f "$PROJECT_DIR/README_UPDATE_SUMMARY.md"

# Remove generated test data (keep only sample)
echo "📊 Cleaning generated test data..."
rm -f "$PROJECT_DIR/data/benchmark_1M.csv"
rm -f "$PROJECT_DIR/data/large_test.csv"
rm -f "$PROJECT_DIR/data/medium_test.csv"
rm -f "$PROJECT_DIR/data/test_capture.csv.gz"

# Remove build artifacts
echo "🔨 Removing build artifacts..."
if [ -d "$PROJECT_DIR/build" ]; then
    cd "$PROJECT_DIR/build"
    rm -f .ninja_deps .ninja_log
    rm -rf CMakeFiles/ Testing/
    cd "$PROJECT_DIR"
fi

# Remove Python venv
if [ -d "$PROJECT_DIR/.venv" ]; then
    echo "🐍 Removing Python virtual environment..."
    rm -rf "$PROJECT_DIR/.venv"
fi

# Remove __pycache__
find "$PROJECT_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

# Remove .DS_Store files (macOS)
find "$PROJECT_DIR" -name ".DS_Store" -delete 2>/dev/null || true

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Kept files:"
echo "  ✓ README.md (main documentation)"
echo "  ✓ scripts/README.md (scripts documentation)"
echo "  ✓ data/sample_orders.csv (example data)"
echo "  ✓ All source code"
echo "  ✓ Build configuration"
echo ""
echo "Next steps:"
echo "  1. Review README.md"
echo "  2. Initialize Git: git init"
echo "  3. Add files: git add ."
echo "  4. Commit: git commit -m 'Initial commit: High-performance LOB simulator'"
echo ""
