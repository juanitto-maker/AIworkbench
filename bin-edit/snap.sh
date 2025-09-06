#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
T="${1:-$( [ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "" )}"
[ -z "$T" ] && { echo "❌ No active task."; exit 1; }

TS="$(date +%Y%m%d-%H%M%S)"
DEST="$AIWB/history/$T/$TS"
mkdir -p "$DEST"

cp -f "$HOME/temp/$T.prompt.md" "$DEST/" 2>/dev/null || true
cp -f "$AIWB/gemini-out/$T.output.md" "$DEST/" 2>/dev/null || true
cp -f "$AIWB/claude-out/$T.review.md" "$DEST/" 2>/dev/null || true
cp -f "$AIWB/drafts/$T.draft.md" "$DEST/" 2>/dev/null || true
cp -f "$AIWB/drafts/$T.claude.md" "$DEST/" 2>/dev/null || true

echo "📸 Snapshot → $DEST"