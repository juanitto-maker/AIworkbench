#!/usr/bin/env bash
# aiwb — AIworkbench Orchestrator (chat-first TUI)
# - Default interaction is chat. No project/task required.
# - Workspace defaults to ~/storage/shared/aiwb if available (Android-visible),
#   otherwise ~/.aiwb/workspace.
# - Keys are read from ~/.aiwb.env (created via /keys).
# - Auto-fixes CRLF in installed tools on startup.
# - Smart context loading: selective by default, /fullcontext for deep scan
# - Universal: works with any repo, any model provider
# - Slash commands: /help /keys /settings /estimate /generate /debug /fullcontext /exit

set -o pipefail

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

MODEL_PROVIDER="${MODEL_PROVIDER:-gemini}"     # gemini|claude|openai|ollama|custom
MODEL_NAME="${MODEL_NAME:-}"                   # filled from default if empty
CURRENT_TASK="${CURRENT_TASK:-}"               # optional
CHAT_LOG="$LOGS_DIR/chat_$(date +%Y%m%d_%H%M%S).log"
CONTEXT_MODE="${CONTEXT_MODE:-selective}"      # selective|full

default_model_for() {
  case "$1" in
    gemini) echo "gemini-2.0-flash-exp" ;;
    claude) echo "claude-sonnet-4-20250514" ;;
    openai) echo "gpt-4" ;;
    ollama) echo "llama2" ;;
    *) echo "" ;;
  esac
}

save_session() {
  cat >"$SESSION_FILE" <<JSON
{"workspace":"$WS_ROOT","model_provider":"$MODEL_PROVIDER","model_name":"${MODEL_NAME:-}","task":"$CURRENT_TASK","context_mode":"$CONTEXT_MODE"}
JSON
}
load_session() {
  [[ -f "$SESSION_FILE" ]] || return 0
  WS_ROOT="$(jq -r '.workspace // empty' "$SESSION_FILE" 2>/dev/null || echo "$WS_ROOT")"
  MODEL_PROVIDER="$(jq -r '.model_provider // empty' "$SESSION_FILE" 2>/dev/null || echo "$MODEL_PROVIDER")"
  MODEL_NAME="$(jq -r '.model_name // empty' "$SESSION_FILE" 2>/dev/null || echo "")"
  CURRENT_TASK="$(jq -r '.task // empty' "$SESSION_FILE" 2>/dev/null || echo "")"
  CONTEXT_MODE="$(jq -r '.context_mode // empty' "$SESSION_FILE" 2>/dev/null || echo "selective")"
}
have jq && load_session || true
[[ -z "$MODEL_NAME" ]] && MODEL_NAME="$(default_model_for "$MODEL_PROVIDER")"

# ---------- universal context builder ----------
# Builds repo context intelligently based on mode

