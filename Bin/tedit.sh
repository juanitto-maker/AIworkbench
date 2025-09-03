#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
. ~/bin/paths.sh

# need project & task
[ -s "$CURRENT_PROJECT_FILE" ] || { echo "No active project. Use pset."; exit 1; }
[ -s "$CURRENT_TASK_FILE" ]     || { echo "No active task. Use tnew."; exit 1; }

P="$(cat "$CURRENT_PROJECT_FILE")"
T="$(cat "$CURRENT_TASK_FILE")"
PROJ="$PROJ_ROOT/$P"
F="$PROJ/temp/$T.prompt.md"

mkdir -p "$(dirname "$F")"
[ -f "$F" ] || : > "$F"

# Try QuickEdit (termux-open-editor), else nano
if command -v termux-open-editor >/dev/null 2>&1; then
  termux-open-editor "$F" || nano "$F"
else
  nano "$F"
fi