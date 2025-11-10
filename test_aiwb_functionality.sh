#!/usr/bin/env bash
# Comprehensive AIWB Functionality Test Script
# Tests: APIs, workspace functionality, dialogs, output handling, mode behavior
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
declare -a WORKSPACE_ISSUES

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
# WORKSPACE FUNCTIONALITY TESTS
# ============================================================================

test_workspace_structure() {
    local test_name="Workspace: Structure Creation"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    # Run aiwb to initialize workspace
    timeout 5 "$SCRIPT_DIR/aiwb" --version >/dev/null 2>&1 || true

    local workspace="$HOME/.aiwb/workspace"
    local config="$HOME/.aiwb/config.json"

    # Check workspace directories
    local required_dirs=(
        "$workspace"
        "$workspace/projects"
        "$workspace/tasks"
        "$workspace/snapshots"
        "$workspace/logs"
        "$workspace/templates"
        "$workspace/history"
    )

    local all_exist=true
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log "  ✓ Directory exists: $dir"
        else
            log "  ✗ Missing directory: $dir"
            all_exist=false
            WORKSPACE_ISSUES+=("Missing directory: $dir")
        fi
    done

    # Check config file
    if [[ -f "$config" ]]; then
        log "  ✓ Config file exists: $config"
        log "  Config contents:"
        cat "$config" | tee -a "$LOG_FILE"
    else
        log "  ✗ Config file missing: $config"
        all_exist=false
        WORKSPACE_ISSUES+=("Config file missing")
    fi

    if $all_exist; then
        success "PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_DETAILS+=("$test_name")
    else
        error "FAILED - Workspace structure incomplete"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: Incomplete structure")
    fi
}

test_output_file_creation() {
    local provider="$1"
    local model="$2"
    local test_name="Workspace: Output File Creation ($provider/$model)"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    local workspace="$HOME/.aiwb/workspace"
    local outputs_dir="$workspace/outputs"

    # Count existing outputs
    local before_count=0
    if [[ -d "$outputs_dir" ]]; then
        before_count=$(find "$outputs_dir" -type f -name "*.md" 2>/dev/null | wc -l)
    fi
    log "Output files before test: $before_count"

    # Create a test using quick command (simpler than make mode)
    local test_input=$(mktemp)
    cat > "$test_input" <<'EOF'
y
EOF

    local output_file=$(mktemp)
    local error_file=$(mktemp)

    log "Running: ./aiwb quick 'write hello world in bash' --provider $provider --model $model"

    set +e
    timeout "$TIMEOUT_SECONDS" "$SCRIPT_DIR/aiwb" --provider "$provider" --model "$model" quick "write hello world in bash" < "$test_input" > "$output_file" 2> "$error_file"
    local exit_code=$?
    set -e

    # Count outputs after
    local after_count=0
    if [[ -d "$outputs_dir" ]]; then
        after_count=$(find "$outputs_dir" -type f -name "*.md" 2>/dev/null | wc -l)
    fi
    log "Output files after test: $after_count"

    # Check if new file was created
    if [[ $after_count -gt $before_count ]]; then
        success "PASSED - New output file created"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_DETAILS+=("$test_name")

        # Log the newest file
        local newest=$(find "$outputs_dir" -type f -name "*.md" 2>/dev/null | sort -r | head -1)
        if [[ -n "$newest" ]]; then
            log "Newest output file: $newest"
            log "File size: $(stat -c%s "$newest" 2>/dev/null || stat -f%z "$newest" 2>/dev/null) bytes"
        fi
    else
        error "FAILED - No output file created"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: No file created")
        WORKSPACE_ISSUES+=("Output files not being saved to workspace")

        # Log what happened
        log "--- STDOUT ---"
        cat "$output_file" | tee -a "$LOG_FILE"
        log "--- STDERR ---"
        cat "$error_file" | tee -a "$LOG_FILE"
    fi

    rm -f "$test_input" "$output_file" "$error_file"
}

