#!/usr/bin/env bash
# aiwb_headless.sh — AIworkbench headless entry point for bot/CI/script use
#
# Runs aiwb in fully non-interactive mode: no gum TUI, no confirmation prompts,
# no "what's next?" menus. Designed for automation, bots, and CI pipelines.
#
# Usage:
#   aiwb_headless --mode make   --prompt "build a REST API for users"
#   aiwb_headless --mode tweak  --instruct /path/to/instructions.md
#   aiwb_headless --mode debug  --prompt "fix the login bug"
#
# Options (same as 'aiwb headless'):
#   --mode        make|tweak|debug  (required)
#   --prompt      inline prompt text
#   --instruct    path to instruction file (alternative to --prompt)
#   --model       provider:name  e.g. gemini:gemini-2.0-flash-exp
#   --provider    model provider name
#   --model-name  model name
#   --verifier    provider:name for verification step
#   --check-instruct  path to check instruction file
#   --context     path to context file or directory
#   --output      copy output to this file path

export AIWB_HEADLESS=1

# Resolve real path to aiwb sibling script
SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"

# When installed via binpush, aiwb lives alongside this script in DEST_BIN
exec "${SCRIPT_DIR}/aiwb" headless "$@"
