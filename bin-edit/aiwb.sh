#!/usr/bin/env bash
# aiwb — AIworkbench Orchestrator (chat-first TUI)
# - Default interaction is chat. No project/task required.
# - Workspace defaults to ~/storage/shared/aiwb if available (Android-visible),
#   otherwise ~/.aiwb/workspace.
# - Keys are read from ~/.aiwb.env (created via /keys).
# - Auto-fixes CRLF in installed tools on startup.
# - Slash commands still work: /help /keys /settings /estimate /generate /debug /exit
# - Cross-platform: Termux/Linux/macOS. Requires: bash, jq, curl; optional: gum, fzf, git.

set -euo pipefail

have()       { command -v "$1" >/dev/null 2>&1; }
err()        { printf "\033[1;31mEE\033[0m %s\n" "$*" >&2; }
warn()       { printf "\033[1;33m!!\033[0m %s\n" "$*" >&2; }
msg()        { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
is_termux()  { [[ "${PREFIX:-}" == *com.termux* ]] || [[ "${OSTYPE:-}" == "linux-android"* ]]; }

GUM=false; have gum && GUM=true

# ---------- env/keys ----------
[ -f "$HOME/.aiwb.env" ] && . "$HOME/.aiwb.env" || true

# ---------- choose workspace (Android-visible if possible) ----------
choose_workspace() {
  local shared="$HOME/storage/shared"
  if [[ -d "$shared" ]]; then
    echo "$shared/aiwb"
  else
    echo "$HOME/.aiwb/workspace"
  fi
}
WS_ROOT="${AIWB_WORKSPACE:-$(choose_workspace)}"
PROJECTS_DIR="$WS_ROOT/projects"
TASKS_DIR="$WS_ROOT/tasks"
SNAP_DIR="$WS_ROOT/snapshots"
LOGS_DIR="$WS_ROOT/logs"
mkdir -p "$PROJECTS_DIR" "$TASKS_DIR" "$SNAP_DIR" "$LOGS_DIR"

# ---------- fix CRLF in installed tools (common Termux issue) ----------
fix_crlf_installed() {
  local offenders
  offenders="$(grep -IRl $'\r' "$HOME/.local/bin" 2>/dev/null || true)"
  if [[ -n "$offenders" ]]; then
    echo "$offenders" | while IFS= read -r f; do
      [[ "${f##*.}" == "sh" ]] || continue
      sed -i 's/\r$//' "$f"
    done
    msg "Normalized CRLF in $(echo "$offenders" | wc -l) installed scripts."
    hash -r
  fi
}
fix_crlf_installed

# ---------- session ----------
AIWB_HOME="$HOME/.aiwb"
SESSION_FILE="$AIWB_HOME/.session"
mkdir -p "$AIWB_HOME"

MODEL_PROVIDER="${MODEL_PROVIDER:-gemini}"     # gemini|claude
MODEL_NAME="${MODEL_NAME:-}"                   # filled from default if empty
CURRENT_TASK="${CURRENT_TASK:-}"               # optional
CHAT_LOG="$LOGS_DIR/chat_$(date +%Y%m%d_%H%M%S).log"

default_model_for() {
  case "$1" in
    gemini) echo "flash-1.5" ;;
    claude) echo "sonnet-3.5" ;;
    *) echo "" ;;
  esac
}

save_session() {
  cat >"$SESSION_FILE" <<JSON
{"workspace":"$WS_ROOT","model_provider":"$MODEL_PROVIDER","model_name":"${MODEL_NAME:-}","task":"$CURRENT_TASK"}
JSON
}
load_session() {
  [[ -f "$SESSION_FILE" ]] || return 0
  WS_ROOT="$(jq -r '.workspace // empty' "$SESSION_FILE" 2>/dev/null || echo "$WS_ROOT")"
  MODEL_PROVIDER="$(jq -r '.model_provider // empty' "$SESSION_FILE" 2>/dev/null || echo "$MODEL_PROVIDER")"
  MODEL_NAME="$(jq -r '.model_name // empty' "$SESSION_FILE" 2>/dev/null || echo "")"
  CURRENT_TASK="$(jq -r '.task // empty' "$SESSION_FILE" 2>/dev/null || echo "")"
}
have jq && load_session || true
[[ -z "$MODEL_NAME" ]] && MODEL_NAME="$(default_model_for "$MODEL_PROVIDER")"

# ---------- keys UI ----------
set_key() {
  local name="$1" current="${!1:-}" val
  if $GUM; then
    val="$(gum input --password --placeholder "$name value" --value "$current")" || return 1
  else
    read -rsp "Enter $name: " val; echo
  fi
  [[ -z "$val" ]] && { warn "$name unchanged"; return 0; }
  perl -0777 -pe "BEGIN{\\$n=q/$name/;\\$v=q/$val/}
                  if(-e \"$HOME/.aiwb.env\"){\\$_=\\$_} END{}" </dev/null >/dev/null 2>&1 || true
  # write/update in ~/.aiwb.env
  if grep -q "^export $name=" "$HOME/.aiwb.env" 2>/dev/null; then
    sed -i "s|^export $name=.*\$|export $name=\"$val\"|" "$HOME/.aiwb.env"
  else
    printf 'export %s="%s"\n' "$name" "$val" >> "$HOME/.aiwb.env"
  fi
  chmod 600 "$HOME/.aiwb.env" 2>/dev/null || true
  # load into current shell
  export "$name=$val"
  msg "Saved $name to ~/.aiwb.env"
}
keys_menu() {
  [[ -f "$HOME/.aiwb.env" ]] && . "$HOME/.aiwb.env" || true
  local g="${GEMINI_API_KEY:+✅}" a="${ANTHROPIC_API_KEY:+✅}"
  if $GUM; then
    while true; do
      local choice
      choice="$(printf "Set GEMINI_API_KEY %s\nSet ANTHROPIC_API_KEY %s\nBack" "$g" "$a" | gum choose --header "API Keys")" || return
      case "$choice" in
        "Set GEMINI_API_KEY "*) set_key GEMINI_API_KEY ;;
        "Set ANTHROPIC_API_KEY "*) set_key ANTHROPIC_API_KEY ;;
        Back) return ;;
      esac
    done
  else
    echo "1) Set GEMINI_API_KEY $g"
    echo "2) Set ANTHROPIC_API_KEY $a"
    echo "3) Back"
    read -rp "> " ans
    case "$ans" in
      1) set_key GEMINI_API_KEY ;;
      2) set_key ANTHROPIC_API_KEY ;;
      *) ;;
    esac
  fi
}