build_context() {
  local mode="${1:-selective}"
  local context=""
  local file_count=0
  local max_file_size=50000  # chars per file limit
  
  msg "Building $mode context for $(basename "$(pwd)")..."
  
  # Common exclusions (universal across all repo types)
  local exclude_dirs=(
    ".git"
    "node_modules"
    "dist"
    "build"
    "__pycache__"
    ".next"
    ".nuxt"
    "vendor"
    "target"
    "out"
    "bin"
    ".venv"
    "venv"
    "env"
  )
  
  # Build find exclusions
  local find_exclude=""
  for dir in "${exclude_dirs[@]}"; do
    find_exclude+=" -not -path '*/$dir/*'"
  done
  
  if [[ "$mode" == "full" ]]; then
    # Full context: read most files (with size limits)
    msg "Deep scan: reading all source files..."
    
    # Find source files (common extensions across languages)
    eval "find . -type f \
      $find_exclude \
      \( -name '*.js' -o -name '*.ts' -o -name '*.jsx' -o -name '*.tsx' \
      -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.java' \
      -o -name '*.c' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \
      -o -name '*.rb' -o -name '*.php' -o -name '*.swift' -o -name '*.kt' \
      -o -name '*.json' -o -name '*.yaml' -o -name '*.yml' -o -name '*.toml' \
      -o -name '*.md' -o -name '*.txt' -o -name '*.sh' -o -name '*.bash' \
      -o -name 'Makefile' -o -name 'Dockerfile' -o -name '.env*' \
      \) 2>/dev/null" | while IFS= read -r file; do
      
      # Skip binary files
      if file "$file" 2>/dev/null | grep -q "text"; then
        local content
        content=$(head -c "$max_file_size" "$file" 2>/dev/null || true)
        if [[ -n "$content" ]]; then
          context+=$'\n'"--- FILE: $file ---"$'\n'
          context+="$content"$'\n'
          ((file_count++))
        fi
      fi
    done
    
  else
    # Selective context: only key files (default mode)
    msg "Smart scan: reading key files..."
    
    # Priority 1: Config files (always important)
    local config_patterns=(
      "package.json"
      "tsconfig.json"
      "*.config.js"
      "*.config.ts"
      "Cargo.toml"
      "go.mod"
      "requirements.txt"
      "Gemfile"
      "composer.json"
      "pom.xml"
      "build.gradle"
      ".env.example"
    )
    
    for pattern in "${config_patterns[@]}"; do
      eval "find . -maxdepth 2 -type f -name '$pattern' $find_exclude 2>/dev/null" | while IFS= read -r file; do
        local content
        content=$(head -c "$max_file_size" "$file" 2>/dev/null || true)
        if [[ -n "$content" ]]; then
          context+=$'\n'"--- FILE: $file ---"$'\n'
          context+="$content"$'\n'
          ((file_count++))
        fi
      done
    done
    
    # Priority 2: Documentation
    eval "find . -maxdepth 2 -type f \( -name 'README*' -o -name 'CHANGELOG*' -o -name 'LICENSE*' \) $find_exclude 2>/dev/null" | while IFS= read -r file; do
      local content
      content=$(head -c "$max_file_size" "$file" 2>/dev/null || true)
      if [[ -n "$content" ]]; then
        context+=$'\n'"--- FILE: $file ---"$'\n'
        context+="$content"$'\n'
        ((file_count++))
      fi
    done
    
    # Priority 3: Main source files (limited depth)
    eval "find . -maxdepth 3 -type f \
      $find_exclude \
      \( -name 'main.*' -o -name 'index.*' -o -name 'app.*' -o -name 'server.*' \
      -o -name '__init__.py' -o -name 'mod.rs' \) 2>/dev/null" | while IFS= read -r file; do
      
      if file "$file" 2>/dev/null | grep -q "text"; then
        local content
        content=$(head -c "$max_file_size" "$file" 2>/dev/null || true)
        if [[ -n "$content" ]]; then
          context+=$'\n'"--- FILE: $file ---"$'\n'
          context+="$content"$'\n'
          ((file_count++))
        fi
      fi
    done
  fi
  
  msg "Context built: $file_count files"
  echo "$context"
}

# ---------- keys UI ----------
set_key() {
  local name="$1" current="${!1:-}" val
  if $GUM; then
    val="$(gum input --password --placeholder "$name value" --value "$current")" || return 1
  else
    read -rsp "Enter $name: " val; echo
  fi
  [[ -z "$val" ]] && { warn "$name unchanged"; return 0; }
  
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
  local g="${GEMINI_API_KEY:+✅}" a="${ANTHROPIC_API_KEY:+✅}" o="${OPENAI_API_KEY:+✅}"
  
  if $GUM; then
    while true; do
      local choice
      choice="$(printf "Set GEMINI_API_KEY %s\nSet ANTHROPIC_API_KEY %s\nSet OPENAI_API_KEY %s\nBack" "$g" "$a" "$o" | gum choose --header "API Keys")" || return
      case "$choice" in
        "Set GEMINI_API_KEY "*) set_key GEMINI_API_KEY ;;
        "Set ANTHROPIC_API_KEY "*) set_key ANTHROPIC_API_KEY ;;
        "Set OPENAI_API_KEY "*) set_key OPENAI_API_KEY ;;
        Back) return ;;
      esac
    done
  else
    echo "1) Set GEMINI_API_KEY $g"
    echo "2) Set ANTHROPIC_API_KEY $a"
    echo "3) Set OPENAI_API_KEY $o"
    echo "4) Back"
    read -rp "> " ans
    case "$ans" in
      1) set_key GEMINI_API_KEY ;;
      2) set_key ANTHROPIC_API_KEY ;;
      3) set_key OPENAI_API_KEY ;;
      *) ;;
    esac
  fi
}

