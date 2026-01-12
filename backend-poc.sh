#!/usr/bin/env bash
# Proof of Concept: AIWB as headless backend
# Usage: ./backend-poc.sh '{"prompt":"test","provider":"gemini","model":"2.5-flash"}'

set -euo pipefail

# Source core modules (no UI dependencies)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/api.sh"

# Parse JSON input
json_input="${1:-}"
if [[ -z "$json_input" ]]; then
    echo '{"error": "No input provided"}' >&2
    exit 1
fi

# Extract parameters
prompt=$(echo "$json_input" | jq -r '.prompt // empty')
provider=$(echo "$json_input" | jq -r '.provider // "gemini"')
model=$(echo "$json_input" | jq -r '.model // "2.5-flash"')

if [[ -z "$prompt" ]]; then
    echo '{"error": "Missing prompt"}' >&2
    exit 1
fi

# Call API (no UI!)
result=$(call_api "$prompt" "$provider" "$model" 2>&1)
exit_code=$?

# Return JSON response
if [[ $exit_code -eq 0 ]]; then
    echo "{\"result\": $(echo "$result" | jq -Rs .)}" | jq -c
else
    echo "{\"error\": $(echo "$result" | jq -Rs .)}" | jq -c >&2
    exit 1
fi
