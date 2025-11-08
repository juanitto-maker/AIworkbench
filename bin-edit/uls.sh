#!/usr/bin/env bash
set -euo pipefail
AIWB="${AIWB:-$HOME/.aiwb/workspace}"
UP="$AIWB/uploads"
mkdir -p "$UP"
echo "📁 $UP"
ls -lah "$UP"