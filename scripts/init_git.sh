#!/bin/bash
# Initialize Git repository with professional setup

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🚀 Setting up Git repository for LOB Simulator"
echo ""

cd "$PROJECT_DIR"

# Check if already a git repo
if [ -d ".git" ]; then
    echo "⚠️  Git repository already exists!"
    echo ""
    read -p "Do you want to reinitialize? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
    rm -rf .git
fi

# Initialize Git
echo "📦 Initializing Git repository..."
git init

# Configure Git (optional, skip if already configured globally)
if [ -z "$(git config user.name)" ]; then
    echo ""
    read -p "Enter your name for Git commits: " git_name
    git config user.name "$git_name"
fi

if [ -z "$(git config user.email)" ]; then
    read -p "Enter your email for Git commits: " git_email
    git config user.email "$git_email"
fi

# Add all files
echo ""
echo "📝 Adding files to Git..."
git add .

# Show what will be committed
echo ""
echo "Files to be committed:"
git status --short

# Create initial commit
echo ""
read -p "Create initial commit? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Staged but not committed. Run 'git commit -m \"Your message\"' when ready."
else
    git commit -m "Initial commit: High-performance C++ LOB simulator

- C++20 limit order book matching engine
- Achieves 915K+ orders/sec with sub-microsecond latency
- Multi-threaded architecture with thread scaling support
- Python bindings via pybind11
- Comprehensive benchmarking and profiling tools
- Real-time market data capture support"
    
    echo ""
    echo "✅ Initial commit created!"
fi

# Ask about remote repository
echo ""
read -p "Do you want to add a remote repository? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Examples:"
    echo "  GitHub: https://github.com/username/cpp-lob-simulator.git"
    echo "  GitLab: https://gitlab.com/username/cpp-lob-simulator.git"
    echo ""
    read -p "Enter remote repository URL: " remote_url
    
    if [ -n "$remote_url" ]; then
        git remote add origin "$remote_url"
        echo "✅ Remote 'origin' added: $remote_url"
        echo ""
        echo "To push your code:"
        echo "  git branch -M main"
        echo "  git push -u origin main"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════"
echo "✅ Git setup complete!"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Review: git status"
echo "  2. Check: git log --oneline"
echo "  3. Push to remote (if configured)"
echo ""
echo "See GIT_SETUP.md for detailed Git workflow guide"
