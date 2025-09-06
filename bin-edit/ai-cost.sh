#!/data/data/com.termux/files/usr/bin/bash
# ai-cost.sh <model> <prompt_file> <out_tokens>
set -euo pipefail

MODEL="${1:-}"; PROMPT="${2:-}"; OUT_TOK="${3:-1000}"
AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
PRICING="$AIWB/pricing.json"

# crude but serviceable: ~4 chars per token
chars=0
[ -f "$PROMPT" ] && chars=$(wc -c < "$PROMPT" | tr -d ' ')
IN_TOK=$(( (chars + 3) / 4 ))
OUT_TOK="${OUT_TOK:-1000}"

# rates from pricing.json when present; conservative defaults otherwise
if [ -f "$PRICING" ] && command -v jq >/dev/null 2>&1; then
  IN_RATE=$(jq -r --arg m "$MODEL" '.[$m].input_per_1k // .default.input_per_1k // 0' "$PRICING")
  OUT_RATE=$(jq -r --arg m "$MODEL" '.[$m].output_per_1k // .default.output_per_1k // 0' "$PRICING")
else
  case "$MODEL" in
    claude-3*|claude-3-5*) IN_RATE=3.00; OUT_RATE=15.00 ;;
    gemini-1.5-flash*)     IN_RATE=0.35; OUT_RATE=0.53  ;;
    gemini-2.5-flash*)     IN_RATE=1.25; OUT_RATE=5.00  ;;
    *)                     IN_RATE=1.00; OUT_RATE=2.00  ;;
  esac
fi

cost_in=$(awk -v t="$IN_TOK" -v r="$IN_RATE" 'BEGIN{printf "%.4f", (t/1000.0)*r}')
cost_out=$(awk -v t="$OUT_TOK" -v r="$OUT_RATE" 'BEGIN{printf "%.4f", (t/1000.0)*r}')
total=$(awk -v a="$cost_in" -v b="$cost_out" 'BEGIN{printf "%.4f", a+b}')

printf "%s\tIN:%d(≈$%s)\tOUT:%d(≈$%s)\tTOTAL≈$%s\n" "$MODEL" "$IN_TOK" "$cost_in" "$OUT_TOK" "$cost_out" "$total"