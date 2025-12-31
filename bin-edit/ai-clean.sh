#!/usr/bin/env bash
# Remove .bak files and empty directories in current repo
set -eo pipefail
find . -type f -name "*.bak" -delete 2>/dev/null || true
find . -type d -empty -delete 2>/dev/null || true
echo "🧹 Cleaned .bak files & empty dirs."