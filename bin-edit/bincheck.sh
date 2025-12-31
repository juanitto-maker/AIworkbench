#!/usr/bin/env bash
# Audit ~/bin for common breakages
set -eo pipefail
DST="$HOME/bin"
BASH_PATH="$(command -v bash)"
echo "🔎 Auditing $DST"
found=0
shopt -s nullglob
for f in "$DST"/*; do
  [ -f "$f" ] || continue
  bad=0
  if ! head -n1 "$f" | grep -qx "#!$BASH_PATH"; then
    echo "  ⚠ bad shebang : $(basename "$f")"
    bad=1
  fi
  if LC_ALL=C grep -q $'\r' "$f"; then
    echo "  ⚠ CRLF found  : $(basename "$f")"
    bad=1
  fi
  if [ ! -x "$f" ]; then
    echo "  ⚠ not +x      : $(basename "$f")"
    bad=1
  fi
  [ $bad -eq 1 ] && found=1
done
[ $found -eq 0 ] && echo "✅ All clean."