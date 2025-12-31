#!/usr/bin/env bash
set -o pipefail
AIWB="${AIWB:-$HOME/.aiwb/workspace}"
T="${1:-$( [ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "" )}"
[ -n "$T" ] || { echo "No active task."; exit 1; }

./gpre.sh "$T" || exit 1
if [ "${CONFIRM:-1}" = "1" ]; then
  read -rp "Proceed? [y/N] " y; case "${y,,}" in y|yes) : ;; *) echo "Canceled."; exit 0;; esac
fi
gemini-runner.sh "$T"