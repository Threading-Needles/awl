#!/usr/bin/env bash
set -euo pipefail

echo "Checking PM plugin prerequisites..."

# Check for gh CLI (GitHub operations — required for sync_prs)
if ! command -v gh &> /dev/null; then
    echo "⚠️  GitHub CLI not found (required for sync_prs, optional for other commands)"
    echo "Install with:"
    echo "  brew install gh  # macOS"
    echo "  See: https://cli.github.com"
else
    echo "✅ GitHub CLI found: $(gh --version | head -n1)"
fi

echo ""
echo "✅ Prerequisites check complete"
exit 0
