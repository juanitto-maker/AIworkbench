#!/usr/bin/env bash
# aiwb — AIworkbench Orchestrator (Agent Mode)
# - Chat-first TUI (gum input if available; plain CLI fallback)
# - Normal messages go to chat-runner.sh which:
#     • asks the model (Gemini/Claude) for a plan in JSON
#     • shows you the plan
#     • on confirm, runs estimate/generate/tweak/debug using your helpers
# - Slash commands still work: /estimate /generate /tweak /debug /project /task /context /settings /keys /help /exit
# - Workspace at ~/.aiwb/workspace (projects, tasks, snapshots, logs)

set -euo pipefail

# ----------------------------- UTILITIES --------------------------------------
have()        { command -v "$1" >/dev/null 2>&1; }
is_termux()   { [[ "${PREFIX:-}" == *com.termux* ]] || [[ "${OSTYPE:-}" == "linux-android"* ]]; }
timestamp()   { date +"%Y-%m-%d_%H-%M-%S"; }
err()         { printf "\033[1;31mEE\033[0m %s\n" "$*" >&2; }
warn()        { printf "\033[1;33m!!\033[0m %s\n" "$*" >&2; }
msg()         { printf "\033[1;32m==>\033[0m %s\n" "$*"; }

GUM_OK=false
have gum && GUM_OK=true

# --------------------------- PATHS & CONFIG -----------------------------------
AIWB_HOME="${HOME}/.aiwb"
CONFIG_JSON="${AIWB_HOME}/config.json"

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

WS_ROOT="$(jq_get '.workspace.root' 2>/dev/null || echo "$WS_ROOT_DEFAULT")"
PROJECTS_DIR="$(jq_get '.workspace.projects' 2>/dev/null || echo "$PROJECTS_DIR_DEFAULT")"
TASKS_DIR="$(jq_get '.workspace.tasks' 2>/dev/null || echo "$TASKS_DIR_DEFAULT")"
SNAP_DIR="$(jq_get '.workspace.snapshots' 2>/dev/null || echo "$SNAP_DIR_DEFAULT")"
LOGS_DIR="$(jq_get '.workspace.logs' 2>/dev/null || echo "$LOGS_DIR_DEFAULT")"
UI_DOUBLE="$(jq_get '.ui.double_check_gate' 2>/dev/null || echo "true")"

mkdir -p "$WS_ROOT" "$PROJECTS_DIR" "$TASKS_DIR" "$SNAP_DIR" "$LOGS_DIR"

# --------------------------- SESSION STATE ------------------------------------
SESSION_FILE="${AIWB_HOME}/.session"
MODEL_PROVIDER="${MODEL_PROVIDER:-$(jq_get '.models.default_provider' 2>/dev/null || echo gemini)}" # gemini|claude
MODEL_NAME=""
CURRENT_PROJECT=""
CURRENT_TASK=""
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

default_model_for() {
  case "$1" in
    gemini) jq_get '.models.gemini_default' 2>/dev/null || echo "flash-1.5" ;;
    claude) jq_get '.models.claude_default' 2>/dev/null || echo "sonnet-3.5" ;;
    *) echo "" ;;
  esac
}

# ----------------------------- PICKERS ----------------------------------------
list_projects() { find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | sort; }
list_tasks()    { find "$TASKS_DIR" -maxdepth 1 -type f -name 't*.prompt.md' -printf "%f\n" 2>/dev/null | sort; }

pick_model_provider() {
  local choice
  if $GUM_OK; then
    choice="$(printf "gemini\nclaude" | gum choose --header "Choose model provider")" || return 1
  else
    echo "Choose provider: [1] gemini  [2] claude"; read -r ans
    case "$ans" in 1) choice="gemini" ;; 2) choice="claude" ;; *) return 1 ;; esac
  fi
  MODEL_PROVIDER="$choice"
  MODEL_NAME="$(default_model_for "$MODEL_PROVIDER")"
  save_session
}
pick_model_name() {
  local list=""
  case "$MODEL_PROVIDER" in
    gemini) list="flash-1.5\npro-1.5" ;;
    claude) list="sonnet-3.5\nhaiku-3.5" ;;
  esac
  local choice
  if $GUM_OK; then
    choice="$(printf "%b" "$list" | gum choose --header "Choose $MODEL_PROVIDER model")" || return 1
  else
    echo -e "Choose $MODEL_PROVIDER model:\n$list"; read -r choice
  fi
  [[ -n "$choice" ]] && MODEL_NAME="$choice" && save_session
}

