#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"

T="${1:-$( [ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "" )}"
[ -z "$T" ] && { echo "❌ No active task."; exit 1; }

cpre.sh "$T" || exit 1

if [ "${CONFIRM:-1}" = "1" ]; then
  read -rp "Run Claude for $T? [y/N] " Y
  case "${Y,,}" in y|yes) : ;; *) echo "❌ Canceled."; exit 0;; esac
fi

claude-runner.sh "$T"