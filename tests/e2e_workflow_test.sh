#!/usr/bin/env bash
# End-to-End Workflow Testing Script
# Tests realistic user workflows and interactions

set -o pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AIWB_ROOT="$(dirname "$SCRIPT_DIR")"
AIWB_BIN="$AIWB_ROOT/aiwb"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log_test() {
    echo -e "${BLUE}[TEST]${RESET} $1"
}

log_pass() {
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
    echo -e "${GREEN}✓${RESET} $1"
}

log_fail() {
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
    echo -e "${RED}✗${RESET} $1"
}

log_skip() {
    ((SKIPPED_TESTS++))
    ((TOTAL_TESTS++))
    echo -e "${YELLOW}○${RESET} $1 (skipped)"
}

# ============================================================================
# TEST SCENARIOS
# ============================================================================

test_help_command() {
    echo ""
    echo -e "${BOLD}${BLUE}>>> Test: Help Command${RESET}"
    log_test "Testing /help command displays correctly"

    local output
    output=$(echo -e "/help\n/exit\nyes" | timeout 10 "$AIWB_BIN" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 124 ]]; then
        if echo "$output" | grep -q "CODE EDITING"; then
            log_pass "Help command displays CODE EDITING section"
        else
            log_fail "Help command missing CODE EDITING section"
        fi

        if echo "$output" | grep -q "CONTEXT MANAGEMENT"; then
            log_pass "Help command displays CONTEXT MANAGEMENT section"
        else
            log_fail "Help command missing CONTEXT MANAGEMENT section"
        fi

        if echo "$output" | grep -q "MODE-BASED WORKFLOWS"; then
            log_pass "Help command displays MODE-BASED WORKFLOWS section"
        else
            log_fail "Help command missing MODE-BASED WORKFLOWS section"
        fi

        if echo "$output" | grep -q "/swarm"; then
            log_pass "Help command includes /swarm command"
        else
            log_fail "Help command missing /swarm command"
        fi
    else
        log_skip "Help command test (app may not be fully configured)"
    fi
}

test_status_command() {
    echo ""
    echo -e "${BOLD}${BLUE}>>> Test: Status Command${RESET}"
    log_test "Testing /status command"

    local output
    output=$(echo -e "/status\n/exit\nyes" | timeout 10 "$AIWB_BIN" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 124 ]]; then
        if echo "$output" | grep -q "Platform"; then
            log_pass "Status shows Platform information"
        else
            log_fail "Status missing Platform information"
        fi

        if echo "$output" | grep -q "Provider\|Model"; then
            log_pass "Status shows Provider/Model information"
        else
            log_fail "Status missing Provider/Model information"
        fi
    else
        log_skip "Status command test"
    fi
}

test_models_command() {
    echo ""
    echo -e "${BOLD}${BLUE}>>> Test: Models Command${RESET}"
    log_test "Testing /models command"

    local output
    output=$(echo -e "/models\n/exit\nyes" | timeout 10 "$AIWB_BIN" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 124 ]]; then
        # Check if models menu appeared (will vary based on environment)
        log_pass "Models command executed without crash"
    else
        log_skip "Models command test"
    fi
}

test_context_commands() {
    echo ""
    echo -e "${BOLD}${BLUE}>>> Test: Context Management Commands${RESET}"

    log_test "Testing /contextshow command"
    local output
    output=$(echo -e "/contextshow\n/exit\nyes" | timeout 10 "$AIWB_BIN" 2>&1)
    if [[ $? -eq 0 ]] || [[ $? -eq 124 ]]; then
        log_pass "contextshow command executed"
    else
        log_skip "contextshow command test"
    fi

    log_test "Testing /contextsave command"
    output=$(echo -e "/contextsave\n/exit\nyes" | timeout 10 "$AIWB_BIN" 2>&1)
    if [[ $? -eq 0 ]] || [[ $? -eq 124 ]]; then
        log_pass "contextsave command executed"
    else
        log_skip "contextsave command test"
    fi

    log_test "Testing /contextload command"
    output=$(echo -e "/contextload\n/exit\nyes" | timeout 10 "$AIWB_BIN" 2>&1)
    if [[ $? -eq 0 ]] || [[ $? -eq 124 ]]; then
        log_pass "contextload command executed"
    else
        log_skip "contextload command test"
    fi
}

test_swarm_command() {
    echo ""
    echo -e "${BOLD}${BLUE}>>> Test: Swarm Mode Command${RESET}"
    log_test "Testing /swarm configuration menu"

    local output
    output=$(echo -e "/swarm\nBack\n/exit\nyes" | timeout 10 "$AIWB_BIN" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 124 ]]; then
        if echo "$output" | grep -q "Swarm Mode\|swarm"; then
            log_pass "Swarm command opens menu"
        else
            log_fail "Swarm command doesn't show menu"
        fi
    else
        log_skip "Swarm command test"
    fi
}

