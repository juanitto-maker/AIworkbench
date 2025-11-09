#!/usr/bin/env bash
# Common paths & defaults

# Workbench home (tools live here)
export AIWB="${AIWB:-$HOME/.aiwb/workspace}"

# Project root (every project gets its own folder here)
export PROJ_ROOT="${PROJ_ROOT:-$HOME/storage/shared/0code}"

# State files for “current project / task”
export CURRENT_PROJECT_FILE="$AIWB/current.project"
export CURRENT_TASK_FILE="$AIWB/current.task"

# Models & price knobs (fill real values or keep env overrides)
export GEMINI_MODEL="${GEMINI_MODEL:-gemini-2.5-flash}"
export CLAUDE_MODEL="${CLAUDE_MODEL:-claude-3-5-sonnet-20241022}"
export MAX_OUT_TOKENS_DEFAULT="${MAX_OUT_TOKENS_DEFAULT:-16000}"

# Pricing (per‑1K tokens, USD). Keep easy to adjust.
# Gemini 2.5 Flash: in/out $0.30/$2.50 per 1M tokens = $0.0003/$0.0025 per 1K
export G_USD_IN_PER_1K="${G_USD_IN_PER_1K:-0.0003}"
export G_USD_OUT_PER_1K="${G_USD_OUT_PER_1K:-0.0025}"

# Claude 4.5 Sonnet: in/out $3.00/$15.00 per 1M tokens = $0.003/$0.015 per 1K
export C_USD_IN_PER_1K="${C_USD_IN_PER_1K:-0.003}"
export C_USD_OUT_PER_1K="${C_USD_OUT_PER_1K:-0.015}"

# FX: USD→EUR (optional). If unset or 0, EUR will not be shown.
export FX_USD_EUR="${FX_USD_EUR:-0}"

# Ensure root dirs exist
mkdir -p "$AIWB" "$PROJ_ROOT"