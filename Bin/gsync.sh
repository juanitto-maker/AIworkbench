#!/data/data/com.termux/files/usr/bin/bash
# Sync the current task's prompt into gemini-prompts folder
set -euo pipefail

AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"

T="${1:-}"
[ -z "$T" ] && [ -f "$AIWB/current.task" ] && T="$(cat "$AIWB/current.task")"
[ -z "$T" ] && { echo "❌ No task ID provided or active."; exit 1; }

SRC="$HOME/temp/$T.prompt.md"
DST="$AIWB/gemini-prompts/$T.prompt.md"

[ -f "$SRC" ] || { echo "❌ Prompt not found: $SRC. Run tedit first."; exit 1; }

mkdir -p "$AIWB/gemini-prompts"
cp -f "$SRC" "$DST"

echo "✅ Prompt synced → $DST"