# ---------- header/help ----------
header() {
  local vis="(internal)"
  [[ "$WS_ROOT" == "$HOME/storage/shared/"* ]] && vis="(Android-visible)"
  printf "[Workspace:%s %s] [Task:%s] [Model:%s/%s] [Context:%s]\n" \
    "$WS_ROOT" "$vis" "${CURRENT_TASK:-—}" "$MODEL_PROVIDER" "${MODEL_NAME:-default}" "$CONTEXT_MODE"
}

help_text() {
  cat <<'HLP'
Commands:
/help         show this help
/keys         set or update API keys (saved to ~/.aiwb.env)
/settings     change provider/model
/fullcontext  deep scan entire repo (use once when entering new repo)
/selective    switch back to smart selective context mode (default)
/estimate     ask agent to estimate current (or inbox) task
/generate     ask agent to generate/apply changes
/debug        ask agent to run debug flow
/exit         quit

Context Modes:
  selective   (default) reads only key files - fast, token-efficient
  full        reads entire repo - use once for initial understanding

Tip: Start new repo with /fullcontext, then switch to normal chat.
     The agent will propose plans and ask to confirm.
HLP
}

# ---------- settings ----------
settings_menu() {
  if $GUM; then
    local choice
    choice="$(printf "Provider: %s\nModel: %s\nContext: %s\nBack" "$MODEL_PROVIDER" "${MODEL_NAME:-default}" "$CONTEXT_MODE" | gum choose --header "Settings")" || return
    case "$choice" in
      Provider:*) 
        choice="$(printf "gemini\nclaude\nopenai\nollama\ncustom" | gum choose --header "Choose provider")" || return
        MODEL_PROVIDER="$choice"
        MODEL_NAME="$(default_model_for "$MODEL_PROVIDER")"
        ;;
      Model:*)
        case "$MODEL_PROVIDER" in
          gemini)
            choice="$(printf "gemini-2.0-flash-exp\ngemini-1.5-pro\ngemini-1.5-flash" | gum choose --header "Choose Gemini model")" || return
            ;;
          claude)
            choice="$(printf "claude-sonnet-4-20250514\nclaude-opus-4-20250514\nclaude-haiku-3.5" | gum choose --header "Choose Claude model")" || return
            ;;
          openai)
            choice="$(printf "gpt-4\ngpt-4-turbo\ngpt-3.5-turbo" | gum choose --header "Choose OpenAI model")" || return
            ;;
          *)
            read -rp "Enter model name: " choice
            ;;
        esac
        MODEL_NAME="$choice"
        ;;
      Context:*)
        choice="$(printf "selective\nfull" | gum choose --header "Choose context mode")" || return
        CONTEXT_MODE="$choice"
        ;;
      Back) ;;
    esac
  else
    echo "Provider: $MODEL_PROVIDER | Model: $MODEL_NAME | Context: $CONTEXT_MODE"
    echo "1) Change provider  2) Change model  3) Change context mode  4) Back"
    read -rp "> " ans
    case "$ans" in
      1)
        echo "1) gemini  2) claude  3) openai  4) ollama  5) custom"
        read -rp "> " p
        case "$p" in
          1) MODEL_PROVIDER=gemini ;;
          2) MODEL_PROVIDER=claude ;;
          3) MODEL_PROVIDER=openai ;;
          4) MODEL_PROVIDER=ollama ;;
          5) read -rp "Provider name: " MODEL_PROVIDER ;;
        esac
        MODEL_NAME="$(default_model_for "$MODEL_PROVIDER")"
        ;;
      2)
        read -rp "Model name: " MODEL_NAME
        ;;
      3)
        echo "1) selective  2) full"
        read -rp "> " c
        case "$c" in
          1) CONTEXT_MODE=selective ;;
          2) CONTEXT_MODE=full ;;
        esac
        ;;
      *) ;;
    esac
  fi
  save_session
}