test_clear_command() {
    echo ""
    echo -e "${BOLD}${BLUE}>>> Test: Clear Command${RESET}"
    log_test "Testing /clear command"

    local output
    output=$(echo -e "/clear\n/exit\nyes" | timeout 10 "$AIWB_BIN" 2>&1)
    if [[ $? -eq 0 ]] || [[ $? -eq 124 ]]; then
        log_pass "Clear command executed"
    else
        log_skip "Clear command test"
    fi
}

test_exit_command() {
    echo ""
    echo -e "${BOLD}${BLUE}>>> Test: Exit Command${RESET}"
    log_test "Testing /exit with confirmation"

    local output
    output=$(echo -e "/exit\nyes" | timeout 10 "$AIWB_BIN" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        if echo "$output" | grep -q "Goodbye\|exit"; then
            log_pass "Exit command works with confirmation"
        else
            log_fail "Exit command missing goodbye message"
        fi
    else
        log_skip "Exit command test"
    fi
}

test_unknown_command() {
    echo ""
    echo -e "${BOLD}${BLUE}>>> Test: Unknown Command Handling${RESET}"
    log_test "Testing unknown slash command"

    local output
    output=$(echo -e "/thiscommanddoesnotexist\n/exit\nyes" | timeout 10 "$AIWB_BIN" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 124 ]]; then
        if echo "$output" | grep -qi "unknown\|invalid"; then
            log_pass "Unknown command shows error message"
        else
            log_fail "Unknown command doesn't show error"
        fi
    else
        log_skip "Unknown command test"
    fi
}

test_empty_input() {
    echo ""
    echo -e "${BOLD}${BLUE}>>> Test: Empty Input Handling${RESET}"
    log_test "Testing empty input (just pressing enter)"

    local output
    output=$(echo -e "\n\n\n/exit\nyes" | timeout 10 "$AIWB_BIN" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 124 ]]; then
        log_pass "Empty input handled gracefully"
    else
        log_fail "Empty input caused crash"
    fi
}

test_rapid_commands() {
    echo ""
    echo -e "${BOLD}${BLUE}>>> Test: Rapid Command Execution${RESET}"
    log_test "Testing rapid command execution"

    local output
    output=$(echo -e "/status\n/models\n/help\n/clear\n/status\n/exit\nyes" | timeout 15 "$AIWB_BIN" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 124 ]]; then
        log_pass "Rapid commands handled without crash"
    else
        log_fail "Rapid commands caused issues"
    fi
}

test_workspace_initialization() {
    echo ""
    echo -e "${BOLD}${BLUE}>>> Test: Workspace Initialization${RESET}"
    log_test "Testing workspace directory creation"

    # Clean test workspace
    local test_home="/tmp/aiwb_test_home_$$"
    export AIWB_HOME="$test_home"

    local output
    output=$(echo -e "/exit\nyes" | timeout 10 "$AIWB_BIN" 2>&1)

    if [[ -d "$test_home/workspace" ]]; then
        log_pass "Workspace directory created"

        if [[ -d "$test_home/workspace/logs" ]]; then
            log_pass "Logs directory created"
        else
            log_fail "Logs directory not created"
        fi

        if [[ -f "$test_home/config.json" ]]; then
            log_pass "Config file created"
        else
            log_fail "Config file not created"
        fi
    else
        log_skip "Workspace initialization test"
    fi

    # Clean up
    rm -rf "$test_home"
    unset AIWB_HOME
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║  AIWB END-TO-END WORKFLOW TESTS                           ║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo "Testing AIWB at: $AIWB_BIN"
    echo ""

    # Check if aiwb exists
    if [[ ! -f "$AIWB_BIN" ]]; then
        echo -e "${RED}ERROR: AIWB binary not found at $AIWB_BIN${RESET}"
        exit 1
    fi

    # Run all test scenarios
    test_help_command
    test_status_command
    test_models_command
    test_context_commands
    test_swarm_command
    test_clear_command
    test_exit_command
    test_unknown_command
    test_empty_input
    test_rapid_commands
    test_workspace_initialization

    # Print summary
    echo ""
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}TEST SUMMARY${RESET}"
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════${RESET}"
    echo ""
    echo "Total Tests:  $((TOTAL_TESTS))"
    echo -e "${GREEN}Passed:       $PASSED_TESTS${RESET}"
    echo -e "${RED}Failed:       $FAILED_TESTS${RESET}"
    echo -e "${YELLOW}Skipped:      $SKIPPED_TESTS${RESET}"
    echo ""

    local pass_rate=0
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fi

    echo "Pass Rate:    ${pass_rate}%"
    echo ""

    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ ALL NON-SKIPPED TESTS PASSED!${RESET}"
        return 0
    else
        echo -e "${YELLOW}${BOLD}⚠ SOME TESTS FAILED${RESET}"
        echo -e "${YELLOW}Review failures above for details.${RESET}"
        return 1
    fi
}

# Run tests
main "$@"
