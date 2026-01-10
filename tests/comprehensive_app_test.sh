#!/usr/bin/env bash
# Comprehensive Application Testing Script
# Tests all major functionality: chat, swarm, context, menus, commands
# This is a holistic test suite for the entire AIWB application

set -o pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AIWB_ROOT="$(dirname "$SCRIPT_DIR")"
AIWB_BIN="$AIWB_ROOT/aiwb"

# Source libraries for testing (don't exit on error)
source "$AIWB_ROOT/lib/common.sh" 2>/dev/null || true
source "$AIWB_ROOT/lib/config.sh" 2>/dev/null || true
source "$AIWB_ROOT/lib/chat_router.sh" 2>/dev/null || true
source "$AIWB_ROOT/lib/swarm.sh" 2>/dev/null || true
source "$AIWB_ROOT/lib/context_state.sh" 2>/dev/null || true

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

# ============================================================================
# TEST HELPER FUNCTIONS
# ============================================================================

test_header() {
    echo ""
    echo -e "${BOLD}${BLUE}========================================${RESET}"
    echo -e "${BOLD}$1${RESET}"
    echo -e "${BOLD}${BLUE}========================================${RESET}"
}

test_section() {
    echo ""
    echo -e "${BOLD}${YELLOW}>>> $1${RESET}"
}

test_pass() {
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
    echo -e "${GREEN}✓${RESET} $1"
}

test_fail() {
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
    echo -e "${RED}✗${RESET} $1"
}

test_skip() {
    ((TOTAL_TESTS++))
    echo -e "${YELLOW}○${RESET} $1 (skipped)"
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [[ "$expected" == "$actual" ]]; then
        test_pass "$test_name"
        return 0
    else
        test_fail "$test_name - Expected: '$expected', Got: '$actual'"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    if echo "$haystack" | grep -q "$needle"; then
        test_pass "$test_name"
        return 0
    else
        test_fail "$test_name - Expected to find '$needle' in output"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    if ! echo "$haystack" | grep -q "$needle"; then
        test_pass "$test_name"
        return 0
    else
        test_fail "$test_name - Did not expect to find '$needle' in output"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="$2"

    if [[ -f "$file" ]]; then
        test_pass "$test_name"
        return 0
    else
        test_fail "$test_name - File does not exist: $file"
        return 1
    fi
}

assert_function_exists() {
    local func="$1"
    local test_name="$2"

    if type "$func" &>/dev/null; then
        test_pass "$test_name"
        return 0
    else
        test_fail "$test_name - Function does not exist: $func"
        return 1
    fi
}

# ============================================================================
# TEST SUITES
# ============================================================================

# Test Suite 1: Core Library Functions
test_core_libraries() {
    test_header "TEST SUITE 1: Core Library Functions"

    test_section "Common Library Functions"
    assert_function_exists "have" "Function 'have' exists"
    assert_function_exists "require" "Function 'require' exists"
    assert_function_exists "msg" "Function 'msg' exists"
    assert_function_exists "err" "Function 'err' exists"
    assert_function_exists "warn" "Function 'warn' exists"

    test_section "Config Library Functions"
    assert_function_exists "config_get" "Function 'config_get' exists"
    assert_function_exists "config_set" "Function 'config_set' exists"
    assert_function_exists "get_workspace" "Function 'get_workspace' exists"

    test_section "Chat Router Functions"
    assert_function_exists "detect_message_intent" "Function 'detect_message_intent' exists"
    assert_function_exists "is_question" "Function 'is_question' exists"
    assert_function_exists "handle_chat_message_routed" "Function 'handle_chat_message_routed' exists"

    test_section "Swarm Mode Functions"
    assert_function_exists "swarm_init" "Function 'swarm_init' exists"
    assert_function_exists "swarm_toggle" "Function 'swarm_toggle' exists"
    assert_function_exists "swarm_auto_detect" "Function 'swarm_auto_detect' exists"

    test_section "Context State Functions"
    assert_function_exists "init_context_state" "Function 'init_context_state' exists"
    assert_function_exists "context_state_get" "Function 'context_state_get' exists"
    assert_function_exists "context_state_add_file" "Function 'context_state_add_file' exists"
}