# ---------- agent call ----------
run_agent() {
  local msgtxt="$1"
  local use_context="${2:-true}"
  
  # Build context if enabled
  local context=""
  if [[ "$use_context" == "true" ]]; then
    context=$(build_context "$CONTEXT_MODE")
  fi
  
  # Build full prompt with context
  local full_prompt
  if [[ -n "$context" ]]; then
    full_prompt="Repository: $(basename "$(pwd)")

Context from local files:
$context

User message: $msgtxt"
  else
    full_prompt="$msgtxt"
  fi
  
  local args=(
    --provider "$MODEL_PROVIDER"
    --model "${MODEL_NAME:-}"
    --message "$full_prompt"
    --workspace "$WS_ROOT"
  )
  
  # If a task is selected, pass it
  if [[ -n "${CURRENT_TASK:-}" ]]; then
    args+=( --taskfile "$TASKS_DIR/${CURRENT_TASK}.prompt.md" )
  fi
  
  if ! command -v chat-runner.sh >/dev/null 2>&1; then
    warn "chat-runner.sh not installed (run binpush)."
    echo "[note] Context built. Free-form chat recorded. Use /keys then /estimate or /generate." | tee -a "$CHAT_LOG"
    return
  fi
  
  chat-runner.sh "${args[@]}" | tee -a "$CHAT_LOG"
}

# ---------- actions ----------
estimate_action() { run_agent "estimate"; }
generate_action() { run_agent "generate"; }
debug_action()    { run_agent "debug"; }

fullcontext_action() {
  CONTEXT_MODE="full"
  save_session
  msg "Switched to FULL context mode"
  msg "This will read the entire repo - use for initial understanding"
  run_agent "Analyze this repository structure and give me a comprehensive overview of what this project does, its architecture, and key components."
}

selective_action() {
  CONTEXT_MODE="selective"
  save_session
  msg "Switched to SELECTIVE context mode (default)"
  msg "This reads only key files - efficient for ongoing work"
}

# ---------- chat loops ----------
chat_loop_gum() {
  clear
  msg "AIworkbench — Chat (gum UI). Type /help for commands."
  echo "Workspace: $WS_ROOT"
  echo "Repository: $(basename "$(pwd)")"
  while true; do
    echo; header
    local inp; inp="$(gum input --placeholder "Message or /command" || true)"
    [[ -z "$inp" ]] && continue
    echo "> $inp" | tee -a "$CHAT_LOG"
    case "$inp" in
      /help)         help_text ;;
      /keys)         keys_menu ;;
      /settings)     settings_menu ;;
      /fullcontext)  fullcontext_action ;;
      /selective)    selective_action ;;
      /estimate)     estimate_action ;;
      /generate)     generate_action ;;
      /debug)        debug_action ;;
      /exit)         exit 0 ;;
      *)             run_agent "$inp" ;;
    esac
  done
}

chat_loop_cli() {
  msg "AIworkbench — Chat (basic). Type /help for commands."
  echo "Workspace: $WS_ROOT"
  echo "Repository: $(basename "$(pwd)")"
  while true; do
    echo; header
    read -rp "> " inp || exit 0
    [[ -z "$inp" ]] && continue
    echo "> $inp" | tee -a "$CHAT_LOG"
    case "$inp" in
      /help)         help_text ;;
      /keys)         keys_menu ;;
      /settings)     settings_menu ;;
      /fullcontext)  fullcontext_action ;;
      /selective)    selective_action ;;
      /estimate)     estimate_action ;;
      /generate)     generate_action ;;
      /debug)        debug_action ;;
      /exit)         exit 0 ;;
      *)             run_agent "$inp" ;;
    esac
  done
}

# ---------- entry ----------
save_session
if $GUM; then chat_loop_gum; else chat_loop_cli; fi
