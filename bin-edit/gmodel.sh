#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
if [ -n "${1:-}" ]; then
  export GEMINI_MODEL="$1"
  echo "🔁 GEMINI_MODEL=$GEMINI_MODEL"
  grep -q '^export GEMINI_MODEL=' ~/.bashrc && sed -i "s/^export GEMINI_MODEL=.*/export GEMINI_MODEL='$GEMINI_MODEL'/" ~/.bashrc || echo "export GEMINI_MODEL='$GEMINI_MODEL'" >> ~/.bashrc
  source ~/.bashrc
else
  echo "GEMINI_MODEL=${GEMINI_MODEL:-gemini-1.5-flash}"
fi