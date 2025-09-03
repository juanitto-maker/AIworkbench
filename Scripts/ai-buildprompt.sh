#!/data/data/com.termux/files/usr/bin/bash
# Compose temp/<T>.prompt.built.md from optional temp/<T>.instruct.md + base prompt
set -euo pipefail
T="${1:-}"; [ -z "$T" ] && { echo "Usage: ai-buildprompt.sh <TASK_ID>"; exit 1; }

AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
BASE="$HOME/temp/$T.prompt.md"
[ -f "$BASE" ] || BASE="$AIWB/gemini-prompts/$T.prompt.md"
[ -f "$BASE" ] || { echo "❌ No prompt for $T"; exit 1; }

INST="$HOME/temp/$T.instruct.md"
OUT="$HOME/temp/$T.prompt.built.md"

{
  if [ -f "$INST" ]; then
    echo "<!-- .instruct - appended by ai-buildprompt -->"
    cat "$INST"
    echo; echo "---"; echo
  fi
  cat "$BASE"
} > "$OUT"

echo "🧩 Built prompt → $OUT"