test_make_mode_workflow() {
    local provider="$1"
    local model="$2"
    local test_name="Workflow: Make Mode Full Flow ($provider/$model)"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    # Test the full make mode workflow
    local test_input=$(mktemp)
    cat > "$test_input" <<'EOF'
/make
prompt "create a simple bash hello world function"
status
run
y
exit
/exit
yes
EOF

    local output_file=$(mktemp)
    local error_file=$(mktemp)

    log "Testing full /make workflow with status check"

    set +e
    timeout "$TIMEOUT_SECONDS" "$SCRIPT_DIR/aiwb" --provider "$provider" --model "$model" < "$test_input" > "$output_file" 2> "$error_file"
    local exit_code=$?
    set -e

    local output_content=$(cat "$output_file")
    local error_content=$(cat "$error_file")

    log "--- STDOUT ---"
    cat "$output_file" | tee -a "$LOG_FILE"
    log "--- STDERR ---"
    cat "$error_file" | tee -a "$LOG_FILE"
    log "--- EXIT CODE: $exit_code ---"

    # Check workflow steps
    local workflow_ok=true
    local issues=()

    # Check if make mode was entered
    if echo "$output_content" | grep -qi "make>"; then
        log "  ✓ Make mode entered successfully"
    else
        log "  ✗ Make mode not entered"
        workflow_ok=false
        issues+=("Make mode not entered")
    fi

    # Check if status command worked
    if echo "$output_content" | grep -qi "status\|instruction\|model"; then
        log "  ✓ Status command worked"
    else
        log "  ⚠ Status command may not have worked"
        issues+=("Status unclear")
    fi

    # Check if generation happened
    if echo "$output_content" | grep -qi "generating\|generated\|response"; then
        log "  ✓ Generation appeared to occur"
    else
        log "  ✗ No evidence of generation"
        workflow_ok=false
        issues+=("No generation detected")
    fi

    # Check for premature exit
    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 130 ]]; then
        log "  ✓ Clean exit"
    else
        log "  ⚠ Unusual exit code: $exit_code"
        issues+=("Exit code: $exit_code")
    fi

    # Check if output was shown (the key issue!)
    if echo "$output_content" | grep -qi "preview\|output\|result\|content:"; then
        log "  ✓ Output appears to be displayed"
    else
        log "  ✗ OUTPUT NOT DISPLAYED - This might be the bug!"
        workflow_ok=false
        issues+=("Output not displayed after generation")
        WORKSPACE_ISSUES+=("Make mode doesn't show output after generation")
    fi

    if $workflow_ok; then
        success "PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_DETAILS+=("$test_name")
    else
        error "FAILED - Workflow issues: ${issues[*]}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: ${issues[*]}")
    fi

    rm -f "$test_input" "$output_file" "$error_file"
}

test_cost_tracking() {
    local test_name="Workspace: Cost Tracking"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    local workspace="$HOME/.aiwb/workspace"
    local usage_log="$workspace/logs/usage.jsonl"

    if [[ -f "$usage_log" ]]; then
        log "✓ Usage log exists: $usage_log"
        log "Usage log contents (last 5 entries):"
        tail -5 "$usage_log" | tee -a "$LOG_FILE"

        # Check if it's valid JSON
        if tail -1 "$usage_log" | jq -e . >/dev/null 2>&1; then
            log "  ✓ Usage log contains valid JSON"
            success "PASSED"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            PASSED_DETAILS+=("$test_name")
        else
            log "  ✗ Usage log has invalid JSON"
            error "FAILED - Invalid JSON in usage log"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            FAILED_DETAILS+=("$test_name: Invalid JSON")
        fi
    else
        warn "Usage log not created yet (may be normal for first run)"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        SKIPPED_DETAILS+=("$test_name: No usage data yet")
    fi
}

test_chat_history() {
    local test_name="Workspace: Chat History Logging"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    local workspace="$HOME/.aiwb/workspace"
    local logs_dir="$workspace/logs"

    if [[ -d "$logs_dir" ]]; then
        local chat_logs=$(find "$logs_dir" -name "chat_*.log" 2>/dev/null | wc -l)
        log "Chat log files found: $chat_logs"

        if [[ $chat_logs -gt 0 ]]; then
            log "✓ Chat history is being logged"
            local newest=$(find "$logs_dir" -name "chat_*.log" 2>/dev/null | sort -r | head -1)
            log "Newest log: $newest"
            log "Last 10 lines:"
            tail -10 "$newest" | tee -a "$LOG_FILE"

            success "PASSED"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            PASSED_DETAILS+=("$test_name")
        else
            warn "No chat logs created yet"
            SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
            SKIPPED_DETAILS+=("$test_name: No logs yet")
        fi
    else
        error "FAILED - Logs directory doesn't exist"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: No logs directory")
    fi
}

