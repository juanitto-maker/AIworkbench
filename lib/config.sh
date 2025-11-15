#!/usr/bin/env bash
# config.sh - Configuration management for AIWB

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

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
            tmp="$(mktemp)"
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
    "tier_default": "Medium"
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
        tmp="$(mktemp)"
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
    tmp="$(mktemp)"

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
            # OpenAI models (updated from working_code_models_14.11.txt)
            echo "gpt-5-nano-2025-08-07 gpt-5-mini-2025-08-07 gpt-5-2025-08-07 gpt-5-pro-2025-10-06 gpt-5-codex gpt-5.1-2025-11-13 gpt-5.1-codex gpt-5.1-codex-mini gpt-4.1-2025-04-14 gpt-4.1-mini gpt-4o gpt-4o-mini-2024-07-18 gpt-3.5-turbo gpt-3.5-turbo-0125 gpt-3.5-turbo-instruct codex-mini-latest"
            ;;
        groq)
            # Groq models (updated from working_code_models_14.11.txt)
            echo "llama-3.3-70b-versatile openai/gpt-oss-120b openai/gpt-oss-20b groq/compound-min"
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
