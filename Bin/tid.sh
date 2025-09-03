#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
[ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "(no active task)"