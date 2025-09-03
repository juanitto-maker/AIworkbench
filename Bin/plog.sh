#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
. ~/bin/paths.sh

[ -s "$CURRENT_PROJECT_FILE" ] || { echo "No active project. Use pset."; exit 1; }
[ -s "$CURRENT_TASK_FILE" ]     || { echo "No active task. Use tnew."; exit 1; }

P="$(cat "$CURRENT_PROJECT_FILE")"
T="$(cat "$CURRENT_TASK_FILE")"
PROJ="$PROJ_ROOT/$P"
LOG="$PROJ/logs/costs.log"
mkdir -p "$(dirname "$LOG")"

STAMP="$(date +'%Y-%m-%d %H:%M:%S')"
echo "[$STAMP] project=$P task=$T model=$1 words=$2 inTok=$3 outTok=$4 usd_in=$5 usd_out=$6 usd_tot=$7" >> "$LOG"
echo "📝 appended → $LOG"