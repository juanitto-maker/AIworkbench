#!/usr/bin/env bash
# error.sh - Error handling and codes for AIWB

# Guard: prevent multiple sourcing
[[ -n "${AIWB_LIB_ERROR_LOADED:-}" ]] && return 0

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ============================================================================
# ERROR CODES
# ============================================================================

# Exit codes
readonly E_SUCCESS=0
readonly E_GENERAL=1
readonly E_MISUSE=2
readonly E_DEPENDENCY=3
readonly E_CONFIG=4
readonly E_API_KEY=5
readonly E_API_CALL=6
readonly E_NETWORK=7
readonly E_AUTH=8
readonly E_RATE_LIMIT=9
readonly E_FILE_NOT_FOUND=10
readonly E_PERMISSION=11
readonly E_INVALID_INPUT=12

# ============================================================================
# ERROR MESSAGES
# ============================================================================

declare -A ERROR_MESSAGES=(
    [$E_SUCCESS]="Success"
    [$E_GENERAL]="General error"
    [$E_MISUSE]="Command misuse"
    [$E_DEPENDENCY]="Missing dependency"
    [$E_CONFIG]="Configuration error"
    [$E_API_KEY]="API key error"
    [$E_API_CALL]="API call failed"
    [$E_NETWORK]="Network error"
    [$E_AUTH]="Authentication failed"
    [$E_RATE_LIMIT]="Rate limit exceeded"
    [$E_FILE_NOT_FOUND]="File not found"
    [$E_PERMISSION]="Permission denied"
    [$E_INVALID_INPUT]="Invalid input"
)

# ============================================================================
# ERROR HELPERS AND SOLUTIONS
# ============================================================================

# Get helpful solution for error
get_error_solution() {
    local code="$1"

    case "$code" in
        $E_DEPENDENCY)
            cat <<'EOF'
Solutions:
  • Install missing dependencies:
    - Linux/Debian: sudo apt install bash jq curl git
    - macOS: brew install bash jq curl git
    - Termux: pkg install bash jq curl git
  • Run: aiwb --doctor to check dependencies
EOF
            ;;
        $E_API_KEY)
            cat <<'EOF'
Solutions:
  • Set your API key: aiwb /keys
  • Or manually: export GEMINI_API_KEY="your-key"
  • Get keys from:
    - Gemini: https://makersuite.google.com/app/apikey
    - Claude: https://console.anthropic.com/
EOF
            ;;
        $E_API_CALL)
            cat <<'EOF'
Solutions:
  • Check your API key is valid
  • Verify your internet connection
  • Check API status:
    - Gemini: https://status.cloud.google.com/
    - Claude: https://status.anthropic.com/
  • Wait a moment and try again
EOF
            ;;
        $E_NETWORK)
            cat <<'EOF'
Solutions:
  • Check your internet connection
  • Try again in a moment
  • Check if firewall is blocking the connection
  • Verify DNS is working: ping google.com
EOF
            ;;
        $E_AUTH)
            cat <<'EOF'
Solutions:
  • Verify your API key is correct
  • Check if your API key has expired
  • Ensure you have sufficient API credits
  • Re-run: aiwb /keys to update your key
EOF
            ;;
        $E_RATE_LIMIT)
            cat <<'EOF'
Solutions:
  • Wait 60 seconds and try again
  • Upgrade your API plan for higher limits
  • Use a different model with higher limits
  • Enable cost tracking: aiwb /models
EOF
            ;;
        $E_FILE_NOT_FOUND)
            cat <<'EOF'
Solutions:
  • Check the file path is correct
  • Ensure the file exists: ls -la <path>
  • Create the file if needed
  • Check file permissions
EOF
            ;;
        $E_CONFIG)
            cat <<'EOF'
Solutions:
  • Reset configuration: aiwb --reset-config
  • Check config file: ~/.aiwb/config.json
  • Verify JSON syntax is valid
  • Delete and recreate: rm ~/.aiwb/config.json
EOF
            ;;
        *)
            cat <<'EOF'
Solutions:
  • Run with debug mode: AIWB_DEBUG=1 aiwb <command>
  • Check logs: ls ~/.aiwb/workspace/logs/
  • Report issue: https://github.com/juanitto-maker/AIworkbench/issues
EOF
            ;;
    esac
}

# ============================================================================
# ERROR HANDLING FUNCTIONS
# ============================================================================

# Die with error code and message
die() {
    local code="${1:-$E_GENERAL}"
    local message="${2:-${ERROR_MESSAGES[$code]}}"

    err "$message"
    echo ""
    get_error_solution "$code"
    exit "$code"
}