# ---------- header/help ----------
header() {
  local vis="(internal)"
  [[ "$WS_ROOT" == "$HOME/storage/shared/"* ]] && vis="(Android-visible)"
  printf "[Workspace:%s %s] [Task:%s] [Model:%s/%s]\n" \
    "$WS_ROOT" "$vis" "${CURRENT_TASK:-—}" "$MODEL_PROVIDER" "${MODEL_NAME:-default}"
}
help_text() {
  cat <<'HLP'
Commands:
/help       show this help
/keys       set or update API keys (saved to ~/.aiwb.env)
/settings   change provider/model
/estimate   ask agent to estimate current (or inbox) task
/generate   ask agent to generate/apply changes
/debug      ask agent to run debug flow
/exit       quit
Tip: just type normally — the agent will propose a plan and ask to confirm.
HLP
}

# ---------- settings ----------
settings_menu() {
  if $GUM; then
    local choice; choice="$(printf "Provider: %s\nModel: %s\nBack" "$MODEL_PROVIDER" "${MODEL_NAME:-default}" | gum choose --header "Settings")" || return
    case "$choice" in
      Provider:*) choice="$(printf "gemini\nclaude" | gum choose --header "Choose provider")" || return
                  MODEL_PROVIDER="$choice"; MODEL_NAME="$(default_model_for "$MODEL_PROVIDER")" ;;
      Model:*)    if [[ "$MODEL_PROVIDER" == "gemini" ]]; then
                    choice="$(printf "flash-1.5\npro-1.5" | gum choose --header "Choose Gemini model")" || return
                  else
                    choice="$(printf "sonnet-3.5\nhaiku-3.5" | gum choose --header "Choose Claude model")" || return
                  fi
                  MODEL_NAME="$choice" ;;
      Back)       ;;
    esac
  else
    echo "Provider now: $MODEL_PROVIDER"; echo "1) gemini  2) claude"; read -rp "> " a
    case "$a" in 1) MODEL_PROVIDER=gemini ;; 2) MODEL_PROVIDER=claude ;; esac
    MODEL_NAME="$(default_model_for "$MODEL_PROVIDER")"
  fi
  save_session
}

# ---------- agent call ----------
run_agent() {
  local msgtxt="$1"
  local args=( --provider "$MODEL_PROVIDER" --model "${MODEL_NAME:-}" --message "$msgtxt" --workspace "$WS_ROOT" )
  # If a task is selected, pass it. Otherwise agent will use inbox.prompt.md automatically.
  if [[ -n "${CURRENT_TASK:-}" ]]; then
    args+=( --taskfile "$TASKS_DIR/${CURRENT_TASK}.prompt.md" )
  fi
  if ! command -v chat-runner.sh >/dev/null 2>&1; then
    warn "chat-runner.sh not installed (run binpush)."
    echo "[note] Free-form chat recorded. Use /keys then /estimate or /generate." | tee -a "$CHAT_LOG"
    return
  fi
  chat-runner.sh "${args[@]}" | tee -a "$CHAT_LOG"
}

# ---------- actions that just delegate to agent ----------
estimate_action() { run_agent "estimate"; }
generate_action() { run_agent "generate"; }
debug_action()    { run_agent "debug"; }

# ---------- chat loops ----------
chat_loop_gum() {
  clear
  msg "AIworkbench — Chat (gum UI). Type /help for commands."
  echo "Workspace: $WS_ROOT"
  while true; do
    echo; header
    local inp; inp="$(gum input --placeholder "Message or /command" || true)"
    [[ -z "$inp" ]] && continue
    echo "> $inp" | tee -a "$CHAT_LOG"
    case "$inp" in
      /help)     help_text ;;
      /keys)     keys_menu ;;
      /settings) settings_menu ;;
      /estimate) estimate_action ;;
      /generate) generate_action ;;
      /debug)    debug_action ;;
      /exit)     exit 0 ;;
      *)         run_agent "$inp" ;;
    esac
  done
}
chat_loop_cli() {
  msg "AIworkbench — Chat (basic). Type /help for commands."
  echo "Workspace: $WS_ROOT"
  while true; do
    echo; header
    read -rp "> " inp || exit 0
    [[ -z "$inp" ]] && continue
    echo "> $inp" | tee -a "$CHAT_LOG"
    case "$inp" in
      /help)     help_text ;;
      /keys)     keys_menu ;;
      /settings) settings_menu ;;
      /estimate) estimate_action ;;
      /generate) generate_action ;;
      /debug)    debug_action ;;
      /exit)     exit 0 ;;
      *)         run_agent "$inp" ;;
    esac
  done
}

# ---------- entry ----------
save_session
if $GUM; then chat_loop_gum; else chat_loop_cli; fi