pick_project() {
  local items; items="$(list_projects || true)"
  if [[ -z "$items" ]]; then warn "No projects in $PROJECTS_DIR."; return 1; fi
  local choice
  if $GUM_OK; then choice="$(printf "%s\n" "$items" | gum choose --header "Select project")" || return 1
  else echo "$items"; read -r choice; fi
  CURRENT_PROJECT="$choice"; save_session
}
new_project_dialog() {
  local name url
  if $GUM_OK; then
    name="$(gum input --placeholder "Project name")" || return 1
    url="$(gum input --placeholder "Git URL (optional)")" || true
  else
    read -rp "Project name: " name; read -rp "Git URL (optional): " url
  fi
  [[ -z "$name" ]] && { warn "Empty name."; return 1; }
  local dir="${PROJECTS_DIR}/${name}"
  mkdir -p "$dir"
  if [[ -n "$url" ]]; then git clone "$url" "$dir" || warn "Clone failed; created empty project."; else echo "# ${name}" > "${dir}/README.md"; fi
  CURRENT_PROJECT="$name"; save_session
}
pick_task() {
  local items; items="$(list_tasks || true)"
  if [[ -z "$items" ]]; then warn "No tasks in $TASKS_DIR."; return 1; fi
  local choice
  if $GUM_OK; then choice="$(printf "%s\n" "$items" | gum choose --header "Select task")" || return 1
  else echo "$items"; read -r choice; fi
  CURRENT_TASK="${choice%%.prompt.md}"; save_session
}
new_task_dialog() {
  local id
  if $GUM_OK; then id="$(gum input --placeholder "Task id e.g., t0003")" || return 1
  else read -rp "Task id (t####): " id; fi
  [[ -z "$id" ]] && { warn "Empty."; return 1; }
  local f="${TASKS_DIR}/${id}.prompt.md"
  [[ -f "$f" ]] || echo -e "# $id\n\nDescribe the task here." > "$f"
  CURRENT_TASK="$id"; save_session
  edit_file "$f"
}
edit_file() {
  local f="$1"; $GUM_OK && gum pager < "$f" >/dev/null 2>&1 || true
  local ed="${EDITOR:-}"; [[ -z "$ed" ]] && { have nano && ed=nano || ed=vi; }; "$ed" "$f"
}

# ---------------------------- KEYS & SETTINGS ---------------------------------
keys_ui() { command -v keys-ui.sh >/dev/null 2>&1 && keys-ui.sh || warn "keys-ui.sh not installed."; }
settings_ui() {
  if ! $GUM_OK; then
    echo "Settings: 1) Provider  2) Model  3) Keys  4) Back"; read -r a
    case "$a" in 1) pick_model_provider ;; 2) pick_model_name ;; 3) keys_ui ;; esac; return
  fi
  while true; do
    local sel; sel="$(printf "Provider: %s\nModel: %s\nKeys…\nBack" "$MODEL_PROVIDER" "$MODEL_NAME" | gum choose --header "Settings")" || return
    case "$sel" in
      Provider:*) pick_model_provider ;;
      Model:*)    pick_model_name ;;
      Keys…)      keys_ui ;;
      Back)       return ;;
    esac
  done
}

# ----------------------------- ACTIONS ----------------------------------------
ensure_project_selected() { [[ -n "$CURRENT_PROJECT" ]] || { warn "No project. Use /project"; return 1; }; }
ensure_task_selected()    { [[ -n "$CURRENT_TASK" ]]    || { warn "No task. Use /task";    return 1; }; }

estimate_action() {
  ensure_task_selected || return 1
  local id="$CURRENT_TASK" out
  case "$MODEL_PROVIDER" in
    gemini)  command -v gpre.sh >/dev/null || { warn "gpre.sh missing"; return 1; }
             out="$(gpre.sh "$id" 2>&1)" || true ;;
    claude)  command -v cpre.sh >/dev/null || { warn "cpre.sh missing"; return 1; }
             out="$(cpre.sh "$id" 2>&1)" || true ;;
    *) warn "Unknown provider $MODEL_PROVIDER"; return 1 ;;
  esac
  echo "$out" | tee -a "$CHAT_LOG"
}
generate_action() {
  ensure_project_selected || return 1; ensure_task_selected || return 1
  estimate_action || true
  local script=""; [[ "$MODEL_PROVIDER" == "gemini" ]] && script="ggo.sh" || script="cgo.sh"
  if command -v "$script" >/dev/null 2>&1; then "$script" "$CURRENT_TASK" | tee -a "$CHAT_LOG"; else warn "$script missing"; fi
}
tweak_action()  { generate_action; }
debug_action()  {
  ensure_project_selected || return 1; ensure_task_selected || return 1
  if command -v cout.sh >/dev/null 2>&1; then cout.sh "$CURRENT_TASK" | tee -a "$CHAT_LOG"
  elif command -v gout.sh >/dev/null 2>&1; then gout.sh "$CURRENT_TASK" | tee -a "$CHAT_LOG"
  else warn "No debug runner (cout.sh/gout.sh)."; fi
}
preview_action(){ command -v wlog.sh >/dev/null 2>&1 && wlog.sh | tail -n 200 || tail -n 200 "$CHAT_LOG"; }
snap_action()   { command -v snap.sh >/dev/null 2>&1 && snap.sh "$CURRENT_PROJECT" | tee -a "$CHAT_LOG" || warn "snap.sh missing"; }
undo_action()   { warn "Undo not wired; restore from $SNAP_DIR manually."; }

