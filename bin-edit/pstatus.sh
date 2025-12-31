#!/usr/bin/env bash
set -eo pipefail
. ~/bin/paths.sh

P="$( [ -f "$CURRENT_PROJECT_FILE" ] && cat "$CURRENT_PROJECT_FILE" || echo "(none)" )"
T="$( [ -f "$CURRENT_TASK_FILE" ] && cat "$CURRENT_TASK_FILE" || echo "(none)" )"

echo "📁 Project: $P"
if [ "$P" != "(none)" ]; then
  echo "    Path: $PROJ_ROOT/$P"
fi
echo "🧩 Task:    $T"