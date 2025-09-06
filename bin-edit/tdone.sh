#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
T="${1:-$( [ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "" )}"
[ -n "$T" ] || { echo "No active task."; exit 1; }
echo "DONE" > "$HOME/temp/$T.status.txt"
echo "✅ $T marked DONE."