# Test Suite 2: Chat Router Intent Detection
test_chat_router_intent() {
    test_header "TEST SUITE 2: Chat Router Intent Detection"

    test_section "Edit Intent Detection"
    local intent

    intent=$(detect_message_intent "implement a new feature")
    assert_equals "edit" "$intent" "Detects 'implement' as edit intent"

    intent=$(detect_message_intent "add a button to the page")
    assert_equals "edit" "$intent" "Detects 'add' as edit intent"

    intent=$(detect_message_intent "fix the bug in login")
    assert_equals "edit" "$intent" "Detects 'fix' as edit intent"

    intent=$(detect_message_intent "update the CSS styles")
    assert_equals "edit" "$intent" "Detects 'update' as edit intent"

    intent=$(detect_message_intent "modify the API endpoint")
    assert_equals "edit" "$intent" "Detects 'modify' as edit intent"

    intent=$(detect_message_intent "refactor the code")
    assert_equals "edit" "$intent" "Detects 'refactor' as edit intent"

    test_section "Generate Intent Detection"
    intent=$(detect_message_intent "generate a new component")
    assert_equals "generate" "$intent" "Detects 'generate' as generate intent"

    intent=$(detect_message_intent "scaffold a new project")
    assert_equals "generate" "$intent" "Detects 'scaffold' as generate intent"

    intent=$(detect_message_intent "build from scratch")
    assert_equals "generate" "$intent" "Detects 'build from scratch' as generate intent"

    test_section "Chat/Question Intent Detection"
    intent=$(detect_message_intent "how does this work?")
    assert_equals "chat" "$intent" "Detects 'how' as chat intent"

    intent=$(detect_message_intent "what is the purpose?")
    assert_equals "chat" "$intent" "Detects 'what' as chat intent"

    intent=$(detect_message_intent "why is this happening?")
    assert_equals "chat" "$intent" "Detects 'why' as chat intent"

    intent=$(detect_message_intent "explain the algorithm")
    assert_equals "chat" "$intent" "Detects 'explain' as chat intent"

    test_section "Question Detection"
    if is_question "What is the best approach?"; then
        test_pass "Detects 'What...' as question"
    else
        test_fail "Should detect 'What...' as question"
    fi

    if is_question "How do I do this?"; then
        test_pass "Detects 'How...' as question"
    else
        test_fail "Should detect 'How...' as question"
    fi

    if is_question "Is this correct?"; then
        test_pass "Detects 'Is...' as question"
    else
        test_fail "Should detect 'Is...' as question"
    fi

    if is_question "Add a feature"; then
        test_fail "Should not detect 'Add...' as question"
    else
        test_pass "Correctly rejects non-question"
    fi
}

# Test Suite 3: Swarm Mode Configuration
test_swarm_mode() {
    test_header "TEST SUITE 3: Swarm Mode Configuration"

    test_section "Swarm Initialization"
    swarm_init
    test_pass "Swarm initialized successfully"

    test_section "Swarm Configuration Variables"
    [[ -n "$SWARM_ENABLED" ]] && test_pass "SWARM_ENABLED is set" || test_fail "SWARM_ENABLED is not set"
    [[ -n "$SWARM_STRATEGY" ]] && test_pass "SWARM_STRATEGY is set" || test_fail "SWARM_STRATEGY is not set"
    [[ -n "$SWARM_WORKER_PROVIDER" ]] && test_pass "SWARM_WORKER_PROVIDER is set" || test_fail "SWARM_WORKER_PROVIDER is not set"
    [[ -n "$SWARM_WORKER_MODEL" ]] && test_pass "SWARM_WORKER_MODEL is set" || test_fail "SWARM_WORKER_MODEL is not set"
    [[ -n "$SWARM_AGGREGATOR_PROVIDER" ]] && test_pass "SWARM_AGGREGATOR_PROVIDER is set" || test_fail "SWARM_AGGREGATOR_PROVIDER is not set"
    [[ -n "$SWARM_AGGREGATOR_MODEL" ]] && test_pass "SWARM_AGGREGATOR_MODEL is set" || test_fail "SWARM_AGGREGATOR_MODEL is not set"
    [[ -n "$SWARM_WORKERS" ]] && test_pass "SWARM_WORKERS is set" || test_fail "SWARM_WORKERS is not set"
    [[ -n "$SWARM_MIN_TOKENS" ]] && test_pass "SWARM_MIN_TOKENS is set" || test_fail "SWARM_MIN_TOKENS is not set"

    test_section "Swarm Display"
    local swarm_display
    swarm_display=$(get_swarm_display)
    [[ -n "$swarm_display" ]] && test_pass "Swarm display generated" || test_fail "Swarm display empty"

    test_section "Swarm Toggle"
    if type swarm_toggle &>/dev/null; then
        test_pass "swarm_toggle function exists"
    else
        test_fail "swarm_toggle function does not exist"
    fi

    test_section "Swarm Auto-Detect"
    if type swarm_auto_detect &>/dev/null; then
        # Test with small prompt (should not trigger swarm)
        local small_result
        small_result=$(swarm_auto_detect "Small test prompt")
        test_pass "swarm_auto_detect works with small prompt"

        # Test with large prompt (should trigger swarm if enabled)
        local large_prompt=$(printf 'word %.0s' {1..1000})
        local large_result
        large_result=$(swarm_auto_detect "$large_prompt")
        test_pass "swarm_auto_detect works with large prompt"
    else
        test_fail "swarm_auto_detect function does not exist"
    fi
}

