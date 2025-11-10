#!/usr/bin/env bash
# AIWB Debugging Console
# Interactive debugging and functionality testing tool
# Exits cleanly when done - no hanging!

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/aiwb_debug_$(date +%Y%m%d_%H%M%S).log"
TIMEOUT_SECONDS=30  # Reduced timeout

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Test tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
declare -a ISSUES

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

header() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${CYAN}$*${RESET}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

section() {
    echo ""
    echo -e "${BOLD}▶ $*${RESET}"
}

pass() {
    echo -e "${GREEN}✓${RESET} $*"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

fail() {
    echo -e "${RED}✗${RESET} $*"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    ISSUES+=("$*")
}

warn() {
    echo -e "${YELLOW}⚠${RESET} $*"
}

info() {
    echo -e "${CYAN}ℹ${RESET} $*"
}

# ============================================================================
# TEST FUNCTIONS
# ============================================================================

test_basic_info() {
    section "Basic Information"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    local version
    version=$("$SCRIPT_DIR/aiwb" --version 2>&1 || echo "FAILED")

    if [[ "$version" =~ "AIWB v" ]]; then
        pass "Version: $version"
    else
        fail "Version check failed"
    fi

    echo "  Platform: $(uname -s)"
    echo "  Termux: $(command -v termux-info &>/dev/null && echo "Yes" || echo "No")"
    echo "  Working Dir: $SCRIPT_DIR"
}

test_workspace() {
    section "Workspace Structure"

    local config="$HOME/.aiwb/config.json"
    local workspace=""

    if [[ -f "$config" ]]; then
        workspace=$(jq -r '.workspace' "$config" 2>/dev/null || echo "")
        pass "Config exists: $config"
        echo "  Configured workspace: $workspace"
    else
        warn "No config file yet"
    fi

    # Check directories using workspace from config
    local check_workspace="$workspace"
    if [[ -z "$check_workspace" || "$check_workspace" == "null" ]]; then
        check_workspace="$HOME/.aiwb/workspace"
    fi

    local dirs=(
        "$check_workspace"
        "$check_workspace/projects"
        "$check_workspace/tasks"
        "$check_workspace/logs"
        "$check_workspace/templates"
    )

    TOTAL_TESTS=$((TOTAL_TESTS + ${#dirs[@]}))

    local missing=0
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            pass "Directory exists: $(basename "$dir")"
        else
            fail "Missing directory: $dir"
            ((missing++))
        fi
    done

    if [[ $missing -gt 0 ]]; then
        warn "Run './aiwb chat' to initialize workspace"
    fi
}

test_config() {
    section "Configuration Check"

    local config="$HOME/.aiwb/config.json"

    if [[ ! -f "$config" ]]; then
        warn "Config not found - run './aiwb' to create"
        return
    fi

    TOTAL_TESTS=$((TOTAL_TESTS + 3))

    # Check provider
    local provider=$(jq -r '.model_provider' "$config" 2>/dev/null)
    if [[ -n "$provider" && "$provider" != "null" ]]; then
        pass "Provider: $provider"
    else
        fail "No provider configured"
    fi

    # Check model
    local model=$(jq -r '.model_name' "$config" 2>/dev/null)
    if [[ -n "$model" && "$model" != "null" ]]; then
        # Check if model is deprecated
        if [[ "$model" =~ "1.5-" ]]; then
            fail "Model '$model' is DEPRECATED - use 2.5-flash or 2.0-flash"
        elif [[ "$provider" == "gemini" && "$model" == "2.0-pro" ]]; then
            warn "Model '$model' - consider 2.5-flash (faster, cheaper)"
        else
            pass "Model: $model"
        fi
    else
        fail "No model configured"
    fi

    # Check workspace
    local workspace=$(jq -r '.workspace' "$config" 2>/dev/null)
    if [[ -n "$workspace" && "$workspace" != "null" ]]; then
        if [[ -d "$workspace" ]]; then
            pass "Workspace accessible: $workspace"
        else
            fail "Workspace NOT accessible: $workspace"
            ISSUES+=("Workspace directory doesn't exist - initialization failed")
        fi
    else
        fail "No workspace configured"
    fi
}

test_api_keys() {
    section "API Keys Check"

    local env_file="$HOME/.aiwb/.aiwb.env"
    local found=0

    # Check environment variables
    for var in GEMINI_API_KEY ANTHROPIC_API_KEY OPENAI_API_KEY GROQ_API_KEY XAI_API_KEY; do
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        if [[ -n "${!var:-}" ]]; then
            pass "${var%_API_KEY}: Set in environment"
            ((found++))
        elif [[ -f "$env_file" ]] && grep -q "$var" "$env_file" 2>/dev/null; then
            pass "${var%_API_KEY}: Set in .aiwb.env"
            ((found++))
        else
            info "${var%_API_KEY}: Not configured"
        fi
    done

    if [[ $found -eq 0 ]]; then
        warn "No API keys found - run './aiwb keys' to configure"
    fi
}

test_quick_functionality() {
    section "Quick Functionality Test"

    # Only test if we have API keys
    local has_key=false
    for var in GEMINI_API_KEY ANTHROPIC_API_KEY OPENAI_API_KEY GROQ_API_KEY XAI_API_KEY; do
        if [[ -n "${!var:-}" ]]; then
            has_key=true
            break
        fi
    done

    if ! $has_key; then
        warn "Skipping API test - no keys configured"
        return
    fi

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    info "Testing basic chat (10 second timeout)..."

    # Create minimal test
    local test_input=$(mktemp)
    echo -e "hi\n/exit\nyes" > "$test_input"

    local output=$(mktemp)

    # Run with short timeout and capture output
    if timeout 10 "$SCRIPT_DIR/aiwb" chat < "$test_input" > "$output" 2>&1; then
        if grep -qi "error\|failed\|404\|401" "$output"; then
            fail "Chat test - API error detected"
            echo "  $(grep -i error "$output" | head -1)"
        else
            pass "Chat responds successfully"
        fi
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            warn "Chat test timed out (may be working but slow)"
        else
            fail "Chat test failed with exit code: $exit_code"
        fi
    fi

    rm -f "$test_input" "$output"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    # Trap to ensure clean exit
    trap 'echo ""; info "Exiting..."; exit 0' INT TERM

    clear
    header "AIWB Debugging Console"

    echo "Debug log: $LOG_FILE"
    echo "Date: $(date)"
    echo ""

    # Run tests
    test_basic_info
    test_workspace
    test_config
    test_api_keys
    test_quick_functionality

    # Summary
    header "Summary"

    echo ""
    echo -e "${BOLD}Tests Run:${RESET} $TOTAL_TESTS"
    echo -e "${GREEN}${BOLD}Passed:${RESET}    $PASSED_TESTS"
    echo -e "${RED}${BOLD}Failed:${RESET}    $FAILED_TESTS"
    echo ""

    if [[ ${#ISSUES[@]} -gt 0 ]]; then
        echo -e "${RED}${BOLD}Issues Found:${RESET}"
        for issue in "${ISSUES[@]}"; do
            echo -e "  ${RED}•${RESET} $issue"
        done
        echo ""
    fi

    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ All checks passed!${RESET}"
    else
        echo -e "${YELLOW}${BOLD}⚠ Some issues need attention${RESET}"
    fi

    echo ""
    info "Full debug log saved to:"
    echo "  $LOG_FILE"
    echo ""

    # Recommendations
    if [[ ${#ISSUES[@]} -gt 0 ]]; then
        echo -e "${BOLD}Recommended Actions:${RESET}"

        # Check for workspace issues
        if printf '%s\n' "${ISSUES[@]}" | grep -qi "workspace"; then
            echo "  1. Initialize workspace: ./aiwb chat"
        fi

        # Check for model issues
        if printf '%s\n' "${ISSUES[@]}" | grep -qi "deprecated\|model"; then
            echo "  2. Update model: ./aiwb settings"
        fi

        # Check for API key issues
        if printf '%s\n' "${ISSUES[@]}" | grep -qi "api\|key"; then
            echo "  3. Configure API keys: ./aiwb keys"
        fi

        echo ""
    fi

    info "Exiting debug console..."

    # Ensure clean exit - kill any background processes
    jobs -p | xargs -r kill 2>/dev/null || true

    # Exit cleanly
    exit 0
}

# Run main with clean exit
main "$@"

# Ensure we exit even if main fails
exit 0
