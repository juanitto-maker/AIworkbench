#!/usr/bin/env bash
set -o pipefail
AIWB="${AIWB:-$HOME/.aiwb/workspace}"
T="${1:-$( [ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "" )}"
[ -n "$T" ] || { echo "No active task."; exit 1; }
echo "DONE" > "$HOME/temp/$T.status.txt"
echo "✅ $T marked DONE."