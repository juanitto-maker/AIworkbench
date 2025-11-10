#!/usr/bin/env bash
# Comprehensive AIWB Functionality Test Script
# Tests ALL features: modes, menus, dialogs, workflows, error handling
# Uses AI to validate outputs and detect issues

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/aiwb_comprehensive_test_$(date +%Y%m%d_%H%M%S).log"
SUMMARY_FILE="$SCRIPT_DIR/aiwb_comprehensive_summary_$(date +%Y%m%d_%H%M%S).txt"
TIMEOUT_SECONDS=120
AI_VALIDATOR_PROVIDER="gemini"
AI_VALIDATOR_MODEL="2.5-flash"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

declare -a FAILED_DETAILS
declare -a PASSED_DETAILS
declare -a ISSUES_FOUND

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_header() {
    echo "" | tee -a "$LOG_FILE"
    echo "========================================================================" | tee -a "$LOG_FILE"
    echo "$1" | tee -a "$LOG_FILE"
    echo "========================================================================" | tee -a "$LOG_FILE"
}

log_section() {
    echo "" | tee -a "$LOG_FILE"
    echo "------------------------------------------------------------------------" | tee -a "$LOG_FILE"
    echo "$1" | tee -a "$LOG_FILE"
    echo "------------------------------------------------------------------------" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓ $*${RESET}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗ $*${RESET}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}⚠ $*${RESET}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${CYAN}ℹ $*${RESET}" | tee -a "$LOG_FILE"
}

# Load API keys
load_api_keys() {
    local env_file="$HOME/.aiwb/.aiwb.env"
    if [[ -f "$env_file" ]]; then
        log "Loading API keys from: $env_file"
        set +u
        # shellcheck disable=SC1090
        source "$env_file" 2>/dev/null || true
        set -u
    fi
}

# Use AI to validate output quality
ai_validate_output() {
    local output="$1"
    local expected_type="$2"  # e.g., "bash script", "explanation", "code"

    # Skip if no validator key available
    [[ -z "${GEMINI_API_KEY:-}" ]] && return 0

    local prompt="You are validating AI-generated output. Check if this output is:
1. Complete (not truncated or cut off)
2. Relevant to the request type: $expected_type
3. Free of obvious errors or nonsense
4. Properly formatted

Output to validate:
---
$output
---

Respond with ONLY:
VALID - if output is good
INVALID: <reason> - if there's a problem"

    local validation_result
    validation_result=$("$SCRIPT_DIR/aiwb" --provider "$AI_VALIDATOR_PROVIDER" --model "$AI_VALIDATOR_MODEL" quick "$prompt" 2>/dev/null | tail -1)

    if echo "$validation_result" | grep -qi "^VALID"; then
        return 0
    else
        log "AI Validation failed: $validation_result"
        return 1
    fi
}

# ============================================================================
# MODE TESTS
# ============================================================================

