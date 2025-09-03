#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
. ~/bin/paths.sh

P="${1:-$(cat "$CURRENT_PROJECT_FILE" 2>/dev/null || true)}"
[ -n "$P" ] || { echo "Usage: ptasks <project>  (or set with pset)"; exit 1; }
PROJ="$PROJ_ROOT/$P"

echo "Project: $P"
[ -d "$PROJ/temp" ] || { echo "  (no tasks yet)"; exit 0; }

while IFS= read -r f; do
  b="$(basename "$f")"
  t="${b%.prompt.md}"
  echo " - $t"
done < <(find "$PROJ/temp" -maxdepth 1 -type f -name '*.prompt.md' | sort)