#!/usr/bin/env bash
# aiwb — AIworkbench Orchestrator (chat-first TUI)
# Cross-platform (Linux/macOS/Termux). Requires: bash, jq, curl, git; optional: gum, fzf, age.
# - Chat by default (gum UI if available; basic CLI fallback otherwise)
# - Model & context pickers (/model, /context)
# - Actions via slash-commands: /estimate, /generate, /tweak, /debug, /project, /task, /snap, /undo, /preview, /settings, /keys, /exit
# - Workspace lives at ~/.aiwb/workspace (projects, tasks, snapshots, logs)
# - Calls helpers (if present): gpre.sh, cpre.sh, ggo.sh, cgo.sh, keys-ui.sh, snap.sh, wlog.sh, projsync.sh
# - Does NOT store plaintext keys; use keys-ui.sh (age vault) or your preferred backend

set -euo pipefail

# ----------------------------- UTILITIES --------------------------------------
have()        { command -v "$1" >/dev/null 2>&1; }
is_termux()   { [[ "${PREFIX:-}" == *com.termux* ]] || [[ "${OSTYPE:-}" == "linux-android"* ]]; }
abs_path()    { python - <<'PY' 2>/dev/null || perl -MCwd=realpath -e 'print realpath(shift)."\n"' "$1" 2>/dev/null || readlink -f "$1" 2>/dev/null || echo "$1"
import os,sys; print(os.path.abspath(sys.argv[1]))
PY
}
timestamp()   { date +"%Y-%m-%d_%H-%M-%S"; }
err()         { printf "\033[1;31mEE\033[0m %s\n" "$*" >&2; }
warn()        { printf "\033[1;33m!!\033[0m %s\n" "$*" >&2; }
msg()         { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
die()         { err "$*"; exit 1; }

GUM_OK=false
if have gum; then GUM_OK=true; fi

# --------------------------- PATHS & CONFIG -----------------------------------
AIWB_HOME="${HOME}/.aiwb"
CONFIG_JSON="${AIWB_HOME}/config.json"

# Defaults if config missing
WS_ROOT_DEFAULT="${AIWB_HOME}/workspace"
PROJECTS_DIR_DEFAULT="${WS_ROOT_DEFAULT}/projects"
TASKS_DIR_DEFAULT="${WS_ROOT_DEFAULT}/tasks"
SNAP_DIR_DEFAULT="${WS_ROOT_DEFAULT}/snapshots"
LOGS_DIR_DEFAULT="${WS_ROOT_DEFAULT}/logs"

mkdir -p "$AIWB_HOME"
if [[ ! -f "$CONFIG_JSON" ]]; then
  cat >"$CONFIG_JSON" <<JSON
{
  "workspace": {
    "root": "$WS_ROOT_DEFAULT",
    "projects": "$PROJECTS_DIR_DEFAULT",
    "tasks": "$TASKS_DIR_DEFAULT",
    "snapshots": "$SNAP_DIR_DEFAULT",
    "logs": "$LOGS_DIR_DEFAULT"
  },
  "models": {
    "default_provider": "gemini",
    "gemini_default": "flash-1.5",
    "claude_default": "sonnet-3.5"
  },
  "ui": {
    "chat_first": true,
    "double_check_gate": true
  }
}
JSON
fi

jq_get() { jq -r "$1" "$CONFIG_JSON"; }

WS_ROOT="$(jq_get '.workspace.root'       2>/dev/null || echo "$WS_ROOT_DEFAULT")"
PROJECTS_DIR="$(jq_get '.workspace.projects' 2>/dev/null || echo "$PROJECTS_DIR_DEFAULT")"
TASKS_DIR="$(jq_get '.workspace.tasks'    2>/dev/null || echo "$TASKS_DIR_DEFAULT")"
SNAP_DIR="$(jq_get '.workspace.snapshots' 2>/dev/null || echo "$SNAP_DIR_DEFAULT")"
LOGS_DIR="$(jq_get '.workspace.logs'      2>/dev/null || echo "$LOGS_DIR_DEFAULT")"
UI_DOUBLE="$(jq_get '.ui.double_check_gate' 2>/dev/null || echo "true")"

mkdir -p "$WS_ROOT" "$PROJECTS_DIR" "$TASKS_DIR" "$SNAP_DIR" "$LOGS_DIR"

# --------------------------- SESSION STATE ------------------------------------
SESSION_FILE="${AIWB_HOME}/.session"
MODEL_PROVIDER="${MODEL_PROVIDER:-$(jq_get '.models.default_provider' 2>/dev/null || echo gemini)}" # gemini|claude
MODEL_NAME=""          # specific model (e.g., flash-1.5 or sonnet-3.5)
CURRENT_PROJECT=""     # project name (folder under projects/)
CURRENT_TASK=""        # task id (e.g., t0001)
CHAT_LOG="${LOGS_DIR}/chat_$(timestamp).log"

load_session() {
  [[ -f "$SESSION_FILE" ]] || return 0
  MODEL_PROVIDER="$(jq -r '.model_provider // empty' "$SESSION_FILE" || echo "$MODEL_PROVIDER")"
  MODEL_NAME="$(jq -r '.model_name // empty' "$SESSION_FILE" || echo "")"
  CURRENT_PROJECT="$(jq -r '.project // empty' "$SESSION_FILE" || echo "")"
  CURRENT_TASK="$(jq -r '.task // empty' "$SESSION_FILE" || echo "")"
}
save_session() {
  cat >"$SESSION_FILE" <<JSON
{"model_provider":"$MODEL_PROVIDER","model_name":"$MODEL_NAME","project":"$CURRENT_PROJECT","task":"$CURRENT_TASK"}
JSON
}

load_session || true

# ------------------------- MODEL/PROVIDER PICKERS -----------------------------
default_model_for() {
  case "$1" in
    gemini) jq_get '.models.gemini_default' 2>/dev/null || echo "flash-1.5" ;;
    claude) jq_get '.models.claude_default' 2>/dev/null || echo "sonnet-3.5" ;;
    *) echo "" ;;
  esac
}

