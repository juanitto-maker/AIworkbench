#!/usr/bin/env bash
# aiwb — Fixed for Local Context
set -uo pipefail

# --- Settings ---
[ -f "$HOME/.aiwb.env" ] && source "$HOME/.aiwb.env"
export WS_ROOT="$(pwd)"
export AIWB_REPO_NAME="$(basename "$WS_ROOT")"

# --- The Brain: This part sends your files to Gemini ---
run_agent() {
  local user_input="$1"
  local model="${AIWB_MODEL:-gemini-1.5-flash}"

  # 1. READ YOUR FILES
  local context=""
  # This finds your .tsx, .ts, .json, and .md files and reads them
  while IFS= read -r file; do
    context+=$'\n'--- "FILE: $file" ---$'\n'
    context+=$(cat "$file" | head -c 10000)
    context+=$'\n'
  done < <(find . -maxdepth 1 -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.json" -o -name "*.md" \))

  # 2. PACK THE DATA
  # We put your files and your question into one package
  local full_prompt="You are an assistant with access to these local files:
$context

User Question: $user_input"

  local json_payload=$(jq -n --arg p "$full_prompt" '{contents: [{parts: [{text: $p}]}]}')

  # 3. TALK TO GEMINI
  local resp=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}" \
    -H "Content-Type: application/json" -d "$json_payload")

  echo -e "\n\033[1;36mAI:\033[0m"
  echo "$resp" | jq -r '.candidates[0].content.parts[0].text'
}

# --- Simple Chat Loop ---
echo "Repository: $AIWB_REPO_NAME (main)"
while true; do
  read -p "> " inp
  [[ "$inp" == "/exit" ]] && exit 0
  run_agent "$inp"
done
