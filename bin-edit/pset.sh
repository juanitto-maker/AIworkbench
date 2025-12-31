#!/usr/bin/env bash
set -eo pipefail
. ~/bin/paths.sh

P="${1:-}"
if [ -z "$P" ]; then
  echo "Usage: pset <projectName>"
  exit 1
fi

PROJ="$PROJ_ROOT/$P"
mkdir -p "$PROJ"/{tasks,temp,drafts,history,run,logs,prompts,outputs}

echo "$P" > "$CURRENT_PROJECT_FILE"

echo "✅ Project selected: $P"
echo "   Folder: $PROJ"