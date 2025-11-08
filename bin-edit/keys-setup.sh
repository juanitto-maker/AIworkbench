#!/usr/bin/env bash
# Creates ~/.aiwb.env if missing and ensures it's sourced by ~/.bashrc

set -euo pipefail
ENVFILE="$HOME/.aiwb.env"
BASHRC="$HOME/.bashrc"

if [ ! -f "$ENVFILE" ]; then
cat > "$ENVFILE" <<'EOF'
# --- AI Workbench keys & defaults ---
# export GEMINI_API_KEY=""
# export ANTHROPIC_API_KEY=""
export GEMINI_MODEL="gemini-1.5-flash"
export CLAUDE_MODEL="claude-3-5-sonnet-latest"
export MAX_OUT_TOKENS_DEFAULT=16000
export CONFIRM=1
# AI workbench repo
export AIWB="$HOME/.aiwb/workspace"
EOF
echo "✅ Wrote template $ENVFILE"
fi

grep -qF 'source ~/.aiwb.env' "$BASHRC" 2>/dev/null || {
  echo 'source ~/.aiwb.env' >> "$BASHRC"
  echo "✅ Added 'source ~/.aiwb.env' to $BASHRC"
}

# shellcheck disable=SC1090
source "$ENVFILE" || true
echo "🔁 Reloaded env."

echo "🔐 Appending current env vars to ~/.bashrc..."

echo "export GEMINI_API_KEY=\"$GEMINI_API_KEY\"" >> ~/.bashrc
echo "export ANTHROPIC_API_KEY=\"$ANTHROPIC_API_KEY\"" >> ~/.bashrc
echo "export GEMINI_MODEL=\"$GEMINI_MODEL\"" >> ~/.bashrc
echo "export CLAUDE_MODEL=\"$CLAUDE_MODEL\"" >> ~/.bashrc
echo "export MAX_OUT_TOKENS_DEFAULT=$MAX_OUT_TOKENS_DEFAULT" >> ~/.bashrc
echo "export CONFIRM=$CONFIRM" >> ~/.bashrc

echo "✅ Done. Run: source ~/.bashrc"