# ============================================================================
# API FUNCTIONALITY TESTS
# ============================================================================

test_chat_message() {
    local provider="$1"
    local model="$2"
    local test_name="API: Chat ($provider/$model)"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_section "TEST $TOTAL_TESTS: $test_name"

    # Create a test input file
    local test_input=$(mktemp)
    cat > "$test_input" <<'EOF'
hi
/exit
yes
EOF

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
        local err_msg=$(echo "$error_content" | grep -i error | head -1)
        FAILED_DETAILS+=("$test_name: $err_msg")
    elif echo "$output_content" | grep -qi "error.*api\|failed.*api\|unknown command\|model.*not.*found"; then
        error "FAILED - Error in output"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_DETAILS+=("$test_name: Output error")
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

    # ========================================================================
    # PHASE 1: WORKSPACE TESTS (No API keys needed)
    # ========================================================================
    log_header "PHASE 1: WORKSPACE FUNCTIONALITY TESTS"

    test_workspace_structure
    test_cost_tracking
    test_chat_history

    # ========================================================================
    # PHASE 2: API & WORKFLOW TESTS (Needs API keys)
    # ========================================================================
    log_header "PHASE 2: API & WORKFLOW TESTS"

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
        warn "No API keys found! Skipping API tests."
        warn "Workspace tests completed, but API tests require keys."
        echo ""
        echo "To test APIs, set at least one API key:"
        echo "  export GEMINI_API_KEY='your-key'"
        echo "  export ANTHROPIC_API_KEY='your-key'"
        echo "  export OPENAI_API_KEY='your-key'"
        echo "  export GROQ_API_KEY='your-key'"
        echo "  export XAI_API_KEY='your-key'"
    else
        # Test each provider
        for provider in "${providers_to_test[@]}"; do
            log_header "TESTING PROVIDER: $provider"

            local models=$(get_models_for_provider "$provider")
            local model_array=($models)
            local first_model="${model_array[0]}"

            # For efficiency, only test first model for each provider
            # But do comprehensive workflow tests
            info "Testing with model: $first_model"

            # API test
            test_chat_message "$provider" "$first_model"

            # Workflow test (the important one!)
            test_make_mode_workflow "$provider" "$first_model"

            # Output file creation test
            test_output_file_creation "$provider" "$first_model"

            # Add small delay between providers
            sleep 2
        done
    fi

    # ========================================================================
    # PHASE 3: SUMMARY & ANALYSIS
    # ========================================================================
    generate_summary
    display_results
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
        echo "Skipped:      ${#SKIPPED_DETAILS[@]}"
        echo ""

        if [[ ${#WORKSPACE_ISSUES[@]} -gt 0 ]]; then
            echo "=========================================================================="
            echo "🐛 WORKSPACE ISSUES DETECTED (${#WORKSPACE_ISSUES[@]})"
            echo "=========================================================================="
            for issue in "${WORKSPACE_ISSUES[@]}"; do
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
        echo "  cat $LOG_FILE"
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

    if [[ ${#WORKSPACE_ISSUES[@]} -gt 0 ]]; then
        echo ""
        echo -e "${BOLD}${RED}⚠️  WORKSPACE ISSUES FOUND!${RESET}"
        echo -e "${YELLOW}These are likely the bugs causing your problems:${RESET}"
        for issue in "${WORKSPACE_ISSUES[@]}"; do
            echo -e "  ${RED}•${RESET} $issue"
        done
    fi

    echo ""
    echo -e "${BOLD}Next Steps:${RESET}"
    echo "1. Review the summary above"
    echo "2. Check detailed logs: cat $LOG_FILE"
    echo "3. Copy/paste the log contents to Claude for analysis"
    echo ""
    echo -e "${YELLOW}Command to view full logs:${RESET}"
    echo "  cat $LOG_FILE"
    echo ""
}

# ============================================================================
# RUN TESTS
# ============================================================================

main "$@"
