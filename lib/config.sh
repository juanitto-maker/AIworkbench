#!/usr/bin/env bash
# config.sh - Configuration management for AIWB

# Guard: prevent multiple sourcing
[[ -n "${AIWB_LIB_CONFIG_LOADED:-}" ]] && return 0

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ============================================================================
# CONSTANTS - Centralized configuration values
# ============================================================================

# API Configuration
readonly AIWB_MAX_TOKENS_DEFAULT=16000      # Default max tokens for API calls
readonly AIWB_TEMPERATURE_DEFAULT=0.2       # Default temperature (0.0-1.0, lower = more focused)
readonly AIWB_API_TIMEOUT=300               # API call timeout in seconds (5 minutes)
readonly AIWB_API_CONNECT_TIMEOUT=10        # Connection timeout in seconds
readonly AIWB_HEADLESS_TIMEOUT="${AIWB_HEADLESS_TIMEOUT:-300}"  # Headless pipeline timeout (seconds)

# Logging Configuration
readonly AIWB_LOG_RETENTION=10              # Number of log files to keep
readonly AIWB_MAX_LOG_SIZE=10485760         # Max log file size in bytes (10MB)
readonly AIWB_LOG_ROTATION_LINES=1000       # Lines to keep when rotating logs

# Context Configuration
readonly AIWB_CONTEXT_FILE_PREVIEW_LINES=20 # Lines to show when previewing files in context
readonly AIWB_MAX_FILE_SIZE=100000          # Max file size for context in bytes (100KB)

# UI Configuration
readonly AIWB_UI_MENU_HEIGHT=15             # Default menu height for gum choose
readonly AIWB_UI_SHORT_DELAY=0.1            # Short delay for UI updates (seconds)
readonly AIWB_UI_MEDIUM_DELAY=0.5           # Medium delay for UI updates (seconds)
readonly AIWB_UI_INFINITE_TIMEOUT=999999    # Infinite timeout for background processes (seconds)
readonly AIWB_ERROR_RETRY_DELAY=60          # Delay before retrying on errors (seconds)

# Threshold Configuration
readonly AIWB_RESPONSE_LINES_THRESHOLD=100  # Lines threshold for truncating large responses
readonly AIWB_EDITOR_PREVIEW_THRESHOLD=30   # Lines threshold for showing more/less in editor
readonly AIWB_OUTPUT_PREVIEW_THRESHOLD=20   # Lines threshold for output preview
readonly AIWB_MIN_API_KEY_LENGTH=30         # Minimum length for API key validation
readonly AIWB_CONTEXT_STATE_MAX_AGE_DAYS=7  # Maximum age for context state before warning (days)
readonly AIWB_KEY_DISPLAY_LIMIT=3           # Maximum number of keys to display in security audit

# HTTP Configuration
readonly AIWB_HTTP_ERROR_THRESHOLD=400      # HTTP status code threshold for errors

# Exit Codes
readonly AIWB_EXIT_SUCCESS=0                # Successful execution
readonly AIWB_EXIT_ERROR=1                  # General error
readonly AIWB_EXIT_USAGE=2                  # Usage/syntax error
readonly AIWB_EXIT_SIGINT=130               # Exit code for SIGINT (Ctrl+C)

# ============================================================================
# CONFIGURATION PATHS
# ============================================================================

get_config_file() {
    echo "$(get_aiwb_home)/config.json"
}

get_session_file() {
    echo "$(get_aiwb_home)/.session"
}

get_env_file() {
    echo "$(get_aiwb_home)/.aiwb.env"
}

get_keys_file() {
    echo "$(get_aiwb_home)/.keys.age"
}

# ============================================================================
# WORKSPACE INITIALIZATION
# ============================================================================

