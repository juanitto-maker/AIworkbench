#!/usr/bin/env bash
# quote.sh — Shared token pricing estimator (used by gpre.sh / cpre.sh / aiwb)
# Supports:
# - Claude and Gemini pricing lookup
# - Estimation based on prompt file token count (1 token ≈ 4 chars)
# - Optional --json output
# - Reads pricing from ~/.aiwb/pricing.json
# - Ensures model name and provider are valid
# - Aborts if relevant API key missing

set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }
err()  { printf "\033[1;31mEE\033[0m %s\n" "$*" >&2; }
warn() { printf "\033[1;33m!!\033[0m %s\n" "$*" >&2; }
msg()  { printf "\033[1;32m==>\033[0m %s\n" "$*"; }

AIWB_HOME="${HOME}/.aiwb"
PRICING_JSON_USER="${AIWB_HOME}/pricing.json"

DEFAULT_PRICING_JSON=$(cat <<'JSON'
{
  "fx": { "EUR_per_USD": 0.92 },
  "gemini": {
    "flash-1.5": { "in_per_1k": 0.15, "out_per_1k": 0.60 },
    "pro-1.5":   { "in_per_1k": 0.30, "out_per_1k": 1.20 }
  },
  "claude": {
    "sonnet-3.5": { "in_per_1k": 3.00, "out_per_1k": 15.00 },
    "haiku-3.5":  { "in_per_1k": 0.80, "out_per_1k": 4.00 }
  }
}
JSON
)

load_pricing() {
  if [[ -f "$PRICING_JSON_USER" ]]; then
    cat "$PRICING_JSON_USER"
  else
    echo "$DEFAULT_PRICING_JSON"
  fi
}

# ------- arg parsing --------
TASK_ID=""
MODEL=""
PROVIDER=""
OUT_TOKENS=0
OUTPUT_JSON="false"

for arg in "$@"; do
  case "$arg" in
    --model=*) MODEL="${arg#--model=}" ;;
    --provider=*) PROVIDER="${arg#--provider=}" ;;
    --out=*) OUT_TOKENS="${arg#--out=}" ;;
    --json) OUTPUT_JSON="true" ;;
    t*) TASK_ID="$arg" ;;
    *) warn "Unknown arg: $arg" ;;
  esac
done

[[ -z "$PROVIDER" ]] && err "Missing --provider= (gemini or claude)" && exit 1
[[ -z "$MODEL" ]] && err "Missing --model= (e.g., flash-1.5 or sonnet-3.5)" && exit 1
[[ -z "$TASK_ID" ]] && err "Missing <TASK_ID>" && exit 1

# ------- sanity API key --------
check_key() {
  case "$PROVIDER" in
    gemini)
      [[ -z "${GEMINI_API_KEY:-}" ]] && err "GEMINI_API_KEY not set" && exit 1 ;;
    claude)
      [[ -z "${ANTHROPIC_API_KEY:-}" ]] && err "ANTHROPIC_API_KEY not set" && exit 1 ;;
  esac
}
check_key

PROMPT_FILE="${AIWB_HOME}/workspace/tasks/${TASK_ID}.prompt.md"
[[ ! -f "$PROMPT_FILE" ]] && err "Prompt file not found: $PROMPT_FILE" && exit 1

chars=$(wc -c < "$PROMPT_FILE" | tr -d ' ')
words=$(wc -w < "$PROMPT_FILE" | tr -d ' ')
lines=$(wc -l < "$PROMPT_FILE" | tr -d ' ')
inp_tokens=$(( (chars + 3) / 4 ))
base_out=$(( inp_tokens * 9 / 10 ))  # approx 90%

[[ "$OUT_TOKENS" -lt 100 ]] && OUT_TOKENS=$base_out

PRICING=$(load_pricing)
if ! have jq; then err "jq required"; exit 1; fi

FX_EUR_PER_USD=$(echo "$PRICING" | jq -r '.fx.EUR_per_USD // 0.92')
in_per_1k=$(echo "$PRICING" | jq -r --arg p "$PROVIDER" --arg m "$MODEL" '.[$p][$m].in_per_1k // empty')
out_per_1k=$(echo "$PRICING" | jq -r --arg p "$PROVIDER" --arg m "$MODEL" '.[$p][$m].out_per_1k // empty')

[[ -z "$in_per_1k" || -z "$out_per_1k" ]] && {
  err "Missing pricing for $PROVIDER/$MODEL. Add to ~/.aiwb/pricing.json"
  exit 1
}

# ------- compute cost -------
price() { awk -v t="$1" -v p="$2" 'BEGIN{printf("%.6f", (t/1000.0)*p)}'; }
usd_in=$(price "$inp_tokens" "$in_per_1k")
usd_out=$(price "$OUT_TOKENS" "$out_per_1k")
usd_total=$(awk -v a="$usd_in" -v b="$usd_out" 'BEGIN{printf("%.6f", a+b)}')
eur_total=$(awk -v usd="$usd_total" -v fx="$FX_EUR_PER_USD" 'BEGIN{printf("%.6f", usd*fx)}')

if [[ "$OUTPUT_JSON" == "true" ]]; then
  jq -n --arg t "$TASK_ID" --arg m "$MODEL" --arg p "$PROVIDER" \
    --argjson tok_in "$inp_tokens" --argjson tok_out "$OUT_TOKENS" \
    --argjson usd "$usd_total" --argjson eur "$eur_total" \
    '{
      task: $t,
      model: $m,
      provider: $p,
      tokens: {in: $tok_in, out: $tok_out},
      total: {usd: $usd, eur: $eur}
    }'
  exit 0
fi

echo
echo "Quote for $TASK_ID — $PROVIDER/$MODEL"
echo "File: $PROMPT_FILE"
echo "Size: $chars chars, $words words, $lines lines"
echo
printf "Tokens:   in=%4d, out=%4d\n" "$inp_tokens" "$OUT_TOKENS"
printf "Pricing:  in=%.4f, out=%.4f\n" "$in_per_1k" "$out_per_1k"
printf "USD:      %.6f\n" "$usd_total"
printf "EUR:      %.6f\n" "$eur_total"
