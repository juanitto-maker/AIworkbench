#!/data/data/com.termux/files/usr/bin/bash
# Delete a single task's files from the current project (prompt/status/drafts/outputs)
set -euo pipefail
. ~/bin/paths.sh

[ -s "$CURRENT_PROJECT_FILE" ] || { echo "No active project. Use: pset <project>"; exit 1; }

P="$(cat "$CURRENT_PROJECT_FILE")"
PROJ="$PROJ_ROOT/$P"

T="${1:-$(cat "$CURRENT_TASK_FILE" 2>/dev/null || true)}"
[ -n "$T" ] || { echo "Usage: tdelete <taskId>  (or set with tset)"; exit 1; }

echo "This will delete task '$T' files in project '$P'."
read -rp "Type YES to confirm: " ok
[ "$ok" = "YES" ] || { echo "Aborted."; exit 1; }

rm -f "$PROJ/temp/$T.prompt.md" \
      "$PROJ/temp/$T.status.txt" \
      "$PROJ/drafts/$T."* \
      "$PROJ/outputs/$T."* 2>/dev/null || true

if [ -s "$CURRENT_TASK_FILE" ] && [ "$(cat "$CURRENT_TASK_FILE")" = "$T" ]; then
  rm -f "$CURRENT_TASK_FILE"
fi

echo "✅ Deleted task '$T' from project '$P'."