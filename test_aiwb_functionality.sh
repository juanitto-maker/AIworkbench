#!/usr/bin/env bash
# Comprehensive AIWB Functionality Test Script
# Tests all providers, models, chat mode, and /make mode
# Generates detailed logs for debugging

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/aiwb_test_results_$(date +%Y%m%d_%H%M%S).log"
SUMMARY_FILE="$SCRIPT_DIR/aiwb_test_summary_$(date +%Y%m%d_%H%M%S).txt"
TIMEOUT_SECONDS=60

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Arrays to track results
declare -a FAILED_DETAILS
declare -a PASSED_DETAILS
declare -a SKIPPED_DETAILS

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_header() {
    local text="$1"
    echo "" | tee -a "$LOG_FILE"
    echo "========================================================================" | tee -a "$LOG_FILE"
    echo "$text" | tee -a "$LOG_FILE"
    echo "========================================================================" | tee -a "$LOG_FILE"
}

log_section() {
    local text="$1"
    echo "" | tee -a "$LOG_FILE"
    echo "------------------------------------------------------------------------" | tee -a "$LOG_FILE"
    echo "$text" | tee -a "$LOG_FILE"
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

# ============================================================================
# TEST INFRASTRUCTURE
# ============================================================================

test_chat_message() {
    local provider="$1"
    local model="$2"
    local test_name="Chat: $provider/$model"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    # Create a test input file
    local test_input=$(mktemp)
    echo "hi" > "$test_input"
    echo "/exit" >> "$test_input"

    # Capture output and errors
    local output_file=$(mktemp)
    local error_file=$(mktemp)

    log "Running: ./aiwb --provider $provider --model $model chat"
    log "Input: 'hi' then '/exit'"

    # Run with timeout and capture exit code
    set +e
    timeout "$TIMEOUT_SECONDS" "$SCRIPT_DIR/aiwb" --provider "$provider" --model "$model" chat < "$test_input" > "$output_file" 2> "$error_file"
    local exit_code=$?
    set -e

    # Log the output
    log "--- STDOUT ---"
    cat "$output_file" | tee -a "$LOG_FILE"
    log "--- STDERR ---"
    cat "$error_file" | tee -a "$LOG_FILE"
    log "--- EXIT CODE: $exit_code ---"

    # Analyze results
    local output_content=$(cat "$output_file")
    local error_content=$(cat "$error_file")

    # Check for success indicators
    if [[ $exit_code -eq 124 ]]; then
        error "TIMEOUT - Test exceeded ${TIMEOUT_SECONDS}s"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: TIMEOUT")
    elif echo "$error_content" | grep -qi "error\|failed\|exception\|404\|401\|403\|500"; then
        error "FAILED - API Error detected"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: API Error - $(echo "$error_content" | grep -i error | head -1)")
    elif echo "$output_content" | grep -qi "error\|failed\|unknown command"; then
        error "FAILED - Error in output"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: Output Error")
    elif [[ $exit_code -ne 0 ]] && [[ $exit_code -ne 130 ]]; then
        error "FAILED - Non-zero exit code: $exit_code"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: Exit code $exit_code")
    else
        success "PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_DETAILS+=("$test_name")
    fi

    # Cleanup
    rm -f "$test_input" "$output_file" "$error_file"
}

test_make_mode() {
    local provider="$1"
    local model="$2"
    local test_name="Make: $provider/$model"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    # Create a test input file for /make mode
    local test_input=$(mktemp)
    cat > "$test_input" <<'EOF'
prompt "Create a bash function that prints hello world"
run
y
exit
/exit
yes
EOF

    # Capture output and errors
    local output_file=$(mktemp)
    local error_file=$(mktemp)

    log "Running: ./aiwb --provider $provider --model $model chat, then entering /make mode"
    log "Input: prompt + run command"

    # Run with timeout
    set +e
    timeout "$TIMEOUT_SECONDS" "$SCRIPT_DIR/aiwb" --provider "$provider" --model "$model" chat < "$test_input" > "$output_file" 2> "$error_file"
    local exit_code=$?
    set -e

    # Log the output
    log "--- STDOUT ---"
    cat "$output_file" | tee -a "$LOG_FILE"
    log "--- STDERR ---"
    cat "$error_file" | tee -a "$LOG_FILE"
    log "--- EXIT CODE: $exit_code ---"

    # Analyze results
    local output_content=$(cat "$output_file")
    local error_content=$(cat "$error_file")

    # Check for success indicators
    if [[ $exit_code -eq 124 ]]; then
        error "TIMEOUT - Test exceeded ${TIMEOUT_SECONDS}s"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: TIMEOUT")
    elif echo "$error_content" | grep -qi "error\|failed\|exception\|404\|401\|403\|500"; then
        error "FAILED - API Error detected"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: API Error - $(echo "$error_content" | grep -i error | head -1)")
    elif echo "$output_content" | grep -qi "error.*api\|failed.*api\|unknown command"; then
        error "FAILED - Error in output"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: Output Error")
    elif [[ $exit_code -ne 0 ]] && [[ $exit_code -ne 130 ]]; then
        error "FAILED - Non-zero exit code: $exit_code"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: Exit code $exit_code")
    else
        success "PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_DETAILS+=("$test_name")
    fi

    # Cleanup
    rm -f "$test_input" "$output_file" "$error_file"
}

check_api_key() {
    local provider="$1"

    case "$provider" in
        gemini)
            [[ -n "${GEMINI_API_KEY:-}" ]]
            ;;
        claude)
            [[ -n "${ANTHROPIC_API_KEY:-}" ]]
            ;;
        openai)
            [[ -n "${OPENAI_API_KEY:-}" ]]
            ;;
        groq)
            [[ -n "${GROQ_API_KEY:-}" ]]
            ;;
        xai)
            [[ -n "${XAI_API_KEY:-}" ]]
            ;;
        ollama)
            # Ollama doesn't need API key, just check if it's running
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