# Handle API errors from response
handle_api_error() {
    local response="$1"
    local provider="${2:-unknown}"

    # Try to extract error from JSON
    local error_msg
    error_msg="$(echo "$response" | jq -r '.error.message // .error // empty' 2>/dev/null)"

    if [[ -z "$error_msg" ]]; then
        err "API call failed"
        debug "Response: $response"
        die "$E_API_CALL" "API call to $provider failed. Check logs for details."
    fi

    # Classify the error
    if echo "$error_msg" | grep -iq "api key"; then
        die "$E_AUTH" "Authentication failed: $error_msg"
    elif echo "$error_msg" | grep -iq "rate limit\|quota"; then
        die "$E_RATE_LIMIT" "Rate limit exceeded: $error_msg"
    elif echo "$error_msg" | grep -iq "network\|connection\|timeout"; then
        die "$E_NETWORK" "Network error: $error_msg"
    else
        die "$E_API_CALL" "API error: $error_msg"
    fi
}

# Validate file exists
require_file() {
    local file="$1"
    local description="${2:-File}"

    if [[ ! -f "$file" ]]; then
        die "$E_FILE_NOT_FOUND" "$description not found: $file"
    fi
}

# Validate directory exists
require_dir() {
    local dir="$1"
    local description="${2:-Directory}"

    if [[ ! -d "$dir" ]]; then
        die "$E_FILE_NOT_FOUND" "$description not found: $dir"
    fi
}

# Validate command available
require_command() {
    local cmd="$1"
    local install_hint="${2:-Install $cmd and try again}"

    if ! have "$cmd"; then
        die "$E_DEPENDENCY" "Required command not found: $cmd\n  → $install_hint"
    fi
}

# Validate API key set
require_api_key() {
    local provider="$1"
    local key
    key="$(get_api_key "$provider")"

    if [[ -z "$key" ]]; then
        die "$E_API_KEY" "API key not set for $provider\n  → Run 'aiwb /keys' to configure"
    fi
}

# ============================================================================
# RETRY LOGIC
# ============================================================================

# Retry command with exponential backoff
retry() {
    local max_attempts="${1:-3}"
    local delay="${2:-2}"
    shift 2
    local cmd=("$@")

    local attempt=1
    local exit_code=0

    while ((attempt <= max_attempts)); do
        debug "Attempt $attempt/$max_attempts: ${cmd[*]}"

        if "${cmd[@]}"; then
            return 0
        fi

        exit_code=$?
        if ((attempt < max_attempts)); then
            warn "Command failed (exit: $exit_code). Retrying in ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))  # Exponential backoff
        fi

        ((attempt++))
    done

    err "Command failed after $max_attempts attempts"
    return "$exit_code"
}

# Retry API call specifically
retry_api_call() {
    local provider="$1"
    shift
    local cmd=("$@")

    # Retry with specific handling for different errors
    local attempt=1
    local max_attempts=3

    while ((attempt <= max_attempts)); do
        local response
        response=$("${cmd[@]}" 2>&1)
        local exit_code=$?

        if [[ $exit_code -eq 0 ]] && [[ -n "$response" ]]; then
            echo "$response"
            return 0
        fi

        # Check if it's a retryable error
        if echo "$response" | grep -iq "rate limit\|429"; then
            if ((attempt < max_attempts)); then
                warn "Rate limit hit. Waiting 60s before retry..."
                sleep 60
            fi
        elif echo "$response" | grep -iq "network\|connection\|timeout"; then
            if ((attempt < max_attempts)); then
                warn "Network error. Retrying in $((attempt * 2))s..."
                sleep $((attempt * 2))
            fi
        else
            # Non-retryable error
            handle_api_error "$response" "$provider"
        fi

        ((attempt++))
    done

    handle_api_error "$response" "$provider"
}

# ============================================================================
# VALIDATION
# ============================================================================

# Validate JSON
validate_json() {
    local data="$1"
    echo "$data" | jq -e . >/dev/null 2>&1
}

# Validate provider
validate_provider() {
    local provider="$1"
    case "$provider" in
        gemini|claude|openai|groq|ollama) return 0 ;;
        *) return 1 ;;
    esac
}

# Validate model for provider
validate_model() {
    local provider="$1"
    local model="$2"

    local available
    available="$(get_available_models "$provider")"

    if echo "$available" | grep -qw "$model"; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# EXPORTS
# ============================================================================

export AIWB_LIB_ERROR_LOADED=1
