#!/data/data/com.termux/files/usr/bin/bash
# Tiered quote + cost estimator for a project prompt
# Works with Claude (Anthropic) or Gemini (Google) via curl.
# Requires: jq, curl, and your ~/.aiwb.env with pricing/keys (you already have this).

set -euo pipefail

# --- config / env ------------------------------------------------------------
AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
ENV="$HOME/.aiwb.env"
[ -f "$ENV" ] && . "$ENV" || true

# Pricing (USD per 1M tokens). You already have these variables in ~/.aiwb.env.
G_IN="${G_USD_IN_PER_M:-0.075}"        # Gemini input $/1M tok
G_OUT="${G_USD_OUT_PER_M:-0.30}"       # Gemini output $/1M tok
C_IN="${C_USD_IN_PER_M:-3.00}"         # Claude input $/1M tok
C_OUT="${C_USD_OUT_PER_M:-15.00}"      # Claude output $/1M tok
FX="${FX_USD_EUR:-0.91}"               # Optional USD -> EUR

# Models/keys (you already keep these in ~/.aiwb.env)
PROVIDER="${PROVIDER:-auto}"           # auto | claude | gemini
CLAUDE_MODEL="${CLAUDE_MODEL:-claude-3-5-sonnet-latest}"
GEMINI_MODEL="${GEMINI_MODEL:-gemini-1.5-flash}"

# --- helpers -----------------------------------------------------------------
die(){ echo "Error: $*" >&2; exit 1; }

need(){
  command -v "$1" >/dev/null 2>&1 || die "Missing '$1' (try: pkg install $1)"
}

need jq
need curl

pick_provider(){
  case "$PROVIDER" in
    claude) echo "claude";;
    gemini) echo "gemini";;
    auto)
      if [ -n "${ANTHROPIC_API_KEY:-}" ]; then echo "claude"
      elif [ -n "${GEMINI_API_KEY:-}" ]; then echo "gemini"
      else die "No API key found. Set ANTHROPIC_API_KEY or GEMINI_API_KEY in ~/.aiwb.env"
      fi
      ;;
    *) die "PROVIDER must be auto|claude|gemini";;
  esac
}

# Approx tokenizer: chars → ~tokens (fast rough cut, ~4 chars/token)
approx_in_tokens(){
  awk -v s="$1" 'BEGIN{print int(length(s)/4)+1}'
}

