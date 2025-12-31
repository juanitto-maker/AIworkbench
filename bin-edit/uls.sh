#!/usr/bin/env bash
set -eo pipefail
AIWB="${AIWB:-$HOME/.aiwb/workspace}"
UP="$AIWB/uploads"
mkdir -p "$UP"
echo "📁 $UP"
ls -lah "$UP"