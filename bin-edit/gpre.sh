#!/usr/bin/env bash
# gpre.sh — Pre-estimate for Gemini (AIworkbench)
# - Universal: Linux/macOS/Termux (shebang gets fixed by binpush on Termux)
# - Chat-first flow support: prints human table by default, --json for machine output
# - Tier menu FIRST (Abort/Basic/Medium/Best) when interactive; or pass --tier=
# - Reads workspace/config from ~/.aiwb/config.json with sane fallbacks
# - Finds prompt at ~/.aiwb/workspace/tasks/<TASK_ID>.prompt.md
# - Heuristic token estimate, transparent multipliers per tier
# - Configurable pricing (override in ~/.aiwb/pricing.json or via env)
#
# Usage:
#   gpre.sh <TASK_ID> [--json] [--tier=Basic|Medium|Best|Abort] [--model=<gemini-model>] [--show-config]
#
# JSON output shape:
# {
#   "task": "t0001",
#   "model": "flash-1.5",
#   "tokens": { "in": 850, "out_est": 1400 },
#   "tiers": [
#     {"name":"Basic","out_tokens":900,"usd_total":0.12,"eur_total":0.11},
#     {"name":"Medium","out_tokens":1400,"usd_total":0.18,"eur_total":0.17},
#     {"name":"Best","out_tokens":2200,"usd_total":0.28,"eur_total":0.26}
#   ],
#   "chosen_tier": "Medium"
# }

set -euo pipefail

# ---------- utils ----------
have() { command -v "$1" >/dev/null 2>&1; }
err()  { printf "\033[1;31mEE\033[0m %s\n" "$*" >&2; }
warn() { printf "\033[1;33m!!\033[0m %s\n" "$*" >&2; }
msg()  { printf "\033[1;32m==>\033[0m %s\n" "$*"; }

AIWB_HOME="${HOME}/.aiwb"
CONFIG_JSON="${AIWB_HOME}/config.json"
PRICING_JSON_USER="${AIWB_HOME}/pricing.json"

# ---------- defaults ----------
WS_ROOT_DEFAULT="${AIWB_HOME}/workspace"
TASKS_DIR_DEFAULT="${WS_ROOT_DEFAULT}/tasks"

PROVIDER_DEFAULT="gemini"
MODEL_DEFAULT_GEMINI="flash-1.5"

# Pricing defaults (USD per 1K tokens) — override in ~/.aiwb/pricing.json
# Values are placeholders; adjust as needed in your user pricing.json.
read -r -d '' PRICING_DEFAULT <<'JSON' || true
{
  "fx": { "EUR_per_USD": 0.92 },
  "gemini": {
    "flash-1.5": { "in_per_1k": 0.15, "out_per_1k": 0.60 },
    "pro-1.5":   { "in_per_1k": 0.30, "out_per_1k": 1.20 }
  }
}
JSON

# Tier multipliers (on out tokens)
declare -A TIER_MULT=(
  ["Basic"]="0.65"
  ["Medium"]="1.00"
  ["Best"]="1.60"
)

TIERS=("Basic" "Medium" "Best")

# ---------- parse args ----------
TASK_ID="${1:-}"
[[ -z "${TASK_ID}" ]] && { err "Usage: gpre.sh <TASK_ID> [--json] [--tier=...] [--model=...]"; exit 2; }

OUTPUT_JSON="false"
CHOSEN_TIER=""
MODEL_NAME=""
SHOW_CONFIG="false"

for a in "${@:2}"; do
  case "$a" in
    --json) OUTPUT_JSON="true" ;;
    --tier=*) CHOSEN_TIER="${a#--tier=}" ;;
    --model=*) MODEL_NAME="${a#--model=}" ;;
    --show-config) SHOW_CONFIG="true" ;;
    *) warn "Unknown arg: $a" ;;
  esac
done

# ---------- config ----------
jq_get() { jq -r "$1" "$CONFIG_JSON"; }

