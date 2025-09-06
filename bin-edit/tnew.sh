#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
. ~/bin/paths.sh

# require a current project
if [ ! -s "$CURRENT_PROJECT_FILE" ]; then
  echo "No active project. Use: pset <projectName>"
  exit 1
fi
P="$(cat "$CURRENT_PROJECT_FILE")"
PROJ="$PROJ_ROOT/$P"

# TID argument or auto next (t0001, t0002, …)
T="${1:-}"
if [ -z "$T" ]; then
  last=$(ls -1 "$PROJ/tasks" 2>/dev/null | sed -n 's/^t\([0-9][0-9]*\)\.md$/\1/p' | sort -n | tail -1 || true)
  next=$(( ${last:-0} + 1 ))
  T=$(printf "t%04d" "$next")
fi

mkdir -p "$PROJ"/{tasks,temp,drafts,history,run,logs,prompts,outputs}

# Create skeletons if missing
[ -f "$PROJ/tasks/$T.md" ] || printf "# %s\n\n" "$T" > "$PROJ/tasks/$T.md"
[ -f "$PROJ/temp/$T.prompt.md" ] || : > "$PROJ/temp/$T.prompt.md"
echo "NEW" > "$PROJ/temp/$T.status.txt"

# Mark current task
echo "$T" > "$CURRENT_TASK_FILE"

echo "✅ Task $T created & selected."
echo "   - Prompt: $PROJ/temp/$T.prompt.md"