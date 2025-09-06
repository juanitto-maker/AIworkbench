#!/usr/bin/env bash
# binpush.sh — install sanitized scripts from bin-edit/ to ~/.local/bin
# Supports: --all and specific files, CRLF fix, host shebang rewrite
set -euo pipefail

# --- config ---
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_DIR="${HOME}/.local/bin"
TERMUX_BASH="/data/data/com.termux/files/usr/bin/bash"

VERBOSE=0
DRYRUN=0
ARGS=()

log(){ printf "%s\n" "$*"; }
vlog(){ [ "$VERBOSE" -eq 1 ] && printf "%s\n" "$*" || true; }
die(){ printf " %s\n" "$*\n" >&2; exit 1; }

host_shebang(){
  if command -v termux-info >/dev/null 2>&1 && [ -x "$TERMUX_BASH" ]; then
    printf '%s\n' "$TERMUX_BASH"
  else
    printf '%s\n' "/usr/bin/env bash"
  fi
}

usage(){
  cat <<HLP
Usage:
  bash bin-edit/binpush.sh [--verbose] [--dry-run] [--dest PATH] [--all] [FILES...]

Examples:
  bash bin-edit/binpush.sh --all
  bash bin-edit/binpush.sh aiwb.sh gpre.sh cpre.sh
Notes:
  • Normalizes CRLF to LF (repo stays portable)
  • Rewrites the INSTALLED shebang to match the host (Termux/Linux/macOS)
  • Installs to ~/.local/bin
HLP
}

while [ $# -gt 0 ]; do
  case "$1" in
    --verbose|-v) VERBOSE=1;;
    --dry-run) DRYRUN=1;;
    --dest) shift; DEST_DIR="${1:-$DEST_DIR}";;
    --all) ARGS+=( "$SRC_DIR"/*.sh );;
    --help|-h) usage; exit 0;;
    -* ) die "Unknown arg: $1";;
     * ) ARGS+=( "$1" );;
  esac
  shift
done

[ ${#ARGS[@]} -eq 0 ] && { usage; exit 1; }

mkdir -p "$DEST_DIR"

normalize_inplace(){
  # strip CR at EOL (if any)
  sed -i 's/\r$//' "$1"
}

rewrite_shebang(){
  local f="$1" sb="$2"
  sed -i "1s|^#!.*|#!${sb}|" "$f"
  chmod 0755 "$f"
}

copy_one(){
  local src="$1" base dst
  # allow "aiwb.sh" or absolute path
  [[ "$src" != /* ]] && src="${SRC_DIR}/${src}"
  [ -f "$src" ] || { vlog "Skip (not a file): $src"; return 0; }
  base="$(basename "$src")"
  dst="${DEST_DIR}/${base}"

  # avoid copying onto itself
  if [ -e "$dst" ] && [ "$(realpath -e "$dst")" = "$(realpath -e "$src")" ]; then
    vlog "Skip (same file): $src"
    return 0
  fi

  if [ "$DRYRUN" -eq 1 ]; then
    vlog "DRYRUN install $src -> $dst"
    return 0
  fi

  # work on a temp copy; do NOT mutate repo files
  local tmp
  tmp="$(mktemp --tmpdir="${TMPDIR:-/data/data/com.termux/files/usr/tmp}" binpush.XXXXXX 2>/dev/null || mktemp)"
  cp -f "$src" "$tmp"
  normalize_inplace "$tmp"
  rewrite_shebang "$tmp" "$(host_shebang)"
  install -m 0755 "$tmp" "$dst"
  rm -f "$tmp"
  vlog "Installed: $dst"

  # also create extensionless alias if name ends with .sh (aiwb.sh -> aiwb)
  if [[ "$base" == *.sh ]]; then
    local alias="${DEST_DIR}/${base%.sh}"
    cp -f "$dst" "$alias"
    chmod 0755 "$alias"
    vlog "Alias: $alias"
  fi
}

log " Installing from: $SRC_DIR    $DEST_DIR"
count=0
for f in "${ARGS[@]}"; do
  copy_one "$f" && count=$((count+1))
done
log " Done. Files processed: $count"
log
log "Sanity:"
for name in aiwb gpre.sh cpre.sh ggo.sh cgo.sh binpush.sh; do
  if command -v "$name" >/dev/null 2>&1; then
    printf "  • %-9s %s\n" "$name" "$(command -v "$name")"
  fi
done