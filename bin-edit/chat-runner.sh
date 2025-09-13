#!/usr/bin/env bash
# chat-runner.sh — Agent runner for AIworkbench
#
# Reads a free-form message, asks Gemini/Claude for a JSON plan, shows it,
# and (on confirmation) runs your helpers:
#   estimate    → gpre.sh / cpre.sh
#   generate    → ggo.sh  / cgo.sh
#   tweak       → ggo.sh  / cgo.sh
#   debug       → cout.sh / gout.sh
# If API keys are missing it falls back to a safe heuristic plan.

set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }
err()  { printf "\033[1;31mEE\033[0m %s\n" "$*" >&2; }
warn() { printf "\033[1;33m!!\033[0m %s\n" "$*" >&2; }
msg()  { printf "\033[1;32m==>\033[0m %s\n" "$*"; }

gum_confirm() {
  if have gum; then gum confirm --prompt "$1" && return 0 || return 1
  else read -rp "$1 [y/N] " yn; [[ "$yn" =~ ^[Yy]$ ]]
  fi
}

json_get() { jq -r "$1" 2>/dev/null; }

# Remove ``` fences (and ```json) — awk-free for Termux/BusyBox/Toybox
strip_fences() {
  sed -e '1s/^\xEF\xBB\xBF//' \
      -e 's/^[[:space:]]*```json[[:space:]]*$//g' \
      -e 's/^[[:space:]]*```[[:space:]]*$//g'
}

# ----------------------------- args -------------------------------------------
PROVIDER=""
MODEL=""
MESSAGE=""
PROJECT_DIR=""
TASK_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider) PROVIDER="$2"; shift 2 ;;
    --model)    MODEL="$2"; shift 2 ;;
    --message)  MESSAGE="$2"; shift 2 ;;
    --project)  PROJECT_DIR="$2"; shift 2 ;;
    --taskfile) TASK_FILE="$2"; shift 2 ;;
    *) warn "Unknown arg: $1"; shift ;;
  esac
done

[[ -z "${MESSAGE:-}" ]]  && { err "Missing --message"; exit 2; }
[[ -z "${PROVIDER:-}" ]] && PROVIDER="gemini"

# ----------------------------- system prompt ----------------------------------
read -r -d '' SYSTEM_PROMPT <<'SYS' || true
You are AIworkbench Orchestrator. Reply with a single JSON object and nothing else.
Fields:
  intent: "estimate" | "generate" | "tweak" | "debug" | "chat"
  tier: "Basic" | "Medium" | "Best" | "" (empty when not applicable)
  reason: short one-sentence justification
  task_update: optional text to append to the current task prompt
  assistant: optional friendly reply when intent == "chat"
No markdown fences. No prose. JSON only.
SYS

# ----------------------------- bodies -----------------------------------------
make_body_gemini() {
  jq -n --arg sys "$SYSTEM_PROMPT" --arg u "$MESSAGE" '
  { contents: [ { role:"user", parts:[ {text:($sys + "\n\nUSER:\n" + $u)} ] } ] }'
}
make_body_claude() {
  jq -n --arg sys "$SYSTEM_PROMPT" --arg u "$MESSAGE" --arg m "${MODEL:-sonnet-3.5}" '
  { model:$m, max_tokens:512, system:$sys, messages:[ {role:"user", content:$u} ] }'
}

# ----------------------------- model call -------------------------------------
call_model() {
  case "$PROVIDER" in
    gemini)
      [[ -z "${GEMINI_API_KEY:-}" ]] && return 10
      local url="https://generativelanguage.googleapis.com/v1beta/models/${MODEL:-gemini-1.5-flash}:generateContent?key=${GEMINI_API_KEY}"
      local body; body="$(make_body_gemini)"
      curl -fsS -H 'Content-Type: application/json' -d "$body" "$url" \
        | jq -r '.candidates[0].content.parts[0].text // empty'
      ;;
    claude)
      [[ -z "${ANTHROPIC_API_KEY:-}" ]] && return 10
      local url="https://api.anthropic.com/v1/messages"
      local body; body="$(make_body_claude)"
      curl -fsS \
        -H "x-api-key: ${ANTHROPIC_API_KEY}" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "$body" \
        | jq -r '.content[0].text // empty'
      ;;
    *)
      return 10 ;;
  esac
}

