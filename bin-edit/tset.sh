#!/usr/bin/env bash
set -o pipefail
T="${1:-}"; [ -z "$T" ] && { echo "Usage: tset <TASK_ID>"; exit 1; }
AIWB="${AIWB:-$HOME/.aiwb/workspace}"
echo "$T" > "$AIWB/current.task"
echo "📌 Active task: $T"