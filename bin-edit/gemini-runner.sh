#!/data/data/com.termux/files/usr/bin/bash
# Calls Google Generative Language API (v1beta) text-only
set -euo pipefail
: "${GEMINI_API_KEY:?Set GEMINI_API_KEY in ~/.bashrc}"

AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
T="${1:-$( [ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "" )}"
[ -n "$T" ] || { echo "Usage: gemini-runner.sh <TASK_ID>"; exit 1; }

MODEL="${GEMINI_MODEL:-gemini-1.5-flash}"
MAXTOK="${MAX_OUT_TOKENS_DEFAULT:-16000}"

PROMPT="$AIWB/gemini-prompts/$T.prompt.md"
OUTDIR="$AIWB/gemini-out"; LOGDIR="$AIWB/runner-logs"
OUT="$OUTDIR/$T.output.md"; LOG="$LOGDIR/$T.log"

mkdir -p "$OUTDIR" "$LOGDIR"
[ -f "$PROMPT" ] || { echo "Missing prompt: $PROMPT"; exit 1; }

REQ=$(jq -n --arg txt "$(cat "$PROMPT")" --argjson max "$MAXTOK" \
  '{contents:[{role:"user", parts:[{text:$txt}]}],
    generationConfig:{temperature:0.2, maxOutputTokens:$max}}')

URL="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}"

echo "🟢 Gemini → $MODEL (maxOutputTokens=$MAXTOK)"
RESP=$(curl -sS -H "Content-Type: application/json" -X POST "$URL" -d "$REQ" | tee "$LOG")
TXT=$(echo "$RESP" | jq -r '.candidates[0].content.parts[]?.text' 2>/dev/null | sed '/^null$/d')

if [ -z "$TXT" ]; then
  echo "❌ No text output. See log: $LOG"
  exit 1
fi

echo "$TXT" > "$OUT"
echo "✅ Saved → $OUT"