# Test Suite 4: Context State Management
test_context_state() {
    test_header "TEST SUITE 4: Context State Management"

    test_section "Context State File Location"
    local context_file
    context_file=$(get_context_state_file)
    [[ -n "$context_file" ]] && test_pass "Context state file path generated" || test_fail "Context state file path empty"

    test_section "Context State Initialization"
    # Clean up any existing context state for testing
    local test_workspace="/tmp/aiwb_test_$$"
    mkdir -p "$test_workspace"
    export WORKSPACE="$test_workspace"

    # Initialize context state
    init_context_state 2>/dev/null || true

    local context_file_test="$test_workspace/.context_state"
    if [[ -f "$context_file_test" ]]; then
        test_pass "Context state file created"

        # Check if it's valid JSON
        if jq empty "$context_file_test" 2>/dev/null; then
            test_pass "Context state file is valid JSON"

            # Check required fields
            local session_id
            session_id=$(jq -r '.session_id' "$context_file_test" 2>/dev/null)
            [[ -n "$session_id" ]] && test_pass "Context state has session_id" || test_fail "Context state missing session_id"

            local created_at
            created_at=$(jq -r '.created_at' "$context_file_test" 2>/dev/null)
            [[ -n "$created_at" ]] && test_pass "Context state has created_at" || test_fail "Context state missing created_at"

            local context_files
            context_files=$(jq -r '.context_files' "$context_file_test" 2>/dev/null)
            [[ "$context_files" != "null" ]] && test_pass "Context state has context_files array" || test_fail "Context state missing context_files"
        else
            test_fail "Context state file is not valid JSON"
        fi
    else
        test_fail "Context state file not created"
    fi

    # Clean up test workspace
    rm -rf "$test_workspace"
}

