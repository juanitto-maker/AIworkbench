#!/data/data/com.termux/files/usr/bin/bash
# binpush.sh — Smart, self-sanitizing push from bin-edit/  bin/
# Now: verbose per-file logging is ON by default.

set -euo pipefail

AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
SRC_DIR="${SRC_DIR:-$AIWB/bin-edit}"
DST_DIR="${DST_DIR:-$AIWB/bin}"

TERMUX_BASH='#!/data/data/com.termux/files/usr/bin/bash'
DEFAULT_PATTERN='*.sh'

DRY_RUN=0
FORCE=0
VERBOSE=1      # <- default ON
PATTERN="$DEFAULT_PATTERN"

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|--dry) DRY_RUN=1 ;;
    --force|-f) FORCE=1 ;;
    --quiet|-q) VERBOSE=0 ;;           # optional: silence details
    --verbose|-v) VERBOSE=1 ;;         # explicit verbose
    --pattern|-p) shift; PATTERN="${1:-$DEFAULT_PATTERN}" ;;
    --help|-h)
      cat <<EOF
binpush.sh — sanitize & push scripts from bin-edit  bin
Options:
  --dry-run       Show actions without copying
  --force         Copy even if identical
  --quiet         Minimal logs (turns verbose off)
  --verbose       Per-file logs (default)
  --pattern GLOB  Limit to files (default: *.sh)
Env: AIWB, SRC_DIR, DST_DIR
EOF
      exit 0;;
    *) echo " Unknown arg: $1" >&2; exit 2;;
  esac; shift
done

log(){ echo -e "$*"; }
vlog(){ [ "$VERBOSE" -eq 1 ] && echo -e "$*"; }
die(){ echo " $*" >&2; exit 1; }

[ -d "$SRC_DIR" ] || die "Source dir not found: $SRC_DIR"
mkdir -p "$DST_DIR"

normalize_line_endings(){ awk 'BEGIN{RS="\r?\n"; ORS="\n"} {print}' "$1" > "$1.tmp" && mv "$1.tmp" "$1"; }
fix_shebang(){
  local f="$1" first; first="$(head -n1 "$f" || true)"
  if [[ "$first" =~ ^#! ]]; then sed -i '1s|^#!.*$|'"$TERMUX_BASH"'|' "$f"
  else { echo "$TERMUX_BASH"; echo; cat "$f"; } > "$f.tmp" && mv "$f.tmp" "$f"; fi
}
same_content(){ cmp -s -- "$1" "$2" 2>/dev/null; }
copy_file(){ [ "$DRY_RUN" -eq 1 ] && log " DRY: cp '$1'  '$2'" || install -m 0755 "$1" "$2"; }

sanitize_to_tmp(){ cp -f "$1" "$2"; normalize_line_endings "$2"; fix_shebang "$2"; chmod +x "$2" || true; }

log " Sanitizing & pushing from:\n  SRC: $SRC_DIR\n  DST: $DST_DIR\n  Filter: $PATTERN"
[ "$DRY_RUN" -eq 1 ] && log " Dry-run mode: no files will be written."

shopt -s nullglob
FILES=("$SRC_DIR"/$PATTERN)
[ ${#FILES[@]} -gt 0 ] || { log " No files match pattern."; exit 0; }

push_count=0; skip_same=0; err_count=0
for SRC in "${FILES[@]}"; do
  [ -f "$SRC" ] || continue
  base="$(basename "$SRC")"; DST="$DST_DIR/$base"
  vlog "\n Processing: $base "
  TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
  if ! sanitize_to_tmp "$SRC" "$TMP"; then log " Failed to sanitize $base"; err_count=$((err_count+1)); rm -f "$TMP"; trap - EXIT; continue; fi
  if [ -f "$DST" ] && same_content "$TMP" "$DST" && [ "$FORCE" -ne 1 ]; then
    vlog "  Identical content, skipping copy: $base"; skip_same=$((skip_same+1)); rm -f "$TMP"; trap - EXIT; continue
  fi
  if copy_file "$TMP" "$DST"; then log " Pushed: $base"; push_count=$((push_count+1))
  else log " Copy failed: $base"; err_count=$((err_count+1)); fi
  rm -f "$TMP"; trap - EXIT
done

echo
log " Summary:\n  • Pushed: $push_count\n  • Skipped same: $skip_same\n  • Errors: $err_count\n  • Verbose: $( [ $VERBOSE -eq 1 ] && echo ON || echo OFF )"
[ "$push_count" -gt 0 ] && [ "$DRY_RUN" -eq 0 ] && log "\n Try a script:\n  $DST_DIR/gpre.sh --tier top --confirm\n  $DST_DIR/cpre.sh --tier medium --confirm"
exit $([ "$err_count" -eq 0 ] && echo 0 || echo 1)