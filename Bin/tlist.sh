#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
. ~/bin/paths.sh

[ -s "$CURRENT_PROJECT_FILE" ] || { echo "No active project. Use: pset <name>"; exit 1; }
P="$(cat "$CURRENT_PROJECT_FILE")"
PROJ="$PROJ_ROOT/$P"

echo "Project: $P"
[ -d "$PROJ/temp" ] || { echo "  (no tasks yet)"; exit 0; }

# list any *.prompt.md under temp/
found=0
while IFS= read -r f; do
  b="$(basename "$f")"
  t="${b%.prompt.md}"
  echo " - $t"
  found=1
done < <(find "$PROJ/temp" -maxdepth 1 -type f -name '*.prompt.md' | sort)

[ "$found" -eq 1 ] || echo "  (no tasks yet)"