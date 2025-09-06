#!/data/data/com.termux/files/usr/bin/bash
# Pick a file with Android file picker and copy into $AIWB/uploads

set -euo pipefail

AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
UP="$AIWB/uploads"
mkdir -p "$UP"

# Requires: termux-api
type termux-storage-get >/dev/null 2>&1 || {
  echo "❌ termux-api not installed. Run: pkg install -y termux-api" >&2; exit 1; }

TMP="$(mktemp)"
if ! termux-storage-get "$TMP"; then
  echo "Cancelled."; exit 1
fi

SRC="$(cat "$TMP")"
rm -f "$TMP"

[ -f "$SRC" ] || { echo "❌ No file selected."; exit 1; }

base="$(basename "$SRC")"
dest="$UP/$base"
cp -f "$SRC" "$dest"

echo "✅ Copied → $dest"
termux-toast "Uploaded: $base"