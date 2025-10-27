# Git Setup Guide

## 🚀 Quick Setup

```bash
# 1. Initialize Git repository
git init

# 2. Add all files
git add .

# 3. Create initial commit
git commit -m "Initial commit: High-performance C++ LOB simulator"

# 4. Add remote (replace with your repository URL)
git remote add origin https://github.com/yourusername/cpp-lob-simulator.git

# 5. Push to GitHub
git branch -M main
git push -u origin main
```

---

## 📋 Pre-commit Checklist

Before committing, ensure:

- ✅ Code compiles without errors: `cd build && cmake --build .`
- ✅ All tests pass: `./build/lob_tests`
- ✅ No build artifacts in git: check `.gitignore`
- ✅ README is up to date
- ✅ No sensitive data or credentials

---

## 🧹 What's Excluded (.gitignore)

The following are automatically excluded from Git:

**Build artifacts:**
- `build/` - CMake build directory
- `*.o`, `*.a`, `*.so` - Compiled files

**Generated data:**
- `data/benchmark_*.csv` - Large test files
- `data/large_test.csv`, `data/medium_test.csv`
- `data/*_depth.csv*`, `data/*_live.csv*` - Captured market data

**IDE/Editor files:**
- `.vscode/`, `.idea/`
- `*.swp`, `.DS_Store`

**Python:**
- `__pycache__/`, `*.pyc`
- `.venv/` - Virtual environment

---

## 📂 What's Included

**Source code:**
- `src/` - C++ implementation
- `include/` - Header files
- `tests/` - Unit tests
- `bindings/` - Python bindings
- `benchmarks/` - Benchmark code

**Configuration:**
- `CMakeLists.txt` - Build configuration
- `requirements.txt` - Python dependencies
- `.gitignore` - Git exclusions

**Documentation:**
- `README.md` - Main documentation
- `scripts/README.md` - Scripts guide

**Sample data:**
- `data/sample_orders.csv` - Example order stream (11 events)

**Scripts:**
- All Python and shell scripts in `scripts/`

---

## 🌳 Recommended Branch Strategy

```bash
# Main branch (stable releases)
main

# Development branch
git checkout -b develop

# Feature branches
git checkout -b feature/optimization
git checkout -b feature/new-order-types

# Bug fixes
git checkout -b fix/memory-leak
```

---

## 📝 Commit Message Guidelines

```bash
# Good commit messages:
git commit -m "Add market order support to matching engine"
git commit -m "Fix memory leak in order book cleanup"
git commit -m "Optimize price level insertion performance"
git commit -m "Update README with benchmark results"

# Format:
# <type>: <description>
#
# Types: feat, fix, docs, style, refactor, test, chore
```

---

## 🔄 Common Git Workflows

### Update after changes:
```bash
git status
git add .
git commit -m "Description of changes"
git push
```

### Create feature branch:
```bash
git checkout -b feature/my-feature
# ... make changes ...
git add .
git commit -m "Implement my feature"
git push -u origin feature/my-feature
```

### Merge feature back:
```bash
git checkout main
git merge feature/my-feature
git push
```

---

## 🏷️ Tagging Releases

```bash
# Create annotated tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push tags to remote
git push origin v1.0.0

# List tags
git tag -l
```

---

## 🔍 Verify Before Push

```bash
# Check what will be committed
git status

# Review changes
git diff

# Check ignored files are not tracked
git status --ignored

# Verify .gitignore is working
git check-ignore -v data/large_test.csv
```

---

## 🛠️ Useful Git Commands

```bash
# View commit history
git log --oneline

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# See what's ignored
git status --ignored

# Remove file from git but keep local
git rm --cached <file>
```

---

## 🌐 GitHub Repository Setup

1. **Create repository on GitHub** (public or private)

2. **Add description:**
   > High-performance C++20 limit order book simulator achieving 915K+ orders/sec with sub-microsecond latency

3. **Add topics:**
   - `cpp20`
   - `high-frequency-trading`
   - `limit-order-book`
   - `trading-simulator`
   - `quantitative-finance`
   - `performance-optimization`

4. **Add README badges** (optional):
   ```markdown
   ![C++20](https://img.shields.io/badge/C%2B%2B-20-blue.svg)
   ![License](https://img.shields.io/badge/license-Apache%202.0-green.svg)
   ```

---

## ✅ Final Checks

Before making repository public:

- [ ] Remove any sensitive data
- [ ] Verify README is professional
- [ ] Test that someone can clone and build
- [ ] Add LICENSE file if needed
- [ ] Check all links work
- [ ] Ensure performance claims are accurate

---

## 📧 License

Consider adding a LICENSE file. For academic/portfolio projects:

```bash
# MIT License (permissive)
curl -o LICENSE https://opensource.org/licenses/MIT

# Or Apache 2.0 (used in this project)
# Already specified in source files
```
