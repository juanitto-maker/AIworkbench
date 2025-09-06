#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
T="${1:-$( [ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "" )}"
[ -z "$T" ] && { echo "❌ No active task."; exit 1; }

SRC="$AIWB/claude-out/$T.review.md"
DST="$AIWB/drafts/$T.claude.md"

[ -f "$SRC" ] || { echo "❌ Claude output not found. Run cgo first."; exit 1; }

mkdir -p "$AIWB/drafts"
cp -f "$SRC" "$DST"

echo "✅ Claude draft saved → $DST"