pick_model_provider() {
  local choice
  if $GUM_OK; then
    choice="$(printf "gemini\nclaude" | gum choose --header "Choose model provider")" || return 1
  else
    echo "Choose provider: [1] gemini  [2] claude"
    read -rp "> " ans
    case "$ans" in 1) choice="gemini" ;; 2) choice="claude" ;; *) return 1 ;; esac
  fi
  MODEL_PROVIDER="$choice"
  MODEL_NAME="$(default_model_for "$MODEL_PROVIDER")"
  save_session
}

pick_model_name() {
  # simple candidate list; you can extend
  local list=""
  case "$MODEL_PROVIDER" in
    gemini) list="flash-1.5\npro-1.5" ;;
    claude) list="sonnet-3.5\nhaiku-3.5" ;;
    *) list="" ;;
  esac
  if [[ -z "$list" ]]; then return 0; fi
  local choice
  if $GUM_OK; then
    choice="$(printf "%b" "$list" | gum choose --header "Choose $MODEL_PROVIDER model")" || return 1
  else
    echo -e "Choose $MODEL_PROVIDER model:\n$list"
    read -rp "> " choice
  fi
  [[ -n "$choice" ]] && MODEL_NAME="$choice" && save_session
}

# ----------------------------- CONTEXT PICKERS --------------------------------
list_projects() { find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | sort; }
list_tasks()    { find "$TASKS_DIR" -maxdepth 1 -type f -name 't*.prompt.md' -printf "%f\n" 2>/dev/null | sort; }

pick_project() {
  local items; items="$(list_projects || true)"
  if [[ -z "$items" ]]; then
    warn "No projects in $PROJECTS_DIR. Use /project new or /generate to create one."
    return 1
  fi
  local choice
  if $GUM_OK; then
    choice="$(printf "%s\n" "$items" | gum choose --no-limit=false --header "Select project")" || return 1
  else
    echo "Select project:"; echo "$items"; read -rp "> " choice
  fi
  CURRENT_PROJECT="$choice"
  save_session
}

new_project_dialog() {
  local name url
  if $GUM_OK; then
    name="$(gum input --placeholder "Project name (letters, digits, dashes)")" || return 1
    url="$(gum input --placeholder "Git URL (optional to clone)")" || true
  else
    read -rp "Project name: " name
    read -rp "Git URL (optional): " url
  fi
  [[ -z "$name" ]] && { warn "Empty name."; return 1; }
  local dir="${PROJECTS_DIR}/${name}"
  if [[ -d "$dir/.git" || -d "$dir" ]]; then
    warn "Project exists: $dir"
  else
    mkdir -p "$dir"
    if [[ -n "$url" ]]; then
      msg "Cloning $url → $dir"
      git clone "$url" "$dir" || warn "Clone failed; leaving empty project."
    else
      # initialize bare layout
      echo "# ${name}" > "${dir}/README.md"
    fi
  fi
  CURRENT_PROJECT="$name"
  save_session
}

