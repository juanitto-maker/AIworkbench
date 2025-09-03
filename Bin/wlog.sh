#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
T="${1:-$( [ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "" )}"
[ -z "$T" ] && { echo "❌ No active task."; exit 1; }

LOG="$AIWB/runner-logs/$T.log"
[ -f "$LOG" ] || { echo "❌ No log found for $T"; exit 0; }

if [[ "${2:-}" == "follow" || "$T" == "follow" ]]; then
  tail -f "$LOG"
else
  tail -n 100 "$LOG"
fi