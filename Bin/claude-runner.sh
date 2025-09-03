#!/data/data/com.termux/files/usr/bin/bash
# Claude API runner — calls Anthropic chat model
set -euo pipefail
: "${ANTHROPIC_API_KEY:?Set ANTHROPIC_API_KEY in ~/.bashrc}"

AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
T="${1:-$( [ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "" )}"
[ -n "$T" ] || { echo "Usage: claude-runner.sh <TASK_ID>"; exit 1; }

MODEL="${CLAUDE_MODEL:-claude-3-5-sonnet-latest}"
MAXTOK="${MAX_OUT_TOKENS_DEFAULT:-16000}"

PROMPT="$AIWB/claude-prompts/$T.prompt.md"
OUTDIR="$AIWB/claude-out"; LOGDIR="$AIWB/runner-logs"
OUT="$OUTDIR/$T.review.md"; LOG="$LOGDIR/$T.log"

mkdir -p "$OUTDIR" "$LOGDIR"
[ -f "$PROMPT" ] || { echo "Missing prompt: $PROMPT"; exit 1; }

REQ=$(jq -n --arg content "$(cat "$PROMPT")" --arg model "$MODEL" --argjson max "$MAXTOK" \
  '{model:$model, max_tokens:$max, temperature:0.2, messages:[{role:"user", content:$content}] }')

echo "🟣 Claude → $MODEL (max_tokens=$MAXTOK)"
RESP=$(curl -sS https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "$REQ" | tee "$LOG")

TXT=$(echo "$RESP" | jq -r '.content[]?.text' 2>/dev/null || true)
[ -n "$TXT" ] || { echo "❌ No text output. See log: $LOG"; exit 1; }

echo "$TXT" > "$OUT"
echo "✅ Saved → $OUT"