pick_task() {
  local items; items="$(list_tasks || true)"
  if [[ -z "$items" ]]; then
    warn "No tasks yet in $TASKS_DIR. Use /task new"
    return 1
  fi
  local choice
  if $GUM_OK; then
    choice="$(printf "%s\n" "$items" | gum choose --no-limit=false --header "Select task (t####.prompt.md)")" || return 1
  else
    echo "Select task:"; echo "$items"; read -rp "> " choice
  fi
  CURRENT_TASK="${choice%%.prompt.md}"
  save_session
}

new_task_dialog() {
  local id
  if $GUM_OK; then
    id="$(gum input --placeholder "Task id e.g., t0001")" || return 1
  else
    read -rp "Task id (t####): " id
  fi
  [[ -z "$id" ]] && { warn "Empty."; return 1; }
  local f="${TASKS_DIR}/${id}.prompt.md"
  if [[ -f "$f" ]]; then
    warn "Task exists: $f"
  else
    echo -e "# $id\n\nDescribe the task here." > "$f"
  fi
  CURRENT_TASK="$id"
  save_session
  edit_file "$f"
}

edit_file() {
  local f="$1"
  if $GUM_OK; then gum pager < "$f" >/dev/null 2>&1 || true; fi
  # simple editors: $EDITOR or nano or vi
  local ed="${EDITOR:-}"
  if [[ -z "$ed" ]]; then
    if have nano; then ed="nano"; else ed="vi"; fi
  fi
  "$ed" "$f"
}

# ---------------------------- KEYS & SETTINGS ---------------------------------
keys_ui() {
  if command -v keys-ui.sh >/dev/null 2>&1; then
    keys-ui.sh
  else
    warn "keys-ui.sh not installed. Use your preferred method (age vault or env vars)."
  fi
}

settings_ui() {
  if ! $GUM_OK; then
    echo "Settings (basic):"
    echo "1) Provider (gemini/claude)"
    echo "2) Model name"
    echo "3) Keys UI"
    echo "4) Back"
    read -rp "> " a
    case "$a" in
      1) pick_model_provider ;;
      2) pick_model_name ;;
      3) keys_ui ;;
    esac
    return
  fi
  while true; do
    local sel; sel="$(printf "Provider: %s\nModel: %s\nKeys…\nBack" "$MODEL_PROVIDER" "$MODEL_NAME" | gum choose --header "Settings")" || return
    case "$sel" in
      "Provider:"*) pick_model_provider ;;
      "Model:"*)    pick_model_name ;;
      "Keys…")      keys_ui ;;
      "Back")       return ;;
    esac
  done
}

# ----------------------------- ACTIONS ----------------------------------------
ensure_project_selected() {
  [[ -n "$CURRENT_PROJECT" ]] && return 0
  warn "No project selected."
  pick_project || new_project_dialog || return 1
}

ensure_task_selected() {
  [[ -n "$CURRENT_TASK" ]] && return 0
  warn "No task selected."
  pick_task || new_task_dialog || return 1
}

estimate_action() {
  ensure_task_selected || return 1
  local id="$CURRENT_TASK"
  local out
  case "$MODEL_PROVIDER" in
    gemini)
      if ! command -v gpre.sh >/dev/null 2>&1; then warn "gpre.sh not installed."; return 1; fi
      out="$(gpre.sh "$id" 2>&1)" || true
      ;;
    claude)
      if ! command -v cpre.sh >/dev/null 2>&1; then warn "cpre.sh not installed."; return 1; fi
      out="$(cpre.sh "$id" 2>&1)" || true
      ;;
    *) warn "Unknown provider: $MODEL_PROVIDER"; return 1 ;;
  esac
  echo "$out" | tee -a "$CHAT_LOG"
}

tier_confirm_dialog() {
  # returns chosen tier in $TI
  local ti=""
  if $GUM_OK; then
    ti="$(printf "Abort\nBasic\nMedium\nBest" | gum choose --header "Choose tier")" || true
  else
    echo "Tier: [a]bort [b]asic [m]edium [B]est"; read -rp "> " ans
    case "$ans" in a|A) ti="Abort";; b|B) ti="Basic";; m|M) ti="Medium";; *) ti="Best";; esac
  fi
  TI="$ti"
}