# ----------------------------- heuristic fallback -----------------------------
heuristic_plan() {
  local lc; lc="$(printf '%s' "$MESSAGE" | tr '[:upper:]' '[:lower:]')"
  if   grep -Eq '\b(estimate|cost|price|quote)\b' <<<"$lc"; then
    echo '{"intent":"estimate","tier":"Medium","reason":"Asked to estimate."}'
  elif grep -Eq '\b(generate|build|create|scaffold|implement)\b' <<<"$lc"; then
    echo '{"intent":"generate","tier":"Medium","reason":"Asked to generate."}'
  elif grep -Eq '\b(tweak|modify|update|change|refactor|improve)\b' <<<"$lc"; then
    echo '{"intent":"tweak","tier":"Medium","reason":"Asked to tweak."}'
  elif grep -Eq '\b(debug|error|fix|bug|issue|trace)\b' <<<"$lc"; then
    echo '{"intent":"debug","tier":"Medium","reason":"Asked to debug."}'
  else
    printf '{"intent":"chat","assistant":%s,"reason":"General conversation."}' \
      "$(printf '%s' "$MESSAGE" | jq -Rs .)"
  fi
}

# ----------------------------- build plan -------------------------------------
RAW="$(call_model 2>/dev/null || true)"
[[ -z "${RAW:-}" ]] && RAW="$(heuristic_plan)"

CLEAN="$(printf '%s' "$RAW" | strip_fences | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

if ! echo "$CLEAN" | jq -e . >/dev/null 2>&1; then
  CLEAN="$(printf '{"intent":"chat","assistant":%s}' "$(printf '%s' "$RAW" | jq -Rs .)")"
fi
PLAN="$(echo "$CLEAN" | jq -c '.')"

# ----------------------------- show plan --------------------------------------
print_plan() {
  local plan="$1"
  local intent tier reason
  intent="$(printf "%s" "$plan" | json_get '.intent // "chat"')"
  tier="$(printf   "%s" "$plan" | json_get '.tier   // ""')"
  reason="$(printf "%s" "$plan" | json_get '.reason // ""')"
  echo "Agent plan:"
  echo "  intent : $intent"
  [[ -n "$tier" ]] && echo "  tier   : $tier"
  [[ -n "$reason" ]] && echo "  reason : $reason"
}
print_plan "$PLAN"

INTENT="$(echo "$PLAN" | json_get '.intent // "chat"')"
TIER="$(echo   "$PLAN" | json_get '.tier   // ""')"
ASSIST="$(echo "$PLAN" | json_get '.assistant // ""')"
TASK_UPDATE="$(echo "$PLAN" | json_get '.task_update // ""')"

# ----------------------------- update task ------------------------------------
if [[ -n "$TASK_UPDATE" && -n "${TASK_FILE:-}" ]]; then
  mkdir -p "$(dirname "$TASK_FILE")"
  { [[ -f "$TASK_FILE" ]] || echo -e "# $(basename "$TASK_FILE")\n"; } >> "$TASK_FILE"
  {
    echo
    echo "## Chat update ($(date -Iseconds))"
    echo "$TASK_UPDATE"
  } >> "$TASK_FILE"
  echo "Updated task file: $TASK_FILE"
fi

# ----------------------------- execute ----------------------------------------
case "$INTENT" in
  chat|"")
    if [[ -n "$ASSIST" ]]; then echo; echo "$ASSIST"; echo
    else echo; echo "(chat) $MESSAGE"; echo
    fi
    exit 0
    ;;

  estimate|generate|tweak|debug)
    if [[ "$PROVIDER" == "gemini" ]]; then PRE="gpre.sh"; GO="ggo.sh"
    else PRE="cpre.sh"; GO="cgo.sh"; fi

    if ! have "$PRE"; then warn "$PRE missing (install via binpush)"; exit 1; fi

    TASK_ID="t0000"
    if [[ -n "${TASK_FILE:-}" ]]; then
      base="$(basename "$TASK_FILE")"; TASK_ID="${base%%.prompt.md}"
    fi

    echo
    $PRE "$TASK_ID" ${TIER:+--tier="$TIER"} || true
    echo

    if [[ "$INTENT" == "estimate" ]]; then exit 0; fi

    gum_confirm "Proceed to ${INTENT^^} with tier ${TIER:-Medium}?" || { echo "Aborted."; exit 0; }

    case "$INTENT" in
      generate|tweak)
        if ! have "$GO"; then warn "$GO missing (install via binpush)"; exit 1; fi
        $GO "$TASK_ID" || true
        ;;
      debug)
        if have cout.sh; then cout.sh "$TASK_ID" || true
        elif have gout.sh; then gout.sh "$TASK_ID" || true
        else warn "No debug runner (cout.sh/gout.sh)."
        fi
        ;;
    esac
    ;;
  *)
    echo "Unknown intent: $INTENT"
    ;;
esac
