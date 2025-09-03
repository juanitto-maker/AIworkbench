#!/data/data/com.termux/files/usr/bin/bash
# gpre.sh — Gemini pre-cost estimator (quote-style) + optional generation
# Works on Termux. No extra repo/bin hop; install to ~/.local/bin.
set -euo pipefail

# ---------- locations & env ----------
AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
AIWB_CODE_ROOT="${AIWB_CODE_ROOT:-$HOME/storage/shared/0code}"
[ -f "$HOME/.aiwb.env" ] && . "$HOME/.aiwb.env" || true

# model & pricing defaults
GEMINI_MODEL="${GEMINI_MODEL:-gemini-1.5-flash}"
PRICING_JSON="${PRICING_JSON:-$AIWB/pricing.json}"
FX="${FX_USD_EUR:-0.91}"                   # USD→EUR rate (optional)

# optional preferred runner; we’ll search these in order:
RUNNER_PREF="${GEMINI_RUNNER:-}"
RUNNERS=()
[ -n "$RUNNER_PREF" ] && RUNNERS+=("$RUNNER_PREF")
RUNNERS+=("ggo.sh" "g.sh" "$AIWB/bin-edit/ggo.sh" "$AIWB/bin-edit/g.sh")

# ---------- helpers ----------
die(){ printf '❌ %s\n' "$*" >&2; exit 1; }
has(){ command -v "$1" >/dev/null 2>&1; }
need(){ has "$1" || die "Missing dependency: $1"; }
need curl; need jq; need awk; need sed

trim_cr_ws(){ # prints sanitized value of the named var ($1)
  local v="${!1-}"; printf '%s' "$v" | tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}
jsons(){  # JSON-string escape (requires jq)
  jq -Rs . <<<"$1"
}
approx_in_tokens(){ awk -v s="$1" 'BEGIN{print int(length(s)/4)+1}' ; }
find_runner(){
  local r
  for r in "${RUNNERS[@]}"; do
    if command -v "$r" >/dev/null 2>&1; then echo "$r"; return; fi
    [ -x "$r" ] && { echo "$r"; return; }
  done
  echo ""
}
norm_tier(){
  case "$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')" in
    1|b|basic) echo basic;;
    2|m|med|medium) echo medium;;
    3|t|top) echo top;;
    *) echo "";;
  esac
}
price_or_default(){
  local model="$1" field="$2" def="$3"
  if [ -f "$PRICING_JSON" ]; then
    local k; k="$(jq -r --arg m "$model" --arg f "$field" '
      to_entries[] | select(.key==$m) | .value |
      if $f=="input_per_k" then .input_per_k
      elif $f=="output_per_k" then .output_per_k else empty end
    ' "$PRICING_JSON" 2>/dev/null || true)"
    if [ -n "$k" ] && [ "$k" != "null" ]; then
      # JSON is per 1K tokens → we store per 1M for easy math later
      awk -v kk="$k" 'BEGIN{printf "%.6f", kk*1000}'
      return
    fi
  fi
  printf '%s' "$def"
}

# ---------- CLI ----------
CONFIRM=0
OUT_JSON=0
SELECT_TIER=""
PROMPT_INLINE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --confirm) CONFIRM=1;;
    --json) OUT_JSON=1;;
    --tier) shift; SELECT_TIER="${1:-}";;
    --model) shift; GEMINI_MODEL="${1:-$GEMINI_MODEL}";;
    --help|-h)
      cat <<'HLP'
Usage: gpre.sh [--tier basic|medium|top|1|2|3] [--confirm] [--json] [--model NAME] [prompt...]
- Estimates token/cost for 3 tiers (BASIC, MEDIUM, TOP). Optionally proceeds to generation.
- Prompt source priority:
    1) inline args after options
    2) 0code/<project>/temp/<task>.prompt.md
    3) 0ai-workbench/temp/<task>.prompt.md
HLP
      exit 0;;
    *) PROMPT_INLINE+="${PROMPT_INLINE:+ }$1";;
  esac; shift