init_workspace() {
    local workspace
    workspace="$(get_workspace)"

    debug "Initializing workspace at: $workspace"

    # Function to try creating workspace and subdirectories
    try_create_workspace() {
        local ws="$1"

        # Try to create main workspace directory
        ensure_dir "$ws" || return 1

        # Try to create subdirectories
        ensure_dir "$ws/projects" || return 1
        ensure_dir "$ws/tasks" || return 1
        ensure_dir "$ws/snapshots" || return 1
        ensure_dir "$ws/logs" || return 1
        ensure_dir "$ws/templates" || return 1
        ensure_dir "$ws/history" || return 1

        return 0
    }

    # Try to create workspace structure at configured location
    if ! try_create_workspace "$workspace"; then
        # If workspace creation fails (e.g., Termux storage not accessible),
        # fall back to .aiwb/workspace
        local fallback_workspace
        fallback_workspace="$(get_aiwb_home)/workspace"

        warn "Could not create workspace at: $workspace"
        warn "Falling back to: $fallback_workspace"

        if is_termux; then
            warn "If you want to use external storage, run: termux-setup-storage"
        fi

        workspace="$fallback_workspace"

        # Try fallback location
        if ! try_create_workspace "$workspace"; then
            err "CRITICAL: Cannot create workspace at $workspace"
            err "Please check filesystem permissions"
            return 1
        fi

        # Update config with fallback workspace
        local config_file
        config_file="$(get_config_file)"
        if [[ -f "$config_file" ]]; then
            local tmp
            tmp="$(aiwb_mktemp)"
            jq --arg ws "$workspace" '.workspace = $ws' "$config_file" > "$tmp" && mv "$tmp" "$config_file"
        fi
    fi

    # Create default inbox task if doesn't exist
    local inbox="$workspace/tasks/inbox.prompt.md"
    if [[ ! -f "$inbox" ]]; then
        cat > "$inbox" <<'EOF'
# Inbox

This is your default task workspace. Use this for quick experiments and one-off prompts.

## Current Task

<!-- Describe what you want to accomplish -->

## Context

<!-- Provide any relevant background information -->

## Requirements

<!-- List specific requirements or constraints -->
EOF
        debug "Created default inbox task"
    fi

    # Create AIWB home structure
    local aiwb_home
    aiwb_home="$(get_aiwb_home)"
    ensure_dir "$aiwb_home"

    success "Workspace initialized at: $workspace"
}

# ============================================================================
# CONFIG FILE MANAGEMENT
# ============================================================================

# Get default configuration
get_default_config() {
    cat <<'JSON'
{
  "version": "2.0.0",
  "workspace": "",
  "model_provider": "gemini",
  "model_name": "2.5-flash",
  "current_task": "",
  "current_project": "",
  "preferences": {
    "auto_estimate": true,
    "confirm_before_generate": true,
    "show_costs": true,
    "stream_output": false,
    "tier_default": "Medium",
    "syntax_highlighting": true
  },
  "cost_tracking": {
    "enabled": true,
    "monthly_budget": 0,
    "currency": "USD"
  },
  "security": {
    "encrypt_keys": false,
    "warn_on_exposure": true
  }
}
JSON
}

# Load or create configuration
load_config() {
    local config_file
    config_file="$(get_config_file)"

    if [[ ! -f "$config_file" ]]; then
        debug "Creating new config file"
        get_default_config > "$config_file"
    fi

    # Set workspace in config if not set
    local workspace
    workspace="$(get_workspace)"
    local current_ws
    current_ws="$(json_get '.workspace' "$config_file")"

    if [[ -z "$current_ws" || "$current_ws" == "null" ]]; then
        local tmp
        tmp="$(aiwb_mktemp)"
        jq --arg ws "$workspace" '.workspace = $ws' "$config_file" > "$tmp" && mv "$tmp" "$config_file"
    fi
}