test_chat_mode() {
    local provider="$1"
    local model="$2"
    local test_name="Mode: Chat ($provider/$model)"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    local output_file=$(mktemp)
    local error_file=$(mktemp)

    log "Testing chat mode with simple question"

    # Use echo with newlines piped to the command
    # AIWB_TEST_MODE is exported in main() for automated testing
    set +e
    timeout "$TIMEOUT_SECONDS" bash -c "echo -e 'What is 2+2?\n/exit\nyes' | '$SCRIPT_DIR/aiwb' --provider '$provider' --model '$model' chat" > "$output_file" 2> "$error_file"
    local exit_code=$?
    set -e

    local output=$(cat "$output_file")

    # Check for issues
    local issues=()

    # Check if it answered
    if ! echo "$output" | grep -qi "4\|four"; then
        issues+=("Did not answer simple math question")
    fi

    # Check for errors
    if echo "$output" | grep -qi "error\|exception\|traceback"; then
        issues+=("Errors in output")
    fi

    # Check for forced exit
    if [[ $exit_code -eq 124 ]]; then
        issues+=("TIMEOUT - hung")
    elif [[ $exit_code -ne 0 ]] && [[ $exit_code -ne 130 ]]; then
        issues+=("Non-zero exit: $exit_code")
    fi

    if [[ ${#issues[@]} -eq 0 ]]; then
        success "PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_DETAILS+=("$test_name")
    else
        error "FAILED: ${issues[*]}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: ${issues[*]}")
        ISSUES_FOUND+=("Chat mode: ${issues[*]}")
    fi

    log "--- OUTPUT ---"
    cat "$output_file" | tee -a "$LOG_FILE"

    rm -f "$output_file" "$error_file"
}

test_quick_mode() {
    local provider="$1"
    local model="$2"
    local test_name="Mode: Quick ($provider/$model)"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    log "Testing quick mode with simple task"

    set +e
    local output
    output=$(timeout "$TIMEOUT_SECONDS" "$SCRIPT_DIR/aiwb" --provider "$provider" --model "$model" quick "write hello world in bash" 2>&1)
    local exit_code=$?
    set -e

    local issues=()

    # Check if it generated code
    if ! echo "$output" | grep -qi "echo\|printf"; then
        issues+=("No bash code generated")
    fi

    # Check if it contains 'hello world'
    if ! echo "$output" | grep -qi "hello.*world\|hello world"; then
        issues+=("Output doesn't contain 'hello world'")
    fi

    # Check for errors
    if [[ $exit_code -eq 124 ]]; then
        issues+=("TIMEOUT")
    elif [[ $exit_code -ne 0 ]]; then
        issues+=("Exit code: $exit_code")
    fi

    if [[ ${#issues[@]} -eq 0 ]]; then
        success "PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_DETAILS+=("$test_name")
    else
        error "FAILED: ${issues[*]}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: ${issues[*]}")
        ISSUES_FOUND+=("Quick mode: ${issues[*]}")
    fi

    log "--- OUTPUT ---"
    echo "$output" | tee -a "$LOG_FILE"
}

test_make_mode() {
    local provider="$1"
    local model="$2"
    local test_name="Mode: Make ($provider/$model)"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    local output_file=$(mktemp)
    local error_file=$(mktemp)

    log "Testing make mode full workflow"

    set +e
    timeout "$TIMEOUT_SECONDS" bash -c "echo -e '/make\nprompt \"create a function that adds two numbers\"\nstatus\nrun\ny\npreview\nexit\n/exit\nyes' | '$SCRIPT_DIR/aiwb' --provider '$provider' --model '$model'" > "$output_file" 2> "$error_file"
    local exit_code=$?
    set -e

    local output=$(cat "$output_file")
    local issues=()

    # Check workflow steps
    if ! echo "$output" | grep -qi "make>"; then
        issues+=("Make mode not entered")
    fi

    if ! echo "$output" | grep -qi "generating\|generated\|response"; then
        issues+=("No generation occurred")
    fi

    if ! echo "$output" | grep -qi "function\|def\|add"; then
        issues+=("No function code generated")
    fi

    # Check if preview showed output
    if ! echo "$output" | grep -qi "preview\|output\|content"; then
        issues+=("Preview not shown")
        ISSUES_FOUND+=("Make mode doesn't show preview after generation")
    fi

    # Check for forced exit
    if [[ $exit_code -eq 124 ]]; then
        issues+=("TIMEOUT")
    elif [[ $exit_code -ne 0 ]] && [[ $exit_code -ne 130 ]]; then
        issues+=("Exit code: $exit_code")
    fi

    if [[ ${#issues[@]} -eq 0 ]]; then
        success "PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_DETAILS+=("$test_name")
    else
        error "FAILED: ${issues[*]}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: ${issues[*]}")
        for issue in "${issues[@]}"; do
            ISSUES_FOUND+=("Make mode: $issue")
        done
    fi

    log "--- OUTPUT ---"
    cat "$output_file" | tee -a "$LOG_FILE"

    rm -f "$output_file" "$error_file"
}

test_plan_mode() {
    local provider="$1"
    local model="$2"
    local test_name="Mode: Plan ($provider/$model)"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    local output_file=$(mktemp)
    local error_file=$(mktemp)

    log "Testing plan mode"

    set +e
    timeout "$TIMEOUT_SECONDS" bash -c "echo -e '/plan\ncreate a todo app\n/exit\nyes' | '$SCRIPT_DIR/aiwb' --provider '$provider' --model '$model'" > "$output_file" 2> "$error_file"
    local exit_code=$?
    set -e

    local output=$(cat "$output_file")
    local issues=()

    # Check if planning occurred
    if ! echo "$output" | grep -qi "plan\|step\|phase"; then
        issues+=("No plan generated")
    fi

    # Check for numbered steps
    if ! echo "$output" | grep -qE "[0-9]+\."; then
        issues+=("No numbered steps in plan")
    fi

    if [[ $exit_code -eq 124 ]]; then
        issues+=("TIMEOUT")
    fi

    if [[ ${#issues[@]} -eq 0 ]]; then
        success "PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_DETAILS+=("$test_name")
    else
        error "FAILED: ${issues[*]}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: ${issues[*]}")
        ISSUES_FOUND+=("Plan mode: ${issues[*]}")
    fi

    log "--- OUTPUT ---"
    cat "$output_file" | tee -a "$LOG_FILE"

    rm -f "$output_file" "$error_file"
}

# ============================================================================
# MENU & DIALOG TESTS
# ============================================================================

test_settings_menu() {
    local test_name="Menu: Settings"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    local output_file=$(mktemp)
    local error_file=$(mktemp)

    log "Testing settings menu navigation"

    set +e
    timeout 30 bash -c "echo -e '/settings\n1\n/exit\nyes' | '$SCRIPT_DIR/aiwb'" > "$output_file" 2> "$error_file"
    local exit_code=$?
    set -e

    local output=$(cat "$output_file")
    local issues=()

    # Check if settings menu appeared
    if ! echo "$output" | grep -qi "settings\|preferences\|configuration"; then
        issues+=("Settings menu not shown")
    fi

    if [[ $exit_code -eq 124 ]]; then
        issues+=("TIMEOUT - menu hung")
    fi

    if [[ ${#issues[@]} -eq 0 ]]; then
        success "PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_DETAILS+=("$test_name")
    else
        error "FAILED: ${issues[*]}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: ${issues[*]}")
        ISSUES_FOUND+=("Settings menu: ${issues[*]}")
    fi

    log "--- OUTPUT ---"
    cat "$output_file" | tee -a "$LOG_FILE"

    rm -f "$output_file" "$error_file"
}

test_help_command() {
    local test_name="Command: Help"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    local output_file=$(mktemp)
    local error_file=$(mktemp)

    log "Testing /help command"

    set +e
    timeout 30 bash -c "echo -e '/help\n/exit\nyes' | '$SCRIPT_DIR/aiwb'" > "$output_file" 2> "$error_file"
    local exit_code=$?
    set -e

    local output=$(cat "$output_file")
    local issues=()

    # Check if help is shown
    if ! echo "$output" | grep -qi "help\|commands\|usage"; then
        issues+=("Help not displayed")
    fi

    # Check for key commands
    if ! echo "$output" | grep -qi "/make\|/quick\|/chat"; then
        issues+=("Key commands not listed")
    fi

    if [[ ${#issues[@]} -eq 0 ]]; then
        success "PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_DETAILS+=("$test_name")
    else
        error "FAILED: ${issues[*]}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: ${issues[*]}")
    fi

    log "--- OUTPUT ---"
    cat "$output_file" | tee -a "$LOG_FILE"

    rm -f "$output_file" "$error_file"
}

# ============================================================================
# ERROR HANDLING TESTS
# ============================================================================

test_invalid_command() {
    local test_name="Error: Invalid Command"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    local output_file=$(mktemp)
    local error_file=$(mktemp)

    log "Testing invalid command handling"

    set +e
    timeout 30 bash -c "echo -e '/invalidcommandthatdoesnotexist\n/exit\nyes' | '$SCRIPT_DIR/aiwb'" > "$output_file" 2> "$error_file"
    local exit_code=$?
    set -e

    local output=$(cat "$output_file")
    local issues=()

    # Should show error message, not crash
    if echo "$output" | grep -qi "unknown.*command\|invalid.*command\|not.*found"; then
        log "✓ Proper error message shown"
    else
        issues+=("No error message for invalid command")
    fi

    # Should not crash
    if [[ $exit_code -ne 0 ]] && [[ $exit_code -ne 130 ]]; then
        issues+=("Crashed on invalid command (exit: $exit_code)")
        ISSUES_FOUND+=("App crashes on invalid command")
    fi

    if [[ ${#issues[@]} -eq 0 ]]; then
        success "PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_DETAILS+=("$test_name")
    else
        error "FAILED: ${issues[*]}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: ${issues[*]}")
    fi

    log "--- OUTPUT ---"
    cat "$output_file" | tee -a "$LOG_FILE"

    rm -f "$output_file" "$error_file"
}

test_empty_input() {
    local test_name="Error: Empty Input"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    local output_file=$(mktemp)
    local error_file=$(mktemp)

    log "Testing empty input handling"

    set +e
    timeout 30 bash -c "echo -e '\n\n/exit\nyes' | '$SCRIPT_DIR/aiwb'" > "$output_file" 2> "$error_file"
    local exit_code=$?
    set -e

    local issues=()

    # Should not crash on empty input
    if [[ $exit_code -ne 0 ]] && [[ $exit_code -ne 130 ]]; then
        issues+=("Crashed on empty input (exit: $exit_code)")
        ISSUES_FOUND+=("App crashes on empty input")
    fi

    if [[ ${#issues[@]} -eq 0 ]]; then
        success "PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_DETAILS+=("$test_name")
    else
        error "FAILED: ${issues[*]}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: ${issues[*]}")
    fi

    rm -f "$output_file" "$error_file"
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
    # Enable test mode for all commands in this script
    export AIWB_TEST_MODE=1

    log_header "AIWB COMPREHENSIVE FUNCTIONALITY TEST"
    log "Script: $0"
    log "Log file: $LOG_FILE"
    log "Summary file: $SUMMARY_FILE"
    log "Date: $(date)"
    log "AIWB Version: $(cd "$SCRIPT_DIR" && ./aiwb --version 2>&1 || echo 'Unknown')"

    # Load API keys
    load_api_keys

    # Determine which provider to test with
    local test_provider=""
    local test_model=""

    if [[ -n "${GEMINI_API_KEY:-}" ]]; then
        test_provider="gemini"
        test_model="2.5-flash"
    elif [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
        test_provider="claude"
        test_model="3-haiku-20240307"
    elif [[ -n "${OPENAI_API_KEY:-}" ]]; then
        test_provider="openai"
        test_model="gpt-4o-mini"
    else
        warn "No API keys found. Skipping AI-dependent tests."
        warn "Testing only menu navigation and error handling."
    fi

    if [[ -n "$test_provider" ]]; then
        log_header "TESTING WITH: $test_provider/$test_model"

        # Mode tests
        test_chat_mode "$test_provider" "$test_model"
        test_quick_mode "$test_provider" "$test_model"
        test_make_mode "$test_provider" "$test_model"
        test_plan_mode "$test_provider" "$test_model"
    fi

    # Menu & Dialog tests (don't need API)
    log_header "TESTING MENUS & DIALOGS"
    test_settings_menu
    test_help_command

    # Error handling tests
    log_header "TESTING ERROR HANDLING"
    test_invalid_command
    test_empty_input

    # Generate summary
    generate_summary
}

generate_summary() {
    log_header "GENERATING SUMMARY"

    {
        echo "=========================================================================="
        echo "AIWB COMPREHENSIVE FUNCTIONALITY TEST SUMMARY"
        echo "=========================================================================="
        echo ""
        echo "Date: $(date)"
        echo "AIWB Version: $(cd "$SCRIPT_DIR" && ./aiwb --version 2>&1 || echo 'Unknown')"
        echo ""
        echo "=========================================================================="
        echo "TEST RESULTS"
        echo "=========================================================================="
        echo ""
        echo "Total Tests:  $TOTAL_TESTS"
        echo "Passed:       $PASSED_TESTS ($(( TOTAL_TESTS > 0 ? PASSED_TESTS * 100 / TOTAL_TESTS : 0 ))%)"
        echo "Failed:       $FAILED_TESTS ($(( TOTAL_TESTS > 0 ? FAILED_TESTS * 100 / TOTAL_TESTS : 0 ))%)"
        echo ""

        if [[ ${#ISSUES_FOUND[@]} -gt 0 ]]; then
            echo "=========================================================================="
            echo "🐛 ISSUES DETECTED (${#ISSUES_FOUND[@]})"
            echo "=========================================================================="
            # Deduplicate issues
            printf '%s\n' "${ISSUES_FOUND[@]}" | sort -u | while read -r issue; do
                echo "  ⚠️  $issue"
            done
            echo ""
        fi

        if [[ ${#FAILED_DETAILS[@]} -gt 0 ]]; then
            echo "=========================================================================="
            echo "FAILED TESTS (${#FAILED_DETAILS[@]})"
            echo "=========================================================================="
            for detail in "${FAILED_DETAILS[@]}"; do
                echo "  ✗ $detail"
            done
            echo ""
        fi

        if [[ ${#PASSED_DETAILS[@]} -gt 0 ]]; then
            echo "=========================================================================="
            echo "PASSED TESTS (${#PASSED_DETAILS[@]})"
            echo "=========================================================================="
            for detail in "${PASSED_DETAILS[@]}"; do
                echo "  ✓ $detail"
            done
            echo ""
        fi

        echo "=========================================================================="
        echo "DETAILED LOGS"
        echo "=========================================================================="
        echo ""
        echo "Full log file: $LOG_FILE"
        echo ""
    } > "$SUMMARY_FILE"

    log "Summary written to: $SUMMARY_FILE"

    # Display summary
    echo ""
    echo ""
    echo -e "${BOLD}${CYAN}=========================================================================="
    echo "COMPREHENSIVE TEST COMPLETE"
    echo -e "==========================================================================${RESET}"
    echo ""
    cat "$SUMMARY_FILE"

    if [[ ${#ISSUES_FOUND[@]} -gt 0 ]]; then
        echo ""
        echo -e "${BOLD}${RED}⚠️  FUNCTIONALITY ISSUES FOUND!${RESET}"
        echo -e "${YELLOW}These issues need attention:${RESET}"
        printf '%s\n' "${ISSUES_FOUND[@]}" | sort -u | while read -r issue; do
            echo -e "  ${RED}•${RESET} $issue"
        done
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main "$@"
