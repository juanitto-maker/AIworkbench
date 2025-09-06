#!/data/data/com.termux/files/usr/bin/bash
# Common paths & defaults

# Workbench home (tools live here)
export AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"

# Project root (every project gets its own folder here)
export PROJ_ROOT="${PROJ_ROOT:-$HOME/storage/shared/0code}"

# State files for “current project / task”
export CURRENT_PROJECT_FILE="$AIWB/current.project"
export CURRENT_TASK_FILE="$AIWB/current.task"

# Models & price knobs (fill real values or keep env overrides)
export GEMINI_MODEL="${GEMINI_MODEL:-gemini-1.5-flash}"
export CLAUDE_MODEL="${CLAUDE_MODEL:-claude-3-5-sonnet-latest}"
export MAX_OUT_TOKENS_DEFAULT="${MAX_OUT_TOKENS_DEFAULT:-16000}"

# Pricing (per‑1K tokens, USD). Keep easy to adjust.
# Gemini Flash (example): in/out $0.35/$0.70  — tweak to match your account
export G_USD_IN_PER_1K="${G_USD_IN_PER_1K:-0.35}"
export G_USD_OUT_PER_1K="${G_USD_OUT_PER_1K:-0.70}"

# Claude Sonnet (example): in/out $3.00/$15.00 — tweak to match your plan
export C_USD_IN_PER_1K="${C_USD_IN_PER_1K:-3.00}"
export C_USD_OUT_PER_1K="${C_USD_OUT_PER_1K:-15.00}"

# FX: USD→EUR (optional). If unset or 0, EUR will not be shown.
export FX_USD_EUR="${FX_USD_EUR:-0}"

# Ensure root dirs exist
mkdir -p "$AIWB" "$PROJ_ROOT"