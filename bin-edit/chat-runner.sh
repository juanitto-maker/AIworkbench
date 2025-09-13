#!/usr/bin/env bash
# chat-runner.sh — Agent runner for AIworkbench
# - Works even with no explicit task: uses <workspace>/tasks/inbox.prompt.md
# - Shows a JSON plan (Gemini/Claude or heuristic), asks to confirm, then runs helpers:
#     estimate  -> gpre.sh / cpre.sh
#     generate  -> ggo.sh  / cgo.sh
#     tweak     -> ggo.sh  / cgo.sh
#     debug     -> gout.sh / cout.sh
# - Cross-platform: Termux/Linux/macOS. Needs: bash, jq, curl. Optional: gum.

set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }
err()  { printf "\033[1;31mEE\033[0m %s\n" "$*" >&2; }
warn() { printf "\033[1;33m!!\033[0m %s\n" "$*" >&2; }
msg()  { printf "\033[1;32m==>\033[0m %s\n" "$*"; }

json_get() { jq -r "$1" 2>/dev/null; }
gum_confirm() {
  if have gum; then gum confirm --prompt "$1" && return 0 || return 1
  else read -rp "$1 [y/N] " yn; [[ "$yn" =~ ^[Yy]$ ]]
  fi
}
# Remove code fences (and BOM) without awk (works on BusyBox/Toybox)
strip_fences() {
  sed -e '1s/^\xEF\xBB\xBF//' \
      -e 's/^[[:space:]]*```json[[:space:]]*$//g' \
      -e 's/^[[:space:]]*```[[:space:]]*$//g'
}

# ---------- args ----------
PROVIDER="" ; MODEL="" ; MESSAGE=""
PROJECT_DIR="" ; TASK_FILE="" ; WORKSPACE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider) PROVIDER="$2"; shift 2 ;;
    --model)    MODEL="$2"; shift 2 ;;
    --message)  MESSAGE="$2"; shift 2 ;;
    --project)  PROJECT_DIR="$2"; shift 2 ;;
    --taskfile) TASK_FILE="$2"; shift 2 ;;
    --workspace)WORKSPACE="$2"; shift 2 ;;
    *) shift ;;
  esac
done
[[ -z "${MESSAGE:-}" ]] && { err "Missing --message"; exit 2; }
[[ -z "${PROVIDER:-}" ]] && PROVIDER="gemini"

# ---------- workspace (Android-visible if possible) ----------
if [[ -z "${WORKSPACE:-}" ]]; then
  if [[ -d "$HOME/storage/shared" ]]; then
    WORKSPACE="$HOME/storage/shared/aiwb"
  else
    WORKSPACE="$HOME/.aiwb/workspace"
  fi
fi
mkdir -p "$WORKSPACE/tasks" "$WORKSPACE/logs" "$WORKSPACE/snapshots" "$WORKSPACE/projects"

# Default task if none passed
if [[ -z "${TASK_FILE:-}" ]]; then
  TASK_FILE="$WORKSPACE/tasks/inbox.prompt.md"
  [[ -f "$TASK_FILE" ]] || printf "# inbox\n\n" > "$TASK_FILE"
  echo "Using default task: $TASK_FILE"
fi

# ---------- system prompt ----------
read -r -d '' SYSTEM_PROMPT <<'SYS' || true
You are AIworkbench Orchestrator. Reply with a single JSON object and nothing else.
Fields:
  intent: "estimate" | "generate" | "tweak" | "debug" | "chat"
  tier:   "Basic" | "Medium" | "Best" | "" (empty when not needed)
  reason: one short sentence justifying the decision
  task_update: optional text to append to the task prompt
  assistant: optional plain reply when intent == "chat"
No markdown, no code fences—JSON only.
SYS

# ---------- request builders ----------
make_body_gemini() {
  jq -n --arg sys "$SYSTEM_PROMPT" --arg u "$MESSAGE" '
  { contents: [ { role:"user", parts:[ {text:($sys + "\n\nUSER:\n" + $u)} ] } ] }'
}
make_body_claude() {
  jq -n --arg sys "$SYSTEM_PROMPT" --arg u "$MESSAGE" --arg m "${MODEL:-sonnet-3.5}" '
  { model:$m, max_tokens:512, system:$sys, messages:[ {role:"user", content:$u} ] }'
}

# ---------- model call ----------
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
      curl -fsS -H "x-api-key: ${ANTHROPIC_API_KEY}" \
        -H "anthropic-version: 2023-06-01" -H "content-type: application/json" \
        -d "$body" | jq -r '.content[0].text // empty'
      ;;
    *) return 10 ;;
  esac
}

