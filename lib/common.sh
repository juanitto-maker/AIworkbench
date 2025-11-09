#!/usr/bin/env bash
# common.sh - Shared utilities for AIWB
# Universal compatibility layer for Linux, macOS, and Termux

# ============================================================================
# PLATFORM DETECTION
# ============================================================================

is_termux() {
    [[ "${PREFIX:-}" == *com.termux* ]] || [[ "${OSTYPE:-}" == "linux-android"* ]]
}

is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

is_linux() {
    [[ "$(uname -s)" == "Linux" ]] && ! is_termux
}

get_platform() {
    if is_termux; then echo "termux"
    elif is_macos; then echo "macos"
    elif is_linux; then echo "linux"
    else echo "unknown"
    fi
}

# ============================================================================
# COMMAND AVAILABILITY
# ============================================================================

have() {
    command -v "$1" >/dev/null 2>&1
}

require() {
    local cmd="$1"
    local msg="${2:-Command '$cmd' is required but not found}"
    if ! have "$cmd"; then
        err "$msg"
        exit 1
    fi
}

# Check if running with color support
supports_color() {
    [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]
}

# ============================================================================
# SAFE INPUT READING (Termux-compatible)
# ============================================================================

# Safely read input with proper fallback handling
# Returns 0 on success, 1 on failure
# Usage: safe_read [-p prompt] variable_name
safe_read() {
    local prompt="" var_name read_opts=()

    # Parse arguments
    if [[ "$1" == "-p" ]]; then
        prompt="$2"
        var_name="$3"
        read_opts=(-r -p "$prompt")
    else
        var_name="$1"
        read_opts=(-r)
    fi

    # Try reading in order of preference
    # 1. Try /dev/tty if in Termux (most reliable for Android)
    # 2. Try stdin if it's a terminal
    # 3. Fail gracefully

    if is_termux; then
        # Termux: Prefer /dev/tty over stdin
        if [[ -c /dev/tty ]] && exec 3</dev/tty 2>/dev/null; then
            read "${read_opts[@]}" "$var_name" <&3
            local result=$?
            exec 3<&- 2>/dev/null || true
            return $result
        fi
    fi

    # Non-Termux or /dev/tty failed: try stdin
    if [[ -t 0 ]]; then
        read "${read_opts[@]}" "$var_name"
        return $?
    fi

    # No interactive input available
    return 1
}

# ============================================================================
# OUTPUT FORMATTING
# ============================================================================

# Colors
if supports_color; then
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    MAGENTA='\033[1;35m'
    CYAN='\033[1;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    BOLD=''
    DIM=''
    RESET=''
fi

# Logging functions
msg() {
    printf "${GREEN}==>${RESET} ${BOLD}%s${RESET}\n" "$*"
}

info() {
    printf "${BLUE}ℹ${RESET}  %s\n" "$*"
}

success() {
    printf "${GREEN}✓${RESET}  %s\n" "$*"
}

warn() {
    printf "${YELLOW}!${RESET}  %s\n" "$*" >&2
}

err() {
    printf "${RED}✗${RESET}  %s\n" "$*" >&2
}

debug() {
    if [[ "${AIWB_DEBUG:-0}" == "1" ]]; then
        printf "${DIM}DEBUG: %s${RESET}\n" "$*" >&2
    fi
}

# Progress indicator
spinner() {
    local pid=$1
    local message="${2:-Processing...}"
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % ${#spinstr} ))
        printf "\r${CYAN}${spinstr:$i:1}${RESET} %s" "$message"
        sleep 0.1
    done
    printf "\r"
}

# ============================================================================
# PATH UTILITIES
# ============================================================================

# Get the AIWB home directory
get_aiwb_home() {
    echo "${AIWB_HOME:-$HOME/.aiwb}"
}

# Get the workspace directory
get_workspace() {
    local aiwb_home
    aiwb_home="$(get_aiwb_home)"

    # Check if user has custom workspace
    if [[ -n "${AIWB_WORKSPACE:-}" ]]; then
        echo "$AIWB_WORKSPACE"
        return
    fi

    # Try to use Android-visible storage on Termux
    if is_termux && [[ -d "$HOME/storage/shared" ]]; then
        echo "$HOME/storage/shared/aiwb"
    else
        echo "${aiwb_home}/workspace"
    fi
}

# Ensure directory exists
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || {
            err "Failed to create directory: $dir"
            return 1
        }
    fi
}

# ============================================================================
# JSON UTILITIES
# ============================================================================

json_get() {
    local query="$1"
    local file="${2:--}"  # default to stdin

    if [[ "$file" == "-" ]]; then
        jq -r "$query" 2>/dev/null || echo ""
    else
        jq -r "$query" "$file" 2>/dev/null || echo ""
    fi
}

json_set() {
    local file="$1"
    local key="$2"
    local value="$3"

    local tmp
    tmp="$(mktemp)"
    jq --arg k "$key" --arg v "$value" '.[$k] = $v' "$file" > "$tmp" && mv "$tmp" "$file"
}

# ============================================================================
# STRING UTILITIES
# ============================================================================

# Trim whitespace
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

# Convert to lowercase
lowercase() {
    echo "$*" | tr '[:upper:]' '[:lower:]'
}

# Convert to uppercase
uppercase() {
    echo "$*" | tr '[:lower:]' '[:upper:]'
}

# ============================================================================
# CONFIRMATION
# ============================================================================

confirm() {
    local prompt="${1:-Are you sure?}"
    local default="${2:-n}"  # y or n

    # Use gum if available
    if have gum; then
        gum confirm "$prompt"
        return $?
    fi

    # Fallback to read
    local yn=""
    local prompt_text

    # Prepare prompt text
    if [[ "$default" == "y" ]]; then
        prompt_text="$prompt [Y/n] "
    else
        prompt_text="$prompt [y/N] "
    fi

    # Try to read from user using safe_read helper
    if ! safe_read -p "$prompt_text" yn; then
        # No interactive input available, use default
        yn="$default"
    fi

    # Check response
    if [[ "$default" == "y" ]]; then
        [[ -z "$yn" || "$yn" =~ ^[Yy]$ ]]
    else
        [[ "$yn" =~ ^[Yy]$ ]]
    fi
}

# ============================================================================
# VERSION COMPARISON
# ============================================================================

version_gte() {
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# ============================================================================
# CLEANUP HANDLERS
# ============================================================================

# Trap cleanup on exit
cleanup_handlers=()

add_cleanup_handler() {
    cleanup_handlers+=("$1")
}

run_cleanup_handlers() {
    # Check if array has elements before iterating (set -u compatibility)
    if [[ ${#cleanup_handlers[@]} -gt 0 ]]; then
        for handler in "${cleanup_handlers[@]}"; do
            eval "$handler" 2>/dev/null || true
        done
    fi
}

trap run_cleanup_handlers EXIT TERM

# ============================================================================
# EXPORTS
# ============================================================================

export AIWB_LIB_COMMON_LOADED=1
