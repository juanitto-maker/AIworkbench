#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
T="${1:-}"; [ -z "$T" ] && { echo "Usage: tset <TASK_ID>"; exit 1; }
AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
echo "$T" > "$AIWB/current.task"
echo "📌 Active task: $T"