#!/usr/bin/env bash
# aiwb — AIworkbench Orchestrator (Termux-Optimized Version)
# - Fixed: Automatic context detection in local directories.
# - Fixed: Silent crashes in Termux by removing 'set -e'.
# - Fixed: JSON payload construction for Gemini API.

set -uo pipefail

# ---------- Helper Functions ----------
have()       { command -v "$1" >/dev/null 2>&1; }
err()        { printf "\033[1;31mEE\033[0m %s\n" "$*" >&2; }
warn()       { printf "\033[1;33m!!\033[0m %s\n" "$*" >&2; }
msg()        { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
is_termux()  { [[ "${PREFIX:-}" == *com.termux* ]] || [[ "${OSTYPE:-}" == "linux-android"* ]]; }

GUM=false; have gum && GUM=true

# ---------- Env / Keys ----------
[ -f "$HOME/.aiwb.env" ] && source "$HOME/.aiwb.env"

# ---------- Workspace Detection ----------
# Always default to the directory where you are standing
export WS_ROOT="$(pwd)"
export AIWB_REPO_ENABLED=true
export AIWB_REPO_NAME="$(basename "$WS_ROOT")"

# Load UI libraries if they exist
LIB_UI="${PREFIX:-$HOME}/bin/lib/ui.sh"
[ ! -f "$LIB_UI" ] && LIB_UI="$HOME/.local/bin/lib/ui.sh"
[ -f "$LIB_UI" ] && source "$LIB_UI"

# ---------- The Main AI Agent Logic ----------
run_agent() {
  local user_input="$1"
  local provider="${AIWB_PROVIDER:-gemini}"
  local model="${AIWB_MODEL:-gemini-1.5-flash}"

  if [[ -z "${GEMINI_API_KEY:-}" ]]; then
    err "No Gemini API key found. Run /keys to add one."
    return 1
  fi

  # 1. Gather Context (Slurp local files)
  msg "Scanning project: $AIWB_REPO_NAME..."
  local context=""
  # Only grab relevant code/text files to stay under token limits
  while IFS= read -r file; do
    if [[ -f "$file" ]]; then
      context+=$'\n'--- "FILE: ${file#$WS_ROOT/}" ---$'\n'
      context+=$(head -c 30000 "$file" 2>/dev/null) # Limit to 30k chars per file to prevent crashes
      context+=$'\n'
    fi
  done < <(find "$WS_ROOT" -maxdepth 2 -not -path '*/.*' -not -path '*node_modules*' -type f \( -name "*.ts*" -o -name "*.js*" -o -name "*.json" -o -name "*.md" -o -name "*.html" -o -name "*.txt" \))

  # 2. Construct the Payload
  local system_instruction="You are a senior developer. Use the provided file context to answer questions about the project."
  local user_content="[LOCAL FILE CONTEXT]:\n$context\n\n[USER QUESTION]:\n$user_input"

  # Use JQ to build safe JSON (prevents 'Mandiant' hallucinations and syntax errors)
  local json_payload
  json_payload=$(jq -n \
    --arg sys "$system_instruction" \
    --arg usr "$user_content" \
    '{
      system_instruction: {parts: [{text: $sys}]},
      contents: [{parts: [{text: $usr}]}]
    }')

  msg "Sending to $model..."
  
  local response
  response=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$json_payload")

  # 3. Handle the Output
  echo -e "\n\033[1;36mAI:\033[0m"
  local ai_text
  ai_text=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text' 2>/dev/null)

  if [[ "$ai_text" == "null" ]] || [[ -z "$ai_text" ]]; then
      err "API Error. Response received:"
      echo "$response" | jq .
  else
      echo "$ai_text"
  fi
}

# ---------- UI & Menus ----------
header() {
    if have ui_show_status; then
        ui_show_status "Termux" "$AIWB_PROVIDER" "$AIWB_MODEL"
    else
        echo "--- AIWB: $AIWB_REPO_NAME ---"
    fi
}

help_text() {
  cat <<EOF
Slash Commands:
  /help      Show this help
  /keys      Configure API keys
  /settings  Change provider/model
  /debug     Print current context info
  /exit      Quit
EOF
}

keys_menu() {
  echo "Enter your Gemini API Key:"
  read -r key
  echo "export GEMINI_API_KEY='$key'" > "$HOME/.aiwb.env"
  echo "export AIWB_PROVIDER='gemini'" >> "$HOME/.aiwb.env"
  msg "Key saved to ~/.aiwb.env"
  source "$HOME/.aiwb.env"
}

# ---------- Chat Loops ----------
chat_loop_gum() {
  clear
  msg "AIworkbench — Context: $AIWB_REPO_NAME"
  while true; do
    header
    local inp; inp="$(gum input --placeholder "Ask about your code or /exit" || true)"
    [[ -z "$inp" ]] && continue
    case "$inp" in
      /help)     help_text ;;
      /keys)     keys_menu ;;
      /exit)     exit 0 ;;
      *)         run_agent "$inp" ;;
    esac
  done
}

chat_loop_cli() {
  msg "AIworkbench (CLI Mode) — Context: $AIWB_REPO_NAME"
  while true; do
    header
    read -p "> " inp
    [[ -z "$inp" ]] && continue
    case "$inp" in
      /help)     help_text ;;
      /keys)     keys_menu ;;
      /exit)     exit 0 ;;
      *)         run_agent "$inp" ;;
    esac
  done
}

# ---------- Startup ----------
if $GUM; then
  chat_loop_gum
else
  chat_loop_cli
fi
