#!/usr/bin/env bash
set -euo pipefail
AIWB="${AIWB:-$HOME/.aiwb/workspace}"
[ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "(no active task)"