TASKS_DIR="$TASKS_DIR_DEFAULT"
MODEL_PROVIDER="$PROVIDER_DEFAULT"
if [[ -f "$CONFIG_JSON" ]] && have jq; then
  TASKS_DIR="$(jq_get '.workspace.tasks' 2>/dev/null || echo "$TASKS_DIR_DEFAULT")"
  MODEL_PROVIDER="$(jq_get '.models.default_provider' 2>/dev/null || echo "$PROVIDER_DEFAULT")"
  [[ -z "$MODEL_NAME" ]] && MODEL_NAME="$(jq_get '.models.gemini_default' 2>/dev/null || echo "$MODEL_DEFAULT_GEMINI")"
fi
[[ -z "$MODEL_NAME" ]] && MODEL_NAME="$MODEL_DEFAULT_GEMINI"

PROMPT_FILE="${TASKS_DIR}/${TASK_ID}.prompt.md"
if [[ ! -f "$PROMPT_FILE" ]]; then
  err "Prompt not found: $PROMPT_FILE"
  err "Create it first (e.g., ~/.aiwb/workspace/tasks/${TASK_ID}.prompt.md)"
  exit 3
fi

# ---------- pricing ----------
load_pricing() {
  local src_json="$PRICING_JSON_USER"
  if [[ -f "$src_json" ]]; then
    cat "$src_json"
  else
    printf "%s" "$PRICING_DEFAULT"
  fi
}

if ! have jq; then
  err "jq is required."
  exit 4
fi

PRICING="$(load_pricing)"
if [[ "$SHOW_CONFIG" == "true" ]]; then
  echo "$PRICING" | jq .
  exit 0
fi

# Fetch per-1k token prices
get_price() {
  local provider="$1" model="$2" kind="$3" # kind=in_per_1k|out_per_1k
  echo "$PRICING" | jq -r --arg p "$provider" --arg m "$model" --arg k "$kind" '.[$p][$m][$k] // empty'
}

FX_EUR_PER_USD="$(echo "$PRICING" | jq -r '.fx.EUR_per_USD // 0.92')"

IN_PER_1K="$(get_price "gemini" "$MODEL_NAME" "in_per_1k")"
OUT_PER_1K="$(get_price "gemini" "$MODEL_NAME" "out_per_1k")"
if [[ -z "$IN_PER_1K" || -z "$OUT_PER_1K" || "$IN_PER_1K" == "null" || "$OUT_PER_1K" == "null" ]]; then
  err "Pricing missing for gemini/$MODEL_NAME. Add it to ~/.aiwb/pricing.json"
  exit 5
fi

# ---------- estimate tokens ----------
# Heuristics:
# - input tokens ≈ ceil(chars/4)
# - baseline out tokens ≈ ceil(input_tokens * 0.9), then tier multipliers
chars=$(wc -c < "$PROMPT_FILE" | tr -d ' ')
words=$(wc -w < "$PROMPT_FILE" | tr -d ' ')
lines=$(wc -l < "$PROMPT_FILE" | tr -d ' ')

inp_tokens=$(( (chars + 3) / 4 ))
base_out=$(awk -v it="$inp_tokens" 'BEGIN{printf("%d", (it*0.9)+0.5)}')

# ---------- interactive tier (if not provided and stdout is a tty) ----------
choose_tier_interactive() {
  if [[ -t 1 ]]; then
    # Try gum for nicer UI
    if have gum; then
      local pick
      pick="$(printf "Abort\nBasic\nMedium\nBest" | gum choose --header "Choose tier for ${TASK_ID} (model: ${MODEL_NAME})")" || pick=""
      echo "$pick"
      return
    fi
    echo "Choose tier: [a]bort [b]asic [m]edium [B]est"
    read -r ans
    case "$ans" in a|A) echo "Abort" ;; b|B) echo "Basic" ;; m|M) echo "Medium" ;; *) echo "Best" ;; esac
  else
    echo "Medium"
  fi
}

if [[ -z "$CHOSEN_TIER" ]]; then
  CHOSEN_TIER="$(choose_tier_interactive)"
