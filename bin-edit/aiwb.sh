#!/usr/bin/env bash
# aiwb — Fixed for Full Context Visibility
set -uo pipefail

# Helper functions
msg() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
err() { printf "\033[1;31mEE\033[0m %s\n" "$*" >&2; }

# Load keys
[ -f "$HOME/.aiwb.env" ] && source "$HOME/.aiwb.env"

# Force current directory as workspace
export WS_ROOT="$(pwd)"
export AIWB_REPO_NAME="$(basename "$WS_ROOT")"

run_agent() {
  local user_input="$1"
  local model="${AIWB_MODEL:-gemini-1.5-flash}"

  # 1. GATHER CONTEXT (The Slurp)
  msg "Reading files in $AIWB_REPO_NAME..."
  local context_data=""
  # Focus only on code and text to avoid bloating
  while IFS= read -r file; do
    if [[ -f "$file" ]]; then
      context_data+=$'\n'--- "FILE: ${file#$WS_ROOT/}" ---$'\n'
      context_data+=$(head -c 20000 "$file" 2>/dev/null) # Safety limit
      context_data+=$'\n'
    fi
  done < <(find "$WS_ROOT" -maxdepth 2 -not -path '*/.*' -not -path '*node_modules*' -type f \( -name "*.ts*" -o -name "*.js*" -o -name "*.json" -o -name "*.md" -o -name "*.html" \))

  # 2. BUNDLE INTO JSON (The Bridge)
  # This is the most important part. It uses jq to make the context "visible" to the API.
  local json_payload
  json_payload=$(jq -n \
    --arg ctx "Use this project context to answer: $context_data" \
    --arg q "$user_input" \
    '{contents: [{parts: [{text: ($ctx + "\n\nQuestion: " + $q)}]}]}')

  # 3. SEND TO AI
  msg "Sending to Gemini..."
  local response
  response=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$json_payload")

  # 4. SHOW OUTPUT
  echo -e "\n\033[1;36mAI:\033[0m"
  echo "$response" | jq -r '.candidates[0].content.parts[0].text' 2>/dev/null || err "API Error: No response."
}

# Simple Loop
while true; do
  echo -e "\n\033[1;33m[Context: $AIWB_REPO_NAME]\033[0m"
  read -p "> " inp
  [[ "$inp" == "/exit" ]] && exit 0
  run_agent "$inp"
done
