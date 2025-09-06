#!/data/data/com.termux/files/usr/bin/bash
# Normalize every file in ~/bin: CRLF→LF, fix shebang, +x
set -euo pipefail
DST="$HOME/bin"
BASH_PATH="$(command -v bash)"
shopt -s nullglob
for f in "$DST"/*; do
  [ -f "$f" ] || continue
  sed -i 's/\r$//' "$f" || true
  sed -i "1s|^#!.*|#!$BASH_PATH|" "$f" || true
  chmod +x "$f" || true
done
hash -r
echo "✅ fixed: $(ls -1 "$DST" 2>/dev/null | wc -l) files"