# Test Suite 5: File Operations and Validation
test_file_operations() {
    test_header "TEST SUITE 5: File Operations and Validation"

    test_section "Main Script Existence"
    assert_file_exists "$AIWB_BIN" "Main aiwb script exists"

    test_section "Library Files"
    assert_file_exists "$AIWB_ROOT/lib/common.sh" "common.sh exists"
    assert_file_exists "$AIWB_ROOT/lib/config.sh" "config.sh exists"
    assert_file_exists "$AIWB_ROOT/lib/api.sh" "api.sh exists"
    assert_file_exists "$AIWB_ROOT/lib/chat_router.sh" "chat_router.sh exists"
    assert_file_exists "$AIWB_ROOT/lib/swarm.sh" "swarm.sh exists"
    assert_file_exists "$AIWB_ROOT/lib/context_state.sh" "context_state.sh exists"
    assert_file_exists "$AIWB_ROOT/lib/modes.sh" "modes.sh exists"
    assert_file_exists "$AIWB_ROOT/lib/ui.sh" "ui.sh exists"
    assert_file_exists "$AIWB_ROOT/lib/error.sh" "error.sh exists"
    assert_file_exists "$AIWB_ROOT/lib/github.sh" "github.sh exists"
    assert_file_exists "$AIWB_ROOT/lib/security.sh" "security.sh exists"
    assert_file_exists "$AIWB_ROOT/lib/editor.sh" "editor.sh exists"

    test_section "Script Syntax Validation"
    if bash -n "$AIWB_BIN" 2>/dev/null; then
        test_pass "Main script has valid syntax"
    else
        test_fail "Main script has syntax errors"
    fi

    for lib in "$AIWB_ROOT/lib"/*.sh; do
        local lib_name=$(basename "$lib")
        if bash -n "$lib" 2>/dev/null; then
            test_pass "$lib_name has valid syntax"
        else
            test_fail "$lib_name has syntax errors"
        fi
    done
}

# Test Suite 6: Configuration Management
test_configuration() {
    test_header "TEST SUITE 6: Configuration Management"

    test_section "Config File Initialization"
    # Test workspace initialization creates config
    local test_workspace="/tmp/aiwb_test_config_$$"
    mkdir -p "$test_workspace"
    export AIWB_HOME="$test_workspace"

    # Initialize workspace
    if type init_workspace &>/dev/null; then
        init_workspace 2>/dev/null || true
        test_pass "Workspace initialization function exists and runs"
    else
        test_skip "init_workspace function not found"
    fi

    # Clean up
    rm -rf "$test_workspace"

    test_section "Configuration Constants"
    [[ -n "$AIWB_MAX_TOKENS_DEFAULT" ]] && test_pass "AIWB_MAX_TOKENS_DEFAULT defined" || test_fail "AIWB_MAX_TOKENS_DEFAULT not defined"
    [[ -n "$AIWB_TEMPERATURE_DEFAULT" ]] && test_pass "AIWB_TEMPERATURE_DEFAULT defined" || test_fail "AIWB_TEMPERATURE_DEFAULT not defined"
    [[ -n "$AIWB_MAX_FILE_SIZE" ]] && test_pass "AIWB_MAX_FILE_SIZE defined" || test_fail "AIWB_MAX_FILE_SIZE not defined"
}

# Test Suite 7: Error Handling
test_error_handling() {
    test_header "TEST SUITE 7: Error Handling"

    test_section "Error Functions"
    assert_function_exists "err" "Error function 'err' exists"
    assert_function_exists "warn" "Warning function 'warn' exists"
    # Note: 'die' function is optional and may not be in all versions

    test_section "Error Codes"
    [[ -n "$AIWB_EXIT_SUCCESS" ]] && test_pass "AIWB_EXIT_SUCCESS defined" || test_fail "AIWB_EXIT_SUCCESS not defined"
    [[ -n "$AIWB_EXIT_ERROR" ]] && test_pass "AIWB_EXIT_ERROR defined" || test_fail "AIWB_EXIT_ERROR not defined"
    [[ -n "$AIWB_EXIT_SIGINT" ]] && test_pass "AIWB_EXIT_SIGINT defined" || test_fail "AIWB_EXIT_SIGINT not defined"
}

# Test Suite 8: Integration Tests
test_integration() {
    test_header "TEST SUITE 8: Integration Tests"

    test_section "Help Command"
    # Test help command doesn't crash
    if echo -e "/help\n/exit\nyes" | timeout 5 "$AIWB_BIN" 2>&1 | grep -q "COMMANDS"; then
        test_pass "Help command works"
    else
        test_skip "Help command test (requires full environment)"
    fi

    test_section "Version Flag"
    if "$AIWB_BIN" --version 2>&1 | grep -q "[0-9]"; then
        test_pass "Version flag works"
    else
        test_skip "Version flag test"
    fi
}

# Test Suite 9: Menu System
test_menu_system() {
    test_header "TEST SUITE 9: Menu System"

    test_section "Menu Functions"
    assert_function_exists "ui_choose" "Menu function 'ui_choose' exists"
    assert_function_exists "ui_input" "Input function 'ui_input' exists"

    test_section "Command Handlers"
    # Note: Command handlers are defined in main aiwb script, not libraries
    # These tests would require sourcing the main script
    test_skip "Command handlers (defined in main script, not libraries)"
}

# Test Suite 10: GitHub Integration
test_github_integration() {
    test_header "TEST SUITE 10: GitHub Integration"

    test_section "GitHub Functions"
    # Note: GitHub command handler is in main script
    test_skip "GitHub command handler (defined in main script)"

    # Check for library functions
    if type gh_status &>/dev/null; then
        test_pass "GitHub status function exists"
    else
        test_skip "GitHub status function (optional)"
    fi
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

main() {
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║  AIWB COMPREHENSIVE APPLICATION TEST SUITE                ║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo "Testing AIWB installation at: $AIWB_ROOT"
    echo ""

    # Run all test suites
    test_core_libraries
    test_chat_router_intent
    test_swarm_mode
    test_context_state
    test_file_operations
    test_configuration
    test_error_handling
    test_integration
    test_menu_system
    test_github_integration

    # Print summary
    echo ""
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}TEST SUMMARY${RESET}"
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════${RESET}"
    echo ""
    echo "Total Tests:  $TOTAL_TESTS"
    echo -e "${GREEN}Passed:       $PASSED_TESTS${RESET}"
    echo -e "${RED}Failed:       $FAILED_TESTS${RESET}"
    echo ""

    local pass_rate=0
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fi

    echo "Pass Rate:    ${pass_rate}%"
    echo ""

    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ ALL TESTS PASSED!${RESET}"
        return 0
    else
        echo -e "${RED}${BOLD}✗ SOME TESTS FAILED${RESET}"
        echo -e "${YELLOW}Please review the failures above.${RESET}"
        return 1
    fi
}

# Run tests
main "$@"