# Read prompt: arg, file, or current task
get_prompt(){
  if [ $# -gt 0 ]; then
    printf '%s' "$*"
    return
  fi
  # Use current task prompt if no args
  if [ -f "$AIWB/current.task" ]; then
    T="$(cat "$AIWB/current.task")"
    F="$AIWB/temp/$T.prompt.md"
    [ -f "$F" ] || die "No prompt found at $F (run tnew.sh / tedit.sh)"
    cat "$F"
    return
  fi
  die "Usage: quote.sh \"your idea\"  (or set a current task and its prompt)."
}

# --- API callers -------------------------------------------------------------
call_claude_json(){
  # $1 = prompt text
  local prompt="$1"

  local sys="You are a senior project estimator. Analyze the user's idea and propose a \
three-tier plan (basic, medium, top). For each tier provide a list of features with \
conservative *output* token estimates for the code/content you would produce. Sum each \
tier, and include an estimate of analysis tokens already used. Respond as STRICT JSON ONLY:

{
  \"analysis_tokens\": <int>,
  \"tiers\": [
    {\"id\":\"basic\",\"label\":\"Basic\",\"features\":[
       {\"name\":\"...\",\"est_out_tokens\":<int>}, ...
    ], \"tier_out_tokens\": <int>},
    {\"id\":\"medium\",\"label\":\"Medium\",...},
    {\"id\":\"top\",\"label\":\"Top\",...}
  ],
  \"notes\": \"short cautionary notes, if any\"
}"

  curl -sS https://api.anthropic.com/v1/messages \
    -H "x-api-key: ${ANTHROPIC_API_KEY:?missing ANTHROPIC_API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d @- <<JSON | jq -r '.content[0].text'
{
  "model": "${CLAUDE_MODEL}",
  "max_tokens": 1200,
  "system": ${sys@Q},
  "messages": [
    {"role":"user","content": ${prompt@Q}}
  ]
}
JSON
}

call_gemini_json(){
  # $1 = prompt text
  local prompt="$1"

  local sys="You are a senior project estimator. Analyze the user's idea and propose a \
three-tier plan (basic, medium, top). For each tier provide a list of features with \
conservative *output* token estimates for the code/content you would produce. Sum each \
tier, and include an estimate of analysis tokens already used. Respond as STRICT JSON ONLY:

{
  \"analysis_tokens\": <int>,
  \"tiers\": [
    {\"id\":\"basic\",\"label\":\"Basic\",\"features\":[
       {\"name\":\"...\",\"est_out_tokens\":<int>}, ...
    ], \"tier_out_tokens\": <int>},
    {\"id\":\"medium\",\"label\":\"Medium\",...},
    {\"id\":\"top\",\"label\":\"Top\",...}
  ],
  \"notes\": \"short cautionary notes, if any\"
}"

  curl -sS \
    "https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY:?missing GEMINI_API_KEY}" \
    -H 'content-type: application/json' \
    -d @- <<JSON | jq -r '.candidates[0].content.parts[0].text'
{
  "contents": [{"role":"user","parts":[{"text": ${prompt@Q}}]}],
  "system_instruction": {"parts":[{"text": ${sys@Q}}]}
}
JSON
}

# --- main --------------------------------------------------------------------
PROV="$(pick_provider)"
PROMPT="$(get_prompt "$@")"
IN_TOK="$(approx_in_tokens "$PROMPT")"

case "$PROV" in
  claude)
    PRICE_IN="$C_IN"; PRICE_OUT="$C_OUT"
    RAW_JSON="$(call_claude_json "$PROMPT")"
    ;;
  gemini)
    PRICE_IN="$G_IN"; PRICE_OUT="$G_OUT"
    RAW_JSON="$(call_gemini_json "$PROMPT")"
    ;;
esac

# Ensure we really have JSON
echo "$RAW_JSON" | jq -e . >/dev/null 2>&1 || {
  printf '\nEstimator output was not valid JSON:\n%s\n' "$RAW_JSON" >&2
  exit 1
}

ANALYSIS_TOK="$(echo "$RAW_JSON" | jq -r '.analysis_tokens // 0')"

# Build a nice table
echo
printf "📁 Project: %s\n" "${PROJECT:-${PWD##*/}}"
if [ -f "$AIWB/current.task" ]; then
  printf "🧩 Task: %s\n" "$(cat "$AIWB/current.task")"
fi
printf "🤖 Provider: %s | Model: %s\n" "$PROV" "$( [ "$PROV" = claude ] && echo "$CLAUDE_MODEL" || echo "$GEMINI_MODEL" )"
printf "📝 Prompt chars: %d  → in≈%d tokens\n" "$(printf '%s' "$PROMPT" | wc -c)" "$IN_TOK"
printf "🔎 Analysis tokens (est): %d\n" "$ANALYSIS_TOK"
printf "💲 Pricing per 1M tok (USD): in=%.6f  out=%.6f\n" "$PRICE_IN" "$PRICE_OUT"
printf "💱 FX USD→EUR: %s\n\n" "$FX"

# Print tiers
echo "Tier  Label   OutTok(tier)  OutTok(cum)    USD(in)   USD(out)   USD(total)    EUR(total)"
echo "----  ------  ------------  ------------  --------  ---------   ----------    ----------"

cum=0
idx=0
echo "$RAW_JSON" | jq -c '.tiers[]' | while read -r T; do
  idx=$((idx+1))
  label="$(echo "$T" | jq -r '.label')"
  tier_tok="$(echo "$T" | jq -r '.tier_out_tokens')"
  cum=$((cum + tier_tok))

  # Cost
  usd_in=$(awk -v t=$((IN_TOK+ANALYSIS_TOK)) -v p="$PRICE_IN" 'BEGIN{printf "%.6f",(t/1000000.0)*p}')
  usd_out=$(awk -v t="$cum" -v p="$PRICE_OUT" 'BEGIN{printf "%.6f",(t/1000000.0)*p}')
  usd_tot=$(awk -v a="$usd_in" -v b="$usd_out" 'BEGIN{printf "%.6f",a+b}')
  eur_tot=$(awk -v u="$usd_tot" -v fx="$FX" 'BEGIN{printf "%.6f",u*fx}')

  printf "%-4s  %-6s  %12d  %12d  %8s  %9s   %10s    %10s\n" \
    "$idx" "$label" "$tier_tok" "$cum" "$usd_in" "$usd_out" "$usd_tot" "$eur_tot"
done

# Show features per tier (compact)
echo
echo "Features by tier (quick view):"
echo "$RAW_JSON" | jq -r '
  .tiers[]
  | "— " + .label + " —\n" + ( .features | map("  • " + .name + "  (~" + (.est_out_tokens|tostring) + " out tok)") | join("\n") )
  + "\n"
'

# Optional: auto-generate after selection (1/2/3)
if [ "${CHOOSE:-}" != "" ]; then
  CH="$CHOOSE"
else
  read -rp "Enter tier to build now (1/2/3, or Enter to quit): " CH || true
fi

case "${CH:-}" in
  1|2|3)
    # Gather features up to selected tier into a single bullet list prompt
    SEL_JSON="$(echo "$RAW_JSON" | jq ".tiers[:$CH]")"
    FEATURE_LIST="$(echo "$SEL_JSON" | jq -r '[ .[].features[] .name ] | unique | map("- " + .) | join("\n")')"

    GEN_PROMPT=$(
      cat <<EOF
Generate the project described below. Implement ONLY the following features:

$FEATURE_LIST

Project idea:
$PROMPT
EOF
    )

    echo
    echo "Starting generation for tier $CH..."
    if [ "$PROV" = claude ]; then
      curl -sS https://api.anthropic.com/v1/messages \
        -H "x-api-key: ${ANTHROPIC_API_KEY:?}" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d @- <<JSON | jq -r '.content[0].text'
{
  "model": "${CLAUDE_MODEL}",
  "max_tokens": 4000,
  "messages":[{"role":"user","content": ${GEN_PROMPT@Q}}]
}
JSON
    else
      curl -sS \
        "https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY:?}" \
        -H 'content-type: application/json' \
        -d @- <<JSON | jq -r '.candidates[0].content.parts[0].text'
{
  "contents":[{"role":"user","parts":[{"text": ${GEN_PROMPT@Q}}]}]
}
JSON
    fi
    ;;
  *) echo "Done. (No generation selected.)";;
esac