double_check_if_enabled() {
  [[ "$UI_DOUBLE" == "true" ]] || return 0
  # Very light stub: ask if you want a cross‑model critique now.
  local go="No"
  if $GUM_OK; then
    go="$(printf "No\nYes" | gum choose --header "Double-check with other model?")" || true
  else
    read -rp "Double-check with other model? [y/N] " yn; [[ "$yn" =~ ^[Yy]$ ]] && go="Yes"
  fi
  [[ "$go" == "Yes" ]] || return 0
  # Call the opposite pre-check quickly (best-effort)
  case "$MODEL_PROVIDER" in
    gemini) command -v cpre.sh >/dev/null 2>&1 && cpre.sh "$CURRENT_TASK" | tee -a "$CHAT_LOG" || warn "Claude pre-check unavailable." ;;
    claude) command -v gpre.sh >/dev/null 2>&1 && gpre.sh "$CURRENT_TASK" | tee -a "$CHAT_LOG" || warn "Gemini pre-check unavailable." ;;
  esac
}

generate_action() {
  ensure_project_selected || return 1
  ensure_task_selected || return 1
  estimate_action || true
  tier_confirm_dialog
  [[ "$TI" == "Abort" || -z "$TI" ]] && { warn "Aborted."; return 1; }
  double_check_if_enabled || true

  case "$MODEL_PROVIDER" in
    gemini)
      if command -v ggo.sh >/dev/null 2>&1; then
        ggo.sh "$CURRENT_TASK" | tee -a "$CHAT_LOG"
      else
        warn "ggo.sh not installed. Generation skipped."
      fi
      ;;
    claude)
      if command -v cgo.sh >/dev/null 2>&1; then
        cgo.sh "$CURRENT_TASK" | tee -a "$CHAT_LOG"
      else
        warn "cgo.sh not installed. Generation skipped."
      fi
      ;;
  esac
}

tweak_action() {
  ensure_project_selected || return 1
  ensure_task_selected || return 1
  estimate_action || true
  tier_confirm_dialog
  [[ "$TI" == "Abort" || -z "$TI" ]] && { warn "Aborted."; return 1; }
  double_check_if_enabled || true
  # Reuse go scripts; your go scripts should inspect prompt to decide tweak vs gen
  generate_action
}

debug_action() {
  ensure_project_selected || return 1
  ensure_task_selected || return 1
  estimate_action || true
  tier_confirm_dialog
  [[ "$TI" == "Abort" || -z "$TI" ]] && { warn "Aborted."; return 1; }
  double_check_if_enabled || true
  # You can wire cout.sh/gout.sh here:
  if command -v cout.sh >/dev/null 2>&1; then
    cout.sh "$CURRENT_TASK" | tee -a "$CHAT_LOG"
  elif command -v gout.sh >/dev/null 2>&1; then
    gout.sh "$CURRENT_TASK" | tee -a "$CHAT_LOG"
  else
    warn "No debug runner (cout.sh/gout.sh)."
  fi
}

preview_action() {
  # Implement your preview strategy (http-server logs, diff, last artifacts)
  if command -v wlog.sh >/dev/null 2>&1; then
    wlog.sh | tail -n 200
  else
    warn "wlog.sh not found; show last 200 lines from chat log instead."
    tail -n 200 "$CHAT_LOG"
  fi
}

snap_action() {
  if command -v snap.sh >/dev/null 2>&1; then
    snap.sh "$CURRENT_PROJECT" | tee -a "$CHAT_LOG"
  else
    warn "snap.sh not found."
  fi
}

undo_action() {
  # Placeholder: depends on your snapshot tooling
  warn "Undo not wired yet; restore from snapshots in $SNAP_DIR."
}

project_menu() {
  if ! $GUM_OK; then
    echo "Project: [s]elect [n]ew [b]ack"; read -rp "> " a
    case "$a" in s|S) pick_project ;; n|N) new_project_dialog ;; esac
    return
  fi
  local sel; sel="$(printf "Select…\nNew…\nBack" | gum choose --header "Project")" || return
  case "$sel" in
    "Select…") pick_project ;;
    "New…")    new_project_dialog ;;
  esac
}

