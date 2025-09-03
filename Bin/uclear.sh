#!/data/data/com.termux/files/usr/bin/bash
# Usage:
#   uclear.sh                # interactive confirm
#   uclear.sh -a             # delete ALL (asks once)
#   uclear.sh -k pattern     # keep matching pattern, delete others
#   uclear.sh -o DAYS        # delete files older than DAYS
#   uclear.sh -y ...         # no prompts

set -euo pipefail
AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
UP="$AIWB/uploads"; mkdir -p "$UP"

ALL=0; YES=0; KEEP=""; DAYS=""
while getopts ":aky o:" opt; do
  case "$opt" in
    a) ALL=1;;
    y) YES=1;;
    k) KEEP="$OPTARG";;
    o) DAYS="$OPTARG";;
    *) echo "Usage: uclear.sh [-a] [-y] [-k pattern] [-o DAYS]"; exit 2;;
  esac
done

cd "$UP"

targets=()
if [ "$ALL" -eq 1 ]; then
  mapfile -t targets < <(find . -maxdepth 1 -type f -printf "%P\n")
elif [ -n "$DAYS" ]; then
  mapfile -t targets < <(find . -maxdepth 1 -type f -mtime +"$DAYS" -printf "%P\n")
else
  echo "Nothing to do. Use -a or -o DAYS. (Or -k pattern with -a/-o)"
  exit 0
fi

if [ -n "$KEEP" ] && [ "${#targets[@]}" -gt 0 ]; then
  tmp=()
  for f in "${targets[@]}"; do
    [[ "$f" == *"$KEEP"* ]] && continue
    tmp+=("$f")
  done
  targets=("${tmp[@]}")
fi

[ "${#targets[@]}" -gt 0 ] || { echo "No matching files."; exit 0; }

echo "Will delete:"
printf '  %s\n' "${targets[@]}"

if [ "$YES" -ne 1 ]; then
  read -rp "Proceed? [y/N] " r
  [[ "$r" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi

for f in "${targets[@]}"; do rm -f -- "$f"; done
echo "✅ Cleared."