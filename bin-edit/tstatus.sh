#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
T="${1:-$( [ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "" )}"
[ -n "$T" ] || { echo "No active task."; exit 1; }

echo "📌 Task: $T"
for f in "$HOME/temp/$T.prompt.md" \
         "$AIWB/gemini-prompts/$T.prompt.md" \
         "$AIWB/gemini-out/$T.output.md" \
         "$AIWB/claude-prompts/$T.prompt.md" \
         "$AIWB/claude-out/$T.review.md" \
         "$AIWB/drafts/$T.draft.md" ; do
  [ -f "$f" ] && echo " • $(realpath "$f")"
done