# ---------- heuristic fallback ----------
heuristic_plan() {
  local lc; lc="$(printf '%s' "$MESSAGE" | tr '[:upper:]' '[:lower:]')"
  if   grep -Eq '\b(estimate|cost|price|quote)\b' <<<"$lc"; then echo '{"intent":"estimate","tier":"Medium","reason":"Asked to estimate."}'
  elif grep -Eq '\b(generate|build|create|scaffold|implement)\b' <<<"$lc"; then echo '{"intent":"generate","tier":"Medium","reason":"Asked to generate."}'
  elif grep -Eq '\b(tweak|modify|update|change|refactor|improve)\b' <<<"$lc"; then echo '{"intent":"tweak","tier":"Medium","reason":"Asked to tweak."}'
  elif grep -Eq '\b(debug|error|fix|bug|issue|trace)\b' <<<"$lc"; then echo '{"intent":"debug","tier":"Medium","reason":"Asked to debug."}'
  else printf '{"intent":"chat","assistant":%s,"reason":"General conversation."}' "$(printf '%s' "$MESSAGE" | jq -Rs .)"
  fi
}

# ---------- plan ----------
RAW="$(call_model 2>/dev/null || true)"
[[ -z "${RAW:-}" ]] && RAW="$(heuristic_plan)"
CLEAN="$(printf '%s' "$RAW" | strip_fences | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
if ! echo "$CLEAN" | jq -e . >/dev/null 2>&1; then
  CLEAN="$(printf '{"intent":"chat","assistant":%s}' "$(printf '%s' "$RAW" | jq -Rs .)")"
fi
PLAN="$(echo "$CLEAN" | jq -c '.')"

# ---------- show plan ----------
print_plan() {
  local p="$1"; echo "Agent plan:"
  echo "  intent : $(echo "$p" | json_get '.intent // "chat"')"
  local t; t="$(echo "$p" | json_get '.tier // ""')"; [[ -n "$t" ]] && echo "  tier   : $t"
  local r; r="$(echo "$p" | json_get '.reason // ""')"; [[ -n "$r" ]] && echo "  reason : $r"
}
print_plan "$PLAN"

INTENT="$(echo "$PLAN" | json_get '.intent // "chat"')"
TIER="$(echo   "$PLAN" | json_get '.tier   // ""')"
ASSIST="$(echo "$PLAN" | json_get '.assistant // ""')"
TASK_UPDATE="$(echo "$PLAN" | json_get '.task_update // ""')"

# ---------- update task prompt ----------
if [[ -n "$TASK_UPDATE" ]]; then
  {
    echo
    echo "## Chat update ($(date -Iseconds))"
    echo "$TASK_UPDATE"
  } >> "$TASK_FILE"
  echo "Updated task file: $TASK_FILE"
fi

# ---------- execute ----------
TASK_ID="$(basename "$TASK_FILE")"; TASK_ID="${TASK_ID%%.prompt.md}"

case "$INTENT" in
  chat|"")
    if [[ -n "$ASSIST" ]]; then echo; echo "$ASSIST"; echo
    else echo; echo "(chat) $MESSAGE"; echo
    fi
    exit 0
    ;;
  estimate|generate|tweak|debug)
    if [[ "$PROVIDER" == "gemini" ]]; then PRE="gpre.sh"; GO="ggo.sh"; DBG1="gout.sh"; DBG2="cout.sh"
    else PRE="cpre.sh"; GO="cgo.sh"; DBG1="cout.sh"; DBG2="gout.sh"; fi

    if ! have "$PRE"; then warn "$PRE missing (install via binpush)"; exit 1; fi
    echo; "$PRE" "$TASK_ID" ${TIER:+--tier="$TIER"} || true; echo

    [[ "$INTENT" == "estimate" ]] && exit 0

    gum_confirm "Proceed to ${INTENT^^} with tier ${TIER:-Medium}?" || { echo "Aborted."; exit 0; }

    case "$INTENT" in
      generate|tweak)
        if ! have "$GO"; then warn "$GO missing (install via binpush)"; exit 1; fi
        "$GO" "$TASK_ID" || true
        ;;
      debug)
        if have "$DBG1"; then "$DBG1" "$TASK_ID" || true
        elif have "$DBG2"; then "$DBG2" "$TASK_ID" || true
        else warn "No debug runner found."
        fi
        ;;
    esac
    ;;
  *)
    echo "Unknown intent: $INTENT"
    ;;
esac
