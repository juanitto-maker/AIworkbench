#!/data/data/com.termux/files/usr/bin/bash
# Remove .bak files and empty directories in current repo
set -euo pipefail
find . -type f -name "*.bak" -delete 2>/dev/null || true
find . -type d -empty -delete 2>/dev/null || true
echo "🧹 Cleaned .bak files & empty dirs."