get_models_for_provider() {
    local provider="$1"

    case "$provider" in
        gemini)
            echo "2.5-flash 2.0-flash"
            ;;
        claude)
            echo "3-haiku-20240307 3-5-sonnet-20241022"
            ;;
        openai)
            echo "gpt-4o-mini gpt-4o"
            ;;
        groq)
            echo "llama-3.3-70b-versatile llama-3.2-3b-preview"
            ;;
        xai)
            echo "grok-beta grok-2"
            ;;
        ollama)
            echo "llama3.2:latest"
            ;;
        *)
            echo ""
            ;;
    esac
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
    log_header "AIWB COMPREHENSIVE FUNCTIONALITY TEST"
    log "Script: $0"
    log "Log file: $LOG_FILE"
    log "Summary file: $SUMMARY_FILE"
    log "Date: $(date)"
    log "AIWB Version: $(cd "$SCRIPT_DIR" && ./aiwb --version 2>&1 || echo 'Unknown')"

    # Check which providers have API keys
    log_section "Checking API Keys"

    local providers_to_test=()

    for provider in gemini claude openai groq xai ollama; do
        if check_api_key "$provider"; then
            success "$provider: API key found"
            providers_to_test+=("$provider")
        else
            warn "$provider: No API key found - SKIPPING"
            SKIPPED_DETAILS+=("All $provider tests: No API key")
        fi
    done

    if [[ ${#providers_to_test[@]} -eq 0 ]]; then
        error "No API keys found! Please set at least one API key:"
        echo "  export GEMINI_API_KEY='your-key'"
        echo "  export ANTHROPIC_API_KEY='your-key'"
        echo "  export OPENAI_API_KEY='your-key'"
        echo "  export GROQ_API_KEY='your-key'"
        echo "  export XAI_API_KEY='your-key'"
        exit 1
    fi

    # Test each provider
    for provider in "${providers_to_test[@]}"; do
        log_header "TESTING PROVIDER: $provider"

        local models=$(get_models_for_provider "$provider")

        for model in $models; do
            info "Testing model: $model"

            # Test chat mode
            test_chat_message "$provider" "$model"

            # Test make mode
            test_make_mode "$provider" "$model"

            # Add small delay between tests
            sleep 2
        done
    done

    # Generate summary
    generate_summary

    # Display results
    display_results
}

generate_summary() {
    log_header "GENERATING SUMMARY"

    {
        echo "=========================================================================="
        echo "AIWB FUNCTIONALITY TEST SUMMARY"
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
        echo "Skipped:      ${#SKIPPED_DETAILS[@]}"
        echo ""

        if [[ ${#PASSED_DETAILS[@]} -gt 0 ]]; then
            echo "=========================================================================="
            echo "PASSED TESTS (${#PASSED_DETAILS[@]})"
            echo "=========================================================================="
            for detail in "${PASSED_DETAILS[@]}"; do
                echo "  ✓ $detail"
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

        if [[ ${#SKIPPED_DETAILS[@]} -gt 0 ]]; then
            echo "=========================================================================="
            echo "SKIPPED TESTS (${#SKIPPED_DETAILS[@]})"
            echo "=========================================================================="
            for detail in "${SKIPPED_DETAILS[@]}"; do
                echo "  ○ $detail"
            done
            echo ""
        fi

        echo "=========================================================================="
        echo "DETAILED LOGS"
        echo "=========================================================================="
        echo ""
        echo "Full log file: $LOG_FILE"
        echo ""
        echo "To share with Claude, copy/paste the contents of:"
        echo "  $LOG_FILE"
        echo ""
        echo "Or run: cat $LOG_FILE"
        echo ""
    } > "$SUMMARY_FILE"

    log "Summary written to: $SUMMARY_FILE"
}

display_results() {
    echo ""
    echo ""
    echo -e "${BOLD}${CYAN}=========================================================================="
    echo "TEST EXECUTION COMPLETE"
    echo -e "==========================================================================${RESET}"
    echo ""

    # Display summary
    cat "$SUMMARY_FILE"

    echo ""
    echo -e "${BOLD}Next Steps:${RESET}"
    echo "1. Review the summary above"
    echo "2. Check detailed logs: cat $LOG_FILE"
    echo "3. Copy/paste the log contents to Claude for analysis"
    echo ""
    echo -e "${YELLOW}Command to view full logs:${RESET}"
    echo "  cat $LOG_FILE"
    echo ""
    echo -e "${YELLOW}Command to copy to clipboard (if available):${RESET}"
    echo "  cat $LOG_FILE | xclip -selection clipboard    # Linux"
    echo "  cat $LOG_FILE | pbcopy                        # macOS"
    echo "  cat $LOG_FILE | termux-clipboard-set          # Termux"
    echo ""
}

# ============================================================================
# RUN TESTS
# ============================================================================

main "$@"