done

# ---------- prompt discovery ----------
PROJECT="$(cat "$AIWB/current.project" 2>/dev/null || true)"
TASK="$(cat "$AIWB/current.task" 2>/dev/null || true)"

PROMPT=""
PROMPT_PATH=""
if [ -n "$PROMPT_INLINE" ]; then
  PROMPT="$PROMPT_INLINE"
  PROMPT_PATH="(inline)"
else
  [ -z "$TASK" ] && die "No current.task set (use tnew.sh/tset.sh) or pass prompt inline."
  if [ -n "$PROJECT" ] && [ -f "$AIWB_CODE_ROOT/$PROJECT/temp/$TASK.prompt.md" ]; then
    PROMPT_PATH="$AIWB_CODE_ROOT/$PROJECT/temp/$TASK.prompt.md"
    PROMPT="$(cat "$PROMPT_PATH")"
  elif [ -f "$AIWB/temp/$TASK.prompt.md" ]; then
    PROMPT_PATH="$AIWB/temp/$TASK.prompt.md"
    PROMPT="$(cat "$PROMPT_PATH")"
  else
    die "Prompt file not found. Checked:
  - $AIWB_CODE_ROOT/$PROJECT/temp/$TASK.prompt.md
  - $AIWB/temp/$TASK.prompt.md"
  fi
fi
[ -n "$(printf '%s' "$PROMPT" | tr -d ' \n\r\t')" ] || die "Prompt is empty."

# ---------- pricing (USD per 1M tokens) ----------
G_IN_PER_M="$(price_or_default "$GEMINI_MODEL" input_per_k 0.075000)"   # flash default
G_OUT_PER_M="$(price_or_default "$GEMINI_MODEL" output_per_k 0.300000)"

# ---------- call Gemini ----------
GEMINI_API_KEY="$(trim_cr_ws GEMINI_API_KEY)"
[ -n "$GEMINI_API_KEY" ] || die "Missing GEMINI_API_KEY in ~/.aiwb.env"

SYS_MSG="You are a senior project estimator. Analyze the idea and produce a three-tier plan (BASIC, MEDIUM, TOP). For each tier: a feature list (name + est_out_tokens per feature) and a 'tier_out_tokens' total. Add 'analysis_tokens'. Respond as STRICT JSON ONLY with keys: analysis_tokens, tiers[], notes. No code fences."

REQUEST="$(cat <<JSON
{
  "systemInstruction": { "role":"user", "parts":[ { "text": $(jsons "$SYS_MSG") } ] },
  "contents": [ { "role":"user", "parts":[ { "text": $(jsons "$PROMPT") } ] } ],
  "generationConfig": {
    "maxOutputTokens": 1200,
    "responseMimeType": "application/json"
  }
}
JSON
)"

RAW="$(curl -sS \
  "https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}" \
  -H 'content-type: application/json' \
  -d "$REQUEST" )"

TEXT="$(printf '%s' "$RAW" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null || true)"
[ -n "$TEXT" ] || die "Empty response from Gemini estimator.
--- RAW ---
$(echo "$RAW" | sed -n '1,160p')
-----------"

# strip ```json fences if any
JSON_EST="$(printf '%s\n' "$TEXT" | sed '/^```[a-zA-Z]*\s*$/d; /^```\s*$/d')"
# validate JSON
echo "$JSON_EST" | jq -e . >/dev/null 2>&1 || die "Estimator output is not valid JSON. Raw body:\n$TEXT"

# ---------- compute & render ----------
ANALYSIS_TOK="$(jq -r '.analysis_tokens // 0' <<<"$JSON_EST")"
IN_TOK="$(approx_in_tokens "$PROMPT")"

