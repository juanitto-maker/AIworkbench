#!/usr/bin/env bash
set -eo pipefail
AIWB="${AIWB:-$HOME/.aiwb/workspace}"
T="${1:-$( [ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "" )}"
[ -n "$T" ] || { echo "No active task."; exit 1; }
SRC="$AIWB/gemini-out/$T.output.md"; DST="$AIWB/drafts/$T.draft.md"
[ -f "$SRC" ] || { echo "Missing: $SRC (run ggo)"; exit 1; }
mkdir -p "$AIWB/drafts"; cp -f "$SRC" "$DST"
echo "✅ Draft → $DST"