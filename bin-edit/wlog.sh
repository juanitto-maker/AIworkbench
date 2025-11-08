#!/usr/bin/env bash
set -euo pipefail

AIWB="${AIWB:-$HOME/.aiwb/workspace}"
T="${1:-$( [ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "" )}"
[ -z "$T" ] && { echo "❌ No active task."; exit 1; }

LOG="$AIWB/runner-logs/$T.log"
[ -f "$LOG" ] || { echo "❌ No log found for $T"; exit 0; }

if [[ "${2:-}" == "follow" || "$T" == "follow" ]]; then
  tail -f "$LOG"
else
  tail -n 100 "$LOG"
fi