#!/data/data/com.termux/files/usr/bin/bash
# Shows current key env; optional --edit opens the env file in nano

set -euo pipefail

ENVFILE="$HOME/.aiwb.env"
[ -f "$ENVFILE" ] || touch "$ENVFILE"

show(){
  echo "🔑 Current (masked):"
  grep -E '^(export )?(GEMINI_API_KEY|ANTHROPIC_API_KEY|GEMINI_MODEL|CLAUDE_MODEL|MAX_OUT_TOKENS_DEFAULT|CONFIRM)=' "$ENVFILE" \
    | sed -E 's/(KEY=).*/\1********/;'
}

case "${1:-}" in
  --edit)
    command -v nano >/dev/null 2>&1 || pkg install -y nano
    nano "$ENVFILE"
    echo "✅ Saved $ENVFILE"
    ;;
  *)
    show
    ;;
esac