# derive per-tier totals if missing
JSON_EST="$(jq '
  .tiers |= (map(
    if has("tier_out_tokens") then .
    else . + { tier_out_tokens:
      ( (.features // [])
        | map( (if type=="object" and has("est_out_tokens") then .est_out_tokens else 0 end) )
        | add // 0
      )
    } end
  ))
' <<<"$JSON_EST")"

if [ "$OUT_JSON" -eq 1 ]; then
  echo "$JSON_EST"
  exit 0
fi

printf ":: prompt: %s\n" "$PROMPT_PATH"
printf "📁 Project: %s\n" "${PROJECT:-<none>}"
printf "🧩 Task:    %s\n" "${TASK:-<none>}"
printf "🤖 Model:   %s\n" "$GEMINI_MODEL"
printf "📝 Prompt in-tokens (approx): %d\n" "$IN_TOK"
printf "🔍 Estimator analysis tokens: %d\n" "$ANALYSIS_TOK"
printf "💵 Pricing USD/1M: in=%s  out=%s\n" "$G_IN_PER_M" "$G_OUT_PER_M"
printf "💱 FX USD→EUR: %s\n\n" "$FX"

echo "tier  label    out_tok(tier)  out_tok(cum)   usd_in     usd_out    usd_total   eur_total"
echo "----  -------  -------------  ------------  --------   --------   ----------  ----------"

cum=0
idx=0
while IFS= read -r row; do
  idx=$((idx+1))
  label="$(jq -r '.label // .tier // "?"' <<<"$row")"
  t_tok="$(jq -r '.tier_out_tokens // 0' <<<"$row")"
  cum=$((cum + t_tok))

  usd_in=$(awk -v t=$((IN_TOK+ANALYSIS_TOK)) -v p="$G_IN_PER_M" 'BEGIN{printf "%.6f",(t/1000000.0)*p}')
  usd_out=$(awk -v t="$cum" -v p="$G_OUT_PER_M" 'BEGIN{printf "%.6f",(t/1000000.0)*p}')
  usd_tot=$(awk -v a="$usd_in" -v b="$usd_out" 'BEGIN{printf "%.6f",a+b}')
  eur_tot=$(awk -v u="$usd_tot" -v fx="$FX" 'BEGIN{printf "%.6f",u*fx}')

  printf "%-4s  %-7s  %13d  %12d  %8s   %8s    %10s   %10s\n" \
    "$idx" "$label" "$t_tok" "$cum" "$usd_in" "$usd_out" "$usd_tot" "$eur_tot"
done < <(jq -c '.tiers[]' <<<"$JSON_EST")

echo; echo "Features by tier:"
jq -r '
  .tiers[]
  | "— " + (.label // .tier) + " —\n" +
    ( (.features // [])
      | map( if type=="object"
              then "  • " + (.name // "feature") + "  (~" + ((.est_out_tokens // 0)|tostring) + " out tok)"
              else "  • " + (tostring)
            end
          )
      | join("\n")
    ) + "\n"
' <<<"$JSON_EST"

# ---------- optional generation ----------
CHOSEN=""
[ -n "$SELECT_TIER" ] && CHOSEN="$(norm_tier "$SELECT_TIER")"

if [ "$CONFIRM" -eq 1 ]; then
  echo
  if [ -z "$CHOSEN" ]; then
    printf "Proceed to generation? Pick tier [1=Basic, 2=Medium, 3=Top, n=No]: "
    read -r ans
    case "$ans" in 1|b|B) CHOSEN="basic";; 2|m|M) CHOSEN="medium";; 3|t|T) CHOSEN="top";; *) echo "Aborted."; exit 0;; esac
  else
    printf "Proceed with tier '%s'? [y/N]: " "$CHOSEN"; read -r yn; case "$yn" in y|Y) ;; *) echo "Aborted."; exit 0;; esac
  fi

  RUNNER="$(find_runner)"; [ -n "$RUNNER" ] || die "No Gemini runner found (looked for: ${RUNNERS[*]})"
  export AIWB_TIER="$CHOSEN"
  if "$RUNNER" --help >/dev/null 2>&1; then "$RUNNER" --tier "$CHOSEN"; else "$RUNNER"; fi
fi