# Get config value
config_get() {
    local key="$1"
    local default="${2:-}"
    local config_file
    config_file="$(get_config_file)"

    [[ ! -f "$config_file" ]] && load_config

    local value
    value="$(json_get ".$key" "$config_file")"

    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Set config value
config_set() {
    local key="$1"
    local value="$2"
    local config_file
    config_file="$(get_config_file)"

    [[ ! -f "$config_file" ]] && load_config

    local tmp
    tmp="$(aiwb_mktemp)"

    # Handle nested keys (e.g., "preferences.auto_estimate")
    if [[ "$key" == *.* ]]; then
        jq --arg v "$value" ".$key = \$v" "$config_file" > "$tmp" && mv "$tmp" "$config_file"
    else
        jq --arg k "$key" --arg v "$value" '.[$k] = $v' "$config_file" > "$tmp" && mv "$tmp" "$config_file"
    fi
}

# ============================================================================
# SESSION MANAGEMENT
# ============================================================================

save_session() {
    local session_file
    session_file="$(get_session_file)"

    local workspace provider model task project
    workspace="$(config_get workspace)"
    provider="$(config_get model_provider 'gemini')"
    model="$(config_get model_name '2.5-flash')"
    task="$(config_get current_task '')"
    project="$(config_get current_project '')"

    cat > "$session_file" <<JSON
{
  "workspace": "$workspace",
  "model_provider": "$provider",
  "model_name": "$model",
  "task": "$task",
  "project": "$project",
  "timestamp": "$(date -Iseconds)"
}
JSON
}

load_session() {
    local session_file
    session_file="$(get_session_file)"

    [[ ! -f "$session_file" ]] && return 0

    # Load session values into config if more recent
    local ws provider model task project
    ws="$(json_get '.workspace' "$session_file")"
    provider="$(json_get '.model_provider' "$session_file")"
    model="$(json_get '.model_name' "$session_file")"
    task="$(json_get '.task' "$session_file")"
    project="$(json_get '.project' "$session_file")"

    # Set config values if they exist (use || true to prevent set -e exit)
    [[ -n "$ws" && "$ws" != "null" ]] && config_set workspace "$ws" || true
    [[ -n "$provider" && "$provider" != "null" ]] && config_set model_provider "$provider" || true
    [[ -n "$model" && "$model" != "null" ]] && config_set model_name "$model" || true
    [[ -n "$task" && "$task" != "null" ]] && config_set current_task "$task" || true
    [[ -n "$project" && "$project" != "null" ]] && config_set current_project "$project" || true
}

# ============================================================================
# MODEL DEFAULTS
# ============================================================================

get_default_model() {
    local provider="${1:-gemini}"

    case "$provider" in
        gemini) echo "2.5-flash" ;;
        claude) echo "haiku-4-5-20251001" ;;
        openai) echo "gpt-4o-mini-2024-07-18" ;;
        groq) echo "llama-3.3-70b-versatile" ;;
        xai) echo "grok-3" ;;
        ollama) echo "llama3.2:latest" ;;
        *) echo "" ;;
    esac
}

get_available_models() {
    local provider="${1:-gemini}"

    case "$provider" in
        gemini)
            # Gemini 2.x models (updated from working_code_models_14.11.txt)
            echo "2.5-flash 2.5-pro 2.5-flash-lite 2.0-flash 2.0-flash-001 2.0-flash-lite-001 2.0-flash-lite"
            ;;
        claude)
            # Claude models (updated from working_code_models_14.11.txt)
            echo "haiku-4-5-20251001 sonnet-4-5-20250929 opus-4-1-20250805 opus-4-20250514 sonnet-4-20250514 3-7-sonnet-20250219 3-5-haiku-20241022 3-haiku-20240307"
            ;;
        openai)
            # OpenAI models (verified working)
            echo "gpt-4.1-2025-04-14 gpt-4.1-mini gpt-4o gpt-4o-mini-2024-07-18"
            ;;
        groq)
            # Groq models (verified working)
            echo "llama-3.3-70b-versatile openai/gpt-oss-120b openai/gpt-oss-20b"
            ;;
        xai)
            # xAI Grok models (updated from working_code_models_14.11.txt)
            echo "grok-2-1212 grok-2-vision-1212 grok-3 grok-3-mini grok-4-0709 grok-4-fast-non-reasoning grok-4-fast-reasoning grok-code-fast-1"
            ;;
        ollama)
            if have ollama; then
                ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | tr '\n' ' '
            else
                echo "llama3.2:latest mistral:latest codellama:latest"
            fi
            ;;
        *)
            echo ""
            ;;
    esac
}

# ============================================================================
# EXPORTS
# ============================================================================

export AIWB_LIB_CONFIG_LOADED=1
