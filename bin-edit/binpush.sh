#!/data/data/com.termux/files/usr/bin/bash
# binpush.sh — install sanitized scripts from bin-edit/ to ~/.local/bin
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_DIR="${HOME}/.local/bin"
SHEBANG="/data/data/com.termux/files/usr/bin/bash"
VERBOSE=0
DRYRUN=0

log(){ printf "%s\n" "$*" ; }
vlog(){ [ "$VERBOSE" -eq 1 ] && printf "%s\n" "$*" || true ; }
die(){ printf " %s\n" "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --verbose|-v) VERBOSE=1;;
    --dry-run) DRYRUN=1;;
    --dest) shift; DEST_DIR="${1:-$DEST_DIR}";;
    --help|-h)
      cat <<HLP
Usage: bash bin-edit/binpush.sh [--verbose] [--dry-run] [--dest PATH]
Copies *.sh from bin-edit/ to ~/.local/bin, normalizing CRLF and shebang.
HLP
      exit 0;;
    *) die "Unknown arg: $1";;
  esac; shift
done

mkdir -p "$DEST_DIR"

sanitize_file(){
  local f="$1"
  # strip CRLF
  tr -d '\r' <"$f" >/tmp/.bp.$$ && cat /tmp/.bp.$$ >"$f" && rm -f /tmp/.bp.$$
  # force Termux bash shebang
  sed -i '1s|^#!.*|'"#!${SHEBANG}"'|' "$f"
  chmod 0755 "$f"
}

copy_file(){
  local src="$1" base dst
  base="$(basename "$src")"
  dst="${DEST_DIR}/${base}"
  if [ "$DRYRUN" -eq 1 ]; then
    vlog "DRYRUN sanitize: $src"
    vlog "DRYRUN copy    : $src -> $dst"
  else
    sanitize_file "$src"
    cp -f "$src" "$dst"
    vlog "Installed: $dst"
  fi
}

log "  Installing scripts from: $SRC_DIR    $DEST_DIR"
count=0
shopt -s nullglob
for f in "$SRC_DIR"/*.sh; do
  # skip this script’s temporary copies if any
  [ -f "$f" ] || continue
  copy_file "$f"
  count=$((count+1))
done
shopt -u nullglob

log " Done. Files processed: $count"
log
log "Sanity:"
for name in gpre.sh cpre.sh ggo.sh cgo.sh; do
  if command -v "$name" >/dev/null 2>&1; then
    path="$(command -v "$name")"
    printf "  • %-8s  %s\n" "$name" "$path"
  fi
done

# show which will run first
type -a gpre.sh 2>/dev/null || true
type -a cpre.sh 2>/dev/null || true