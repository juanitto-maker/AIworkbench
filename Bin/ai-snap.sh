#!/data/data/com.termux/files/usr/bin/bash
# Snapshot prompt/draft/output into history/<task>/<timestamp>/
set -euo pipefail
T="${1:-}"; [ -z "$T" ] && { echo "Usage: ai-snap.sh <TASK_ID>"; exit 1; }
AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
ts="$(date -u +"%Y%m%d-%H%M%S")"
dst="$AIWB/history/$T/$ts"
mkdir -p "$dst"

copy_if() { [ -f "$1" ] && cp -f "$1" "$dst/"; }

copy_if "$HOME/temp/$T.prompt.md"
copy_if "$HOME/temp/$T.prompt.built.md"
copy_if "$HOME/drafts/$T.draft.md"
copy_if "$AIWB/gemini-out/$T.output.md"
copy_if "$AIWB/claude-out/$T.review.md"

echo "📸 Snapshot → $dst"