fi
case "$CHOSEN_TIER" in
  Abort|"") ;;
  Basic|Medium|Best) ;;
  *) warn "Unknown tier '$CHOSEN_TIER' → defaulting to Medium"; CHOSEN_TIER="Medium" ;;
esac

# ---------- compute costs ----------
round_up_divide() { # ceil(a/b)
  awk -v a="$1" -v b="$2" 'BEGIN{printf("%d", (a+b-1)/b)}'
}
price_for() { # tokens, per1k
  local toks="$1" per="$2"
  awk -v t="$toks" -v p="$per" 'BEGIN{printf("%.6f", (t/1000.0)*p)}'
}
usd_to_eur() {
  awk -v u="$1" -v r="$FX_EUR_PER_USD" 'BEGIN{printf("%.6f", u*r)}'
}

json_escape() { python - <<'PY' "$1"; exit 0
import json,sys; print(json.dumps(sys.argv[1]))
PY
}

# Build tier rows
declare -A tier_out
declare -A tier_usd
declare -A tier_eur
for t in "${TIERS[@]}"; do
  mult="${TIER_MULT[$t]}"
  out=$(awk -v b="$base_out" -v m="$mult" 'BEGIN{printf("%d", b*m+0.5)}')
  # totals
  usd_in=$(price_for "$inp_tokens" "$IN_PER_1K")
  usd_out=$(price_for "$out"        "$OUT_PER_1K")
  usd_total=$(awk -v a="$usd_in" -v b="$usd_out" 'BEGIN{printf("%.6f", a+b)}')
  eur_total=$(usd_to_eur "$usd_total")
  tier_out["$t"]="$out"
  tier_usd["$t"]="$usd_total"
  tier_eur["$t"]="$eur_total"
done

# ---------- output ----------
if [[ "$OUTPUT_JSON" == "true" ]]; then
  # JSON
  printf '{'
  printf '"task":%s,' "$(json_escape "$TASK_ID")"
  printf '"model":%s,' "$(json_escape "$MODEL_NAME")"
  printf '"tokens":{"in":%d,"out_est":%d},' "$inp_tokens" "$base_out"
  printf '"tiers":['
  first=1
  for t in "${TIERS[@]}"; do
    [[ $first -eq 0 ]] && printf ','
    printf '{"name":%s,"out_tokens":%d,"usd_total":%.6f,"eur_total":%.6f}' \
      "$(json_escape "$t")" "${tier_out[$t]}" "${tier_usd[$t]}" "${tier_eur[$t]}"
    first=0
  done
  printf ']'
  if [[ "$CHOSEN_TIER" != "Abort" && -n "$CHOSEN_TIER" ]]; then
    printf ',"chosen_tier":%s' "$(json_escape "$CHOSEN_TIER")"
  fi
  printf '}\n'
  exit 0
fi

# Human table
echo
echo "AIWB • Gemini pre-estimate"
echo " Task    : ${TASK_ID}"
echo " Model   : ${MODEL_NAME}"
echo " Prompt  : ${PROMPT_FILE}"
echo " Size    : ${chars} chars, ${words} words, ${lines} lines"
echo " Tokens  : in≈${inp_tokens}, out_base≈${base_out}"
echo
printf " %-8s | %-10s | %-12s | %-12s\n" "Tier" "Out tokens" "USD total" "EUR total"
printf "-----------+------------+--------------+--------------\n"
for t in "${TIERS[@]}"; do
  printf " %-8s | %-10d | %-12.6f | %-12.6f\n" "$t" "${tier_out[$t]}" "${tier_usd[$t]}" "${tier_eur[$t]}"
done
echo

if [[ "$CHOSEN_TIER" == "Abort" || -z "$CHOSEN_TIER" ]]; then
  echo "Chosen tier: Abort"
  exit 0
fi

echo "Chosen tier: ${CHOSEN_TIER}"
echo "(Tip: pass --json for machine-readable output, or --tier= to skip the menu.)"
```0
