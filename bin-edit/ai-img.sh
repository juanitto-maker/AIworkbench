#!/usr/bin/env bash
# Import latest Android screenshot into the task and append a markdown image link to the prompt
set -euo pipefail
T="${1:-}"; [ -z "$T" ] && { echo "Usage: ai-img.sh <TASK_ID>"; exit 1; }

SRC_DIR="/storage/emulated/0/Pictures/Screenshots"
latest="$(ls -t "$SRC_DIR"/* 2>/dev/null | head -n1 || true)"
[ -z "$latest" ] && { echo "❌ No screenshots found in $SRC_DIR"; exit 1; }

dst="$HOME/temp/$T.images"; mkdir -p "$dst"
cp -f "$latest" "$dst/"
name="$(basename "$latest")"

PROMPT="$HOME/temp/$T.prompt.md"
[ -f "$PROMPT" ] || touch "$PROMPT"
echo -e "\n![screenshot]($T.images/$name)\n" >> "$PROMPT"

echo "🖼  Imported: $dst/$name"
echo "✍️  Added image link to: $PROMPT"