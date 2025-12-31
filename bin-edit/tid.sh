#!/usr/bin/env bash
set -eo pipefail
AIWB="${AIWB:-$HOME/.aiwb/workspace}"
[ -f "$AIWB/current.task" ] && cat "$AIWB/current.task" || echo "(no active task)"