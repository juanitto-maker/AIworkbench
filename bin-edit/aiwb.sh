#!/usr/bin/env bash
# aiwb — AIworkbench Orchestrator (Termux-Optimized Version)
set -uo pipefail

# --- Core Helpers ---
have()       { command -v "$1" >/dev/null 2>&1; }
msg()        { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
err()        { printf "\033[1;31mEE\033[0m %s\n" "$*" >&2; }

# --- Load Environment ---
[ -f "$HOME/.aiwb.env" ] && source "$HOME/.aiwb.env"

# --- FIXED: Dynamic Workspace Detection ---
# This ensures it ALWAYS sees the folder you are currently in
export WS_ROOT="$(pwd)"
export AIWB_REPO_NAME="$(basename "$WS_ROOT")"

run_agent() {
  local user_input="$1"
  local model="${AIWB_MODEL:-gemini-1.5-flash}"

  if [[ -z "${GEMINI_API_KEY:-}" ]]; then
    err "API Key missing. Use /keys to set it."
    return 1
  fi

  # 1. GATHER CONTEXT (The Termux 'Slurp')
  msg "Analyzing files in: $WS_ROOT"
  local context=""
  # Scans current folder for code files, ignoring hidden/large ones
  while IFS= read -r file; do
    if [[ -f "$file" ]]; then
      context+=$'\n'--- "FILE: ${file#$WS_ROOT/}" ---$'\n'
      context+=$(head -c 25000 "$file" 2>/dev/null)
      context+=$'\n'
    fi
  done < <(find "$WS_ROOT" -maxdepth 2 -not -path '*/.*' -not -path '*node_modules*' -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.js" -o -name "*.json" -o -name "*.md" \))

  # 2. BUNDLE PAYLOAD (The JSON Bridge)
  # We use jq to perfectly escape your code so the AI can read it
  local system_prompt="You are a senior developer. Use the provided context to answer."
  local user_content="Project Context:\n$context\n\nUser Question: $user_input"
  
  local json_payload
  json_payload=$(jq -n --arg sys "$system_prompt" --arg usr "$user_content" \
    '{system_instruction: {parts: [{text: $sys}]}, contents: [{parts: [{text: $usr}]}]}')

  # 3. SEND & RECEIVE
  msg "Connecting to Gemini..."
  local response
  response=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}" \
    -H "Content-Type: application/json" -d "$json_payload")

  echo -e "\n\033[1;36mAI:\033[0m"
  echo "$response" | jq -r '.candidates[0].content.parts[0].text' 2>/dev/null || err "AI was unable to process context."
}

# --- Simple Chat Loop ---
chat_loop() {
  msg "AIworkbench Ready (Context: $AIWB_REPO_NAME)"
  while true; do
    read -p "> " inp
    [[ -z "$inp" ]] && continue
    case "$inp" in
      /exit) exit 0 ;;
      /keys) 
        read -p "Enter Gemini Key: " k
        echo "export GEMINI_API_KEY='$k'" > "$HOME/.aiwb.env"
        source "$HOME/.aiwb.env" ;;
      *) run_agent "$inp" ;;
    esac
  done
}

chat_loop
