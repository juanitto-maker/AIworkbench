#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
UP="$AIWB/uploads"
mkdir -p "$UP"
echo "📁 $UP"
ls -lah "$UP"