project_menu() {
  if ! $GUM_OK; then echo "[s]elect [n]ew [b]ack"; read -r a; case "$a" in s|S) pick_project ;; n|N) new_project_dialog ;; esac; return; fi
  local sel; sel="$(printf "Select…\nNew…\nBack" | gum choose --header "Project")" || return
  case "$sel" in "Select…") pick_project ;; "New…") new_project_dialog ;; esac
}
task_menu() {
  if ! $GUM_OK; then echo "[s]elect [n]ew [e]dit [b]ack"; read -r a; case "$a" in s|S) pick_task ;; n|N) new_task_dialog ;; e|E) [[ -n "$CURRENT_TASK" ]] && edit_file "${TASKS_DIR}/${CURRENT_TASK}.prompt.md" ;; esac; return; fi
  local sel; sel="$(printf "Select…\nNew…\nEdit current…\nBack" | gum choose --header "Task")" || return
  case "$sel" in "Select…") pick_task ;; "New…") new_task_dialog ;; "Edit current…") [[ -n "$CURRENT_TASK" ]] && edit_file "${TASKS_DIR}/${CURRENT_TASK}.prompt.md" || warn "No task";; esac
}
context_menu() {
  if ! $GUM_OK; then echo "[p]roject [t]ask [m]odel [b]ack"; read -r a; case "$a" in p|P) project_menu ;; t|T) task_menu ;; m|M) pick_model_provider; pick_model_name ;; esac; return; fi
  local sel; sel="$(printf "Project…\nTask…\nModel…\nBack" | gum choose --header "Context")" || return
  case "$sel" in "Project…") project_menu ;; "Task…") task_menu ;; "Model…") pick_model_provider; pick_model_name ;; esac
}

# ----------------------------- CHAT LOOP --------------------------------------
render_header() {
  local p="${CURRENT_PROJECT:-—}" t="${CURRENT_TASK:-—}" m="${MODEL_PROVIDER}${MODEL_NAME:+/$MODEL_NAME}"
  printf "[Project:%s] [Task:%s] [Model:%s]\n" "$p" "$t" "$m"
}
help_lines() {
  cat <<'HLP'
Commands:
/estimate  /generate  /tweak  /debug
/project   /task      /context
/preview   /snap      /undo
/settings  /keys      /help   /exit
Tip: just type normally and the Agent will propose actions; you'll confirm before it runs anything.
HLP
}
handle_command() {
  case "$1" in
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

agent_message() {
  # Send free-form message to the agent runner; it decides plan + optional actions
  local text="$1"
  local proj_path task_file
  proj_path=""; [[ -n "$CURRENT_PROJECT" ]] && proj_path="${PROJECTS_DIR}/${CURRENT_PROJECT}"
  task_file=""; [[ -n "$CURRENT_TASK" ]] && task_file="${TASKS_DIR}/${CURRENT_TASK}.prompt.md"

  if ! command -v chat-runner.sh >/dev/null 2>&1; then
    warn "chat-runner.sh not installed; message recorded only."
    echo "[note] Free-form chat recorded. Use /estimate then /generate to act." | tee -a "$CHAT_LOG"
    return
  fi

  local out
  out="$(chat-runner.sh \
        --provider "$MODEL_PROVIDER" \
        --model    "${MODEL_NAME:-$(default_model_for "$MODEL_PROVIDER")}" \
        --message  "$text" \
        --project  "$proj_path" \
        --taskfile "$task_file" \
        2>&1)" || true

  echo "$out" | tee -a "$CHAT_LOG"
}

chat_loop_gum() {
  clear
  msg "AIworkbench — Chat (gum UI). Type /help for commands."
  while true; do
    echo; render_header
    local input; input="$(gum input --placeholder "Message or /command" || true)"
    [[ -z "$input" ]] && continue
    echo "> $input" | tee -a "$CHAT_LOG"
    if [[ "$input" == /* ]]; then handle_command "$input"; continue; fi
    agent_message "$input"
  done
}
chat_loop_cli() {
  msg "AIworkbench — Chat (basic). Type /help for commands."
  while true; do
    echo; render_header; read -rp "> " input || exit 0
    [[ -z "$input" ]] && continue
    echo "> $input" | tee -a "$CHAT_LOG"
    if [[ "$input" == /* ]]; then handle_command "$input"; else agent_message "$input"; fi
  done
}

# ------------------------------- ENTRY ----------------------------------------
# Ensure model name defaulted
[[ -z "$MODEL_NAME" ]] && MODEL_NAME="$(default_model_for "$MODEL_PROVIDER")"
if $GUM_OK; then chat_loop_gum; else chat_loop_cli; fi