task_menu() {
  if ! $GUM_OK; then
    echo "Task: [s]elect [n]ew [e]dit [b]ack"; read -rp "> " a
    case "$a" in s|S) pick_task ;; n|N) new_task_dialog ;; e|E) [[ -n "$CURRENT_TASK" ]] && edit_file "${TASKS_DIR}/${CURRENT_TASK}.prompt.md" || warn "No task."; esac
    return
  fi
  local sel; sel="$(printf "Select…\nNew…\nEdit current…\nBack" | gum choose --header "Task")" || return
  case "$sel" in
    "Select…") pick_task ;;
    "New…")    new_task_dialog ;;
    "Edit current…") [[ -n "$CURRENT_TASK" ]] && edit_file "${TASKS_DIR}/${CURRENT_TASK}.prompt.md" || warn "No task selected." ;;
  esac
}

context_menu() {
  if ! $GUM_OK; then
    echo "Context: [p]roject [t]ask [m]odel [b]ack"; read -rp "> " a
    case "$a" in p|P) project_menu ;; t|T) task_menu ;; m|M) pick_model_provider; pick_model_name ;; esac
    return
  fi
  local sel; sel="$(printf "Project…\nTask…\nModel…\nBack" | gum choose --header "Context")" || return
  case "$sel" in
    "Project…") project_menu ;;
    "Task…")    task_menu ;;
    "Model…")   pick_model_provider; pick_model_name ;;
  esac
}

# ----------------------------- CHAT LOOP --------------------------------------
render_header() {
  local p="${CURRENT_PROJECT:-—}"
  local t="${CURRENT_TASK:-—}"
  local m="${MODEL_PROVIDER}${MODEL_NAME:+/$MODEL_NAME}"
  printf "[Project:%s] [Task:%s] [Model:%s]\n" "$p" "$t" "$m"
}

help_lines() {
  cat <<'HLP'
Commands:
/estimate      - cost estimate for current task
/generate      - scaffold or apply changes to current project
/tweak         - modify existing codebase per prompt
/debug         - run debugger flow
/project       - select/new project
/task          - select/new/edit task prompt
/context       - pick project/task/model
/preview       - show last output/diff/log
/snap          - snapshot current project
/undo          - restore previous snapshot (manual for now)
/settings      - settings menu (provider/model/keys)
/keys          - open keys UI (encrypted vault)
/help          - show this help
/exit          - quit
HLP
}

handle_command() {
  local cmd="$1"
  case "$cmd" in
    /estimate)  estimate_action ;;
    /generate)  generate_action ;;
    /tweak)     tweak_action ;;
    /debug)     debug_action ;;
    /project)   project_menu ;;
    /task)      task_menu ;;
    /context)   context_menu ;;
    /preview)   preview_action ;;
    /snap)      snap_action ;;
    /undo)      undo_action ;;
    /settings)  settings_ui ;;
    /keys)      keys_ui ;;
    /help)      help_lines ;;
    /exit)      exit 0 ;;
    *)          warn "Unknown command. Type /help" ;;
  esac
}

chat_loop_gum() {
  clear
  msg "AIworkbench — Chat (gum UI). Type /help for commands."
  while true; do
    echo
    render_header
    # input box
    local input; input="$(gum input --placeholder "Message or /command" || true)"
    [[ -z "$input" ]] && continue
    echo "> $input" | tee -a "$CHAT_LOG"
    if [[ "$input" == /* ]]; then
      handle_command "$input"
      continue
    fi
    # Free-form message to orchestrator (no spend by default).
    # You can wire a lightweight local agent here. For now we just log it.
    printf "[note] Free-form chat recorded. Use /estimate then /generate to act.\n" | tee -a "$CHAT_LOG"
  done
}

chat_loop_cli() {
  msg "AIworkbench — Chat (basic). Type /help for commands."
  while true; do
    echo
    render_header
    read -rp "> " input || exit 0
    [[ -z "$input" ]] && continue
    echo "> $input" | tee -a "$CHAT_LOG"
    if [[ "$input" == /* ]]; then
      handle_command "$input"
    else
      echo "[note] Free-form chat recorded. Use /estimate then /generate to act." | tee -a "$CHAT_LOG"
    fi
  done
}

# ------------------------------- ENTRY ----------------------------------------
if $GUM_OK; then
  chat_loop_gum
else
  chat_loop_cli
fi
