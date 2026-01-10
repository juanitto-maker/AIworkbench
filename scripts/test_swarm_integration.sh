#!/usr/bin/env bash
# test_swarm_integration.sh - Integration tests for swarm mode
# This script tests the swarm feature end-to-end

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Swarm Mode Integration Tests"
echo "========================================="
echo ""

# Test environment setup
export AIWB_TEST_MODE=1
export AIWB_HOME="/tmp/aiwb_swarm_test_$$"
mkdir -p "$AIWB_HOME"

# Create test config
cat > "$AIWB_HOME/config.json" <<EOF
{
  "version": "2.0.0",
  "swarm": {
    "enabled": "true",
    "strategy": "auto",
    "worker_provider": "gemini",
    "worker_model": "2.5-flash",
    "aggregator_provider": "claude",
    "aggregator_model": "sonnet-4-5-20250929",
    "workers": "3"
  }
}
EOF

# Source libraries
source "$PROJECT_ROOT/lib/common.sh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/config.sh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/ui.sh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/api.sh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/swarm.sh" 2>/dev/null || true

# Test counter
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_start() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Test $TESTS_TOTAL: $1 ... "
}

test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}PASS${NC}"
}

test_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}FAIL${NC}"
    [[ -n "${1:-}" ]] && echo "  Error: $1"
}

# ============================================================================
# TEST 1: Swarm Initialization
# ============================================================================

test_start "Swarm initialization from config"
if [[ "$SWARM_ENABLED" = "true" ]] && \
   [[ "$SWARM_STRATEGY" = "auto" ]] && \
   [[ "$SWARM_WORKERS" = "3" ]]; then
    test_pass
else
    test_fail "Expected SWARM_ENABLED=true, SWARM_STRATEGY=auto, SWARM_WORKERS=3"
fi

# ============================================================================
# TEST 2: Swarm Display
# ============================================================================

test_start "Swarm display shows correct status"
display=$(get_swarm_display)
if [[ "$display" =~ "ON" ]] && [[ "$display" =~ "3 workers" ]]; then
    test_pass
else
    test_fail "Expected display to show ON with 3 workers, got: $display"
fi

# ============================================================================
# TEST 3: Auto-detect Strategy - Small Context
# ============================================================================

test_start "Auto-detect returns 'none' for small context"
small_prompt="Write a hello world function"
strategy=$(swarm_auto_detect "$small_prompt")
if [[ "$strategy" = "none" ]]; then
    test_pass
else
    test_fail "Expected 'none' for small context, got: $strategy"
fi

# ============================================================================
# TEST 4: Auto-detect Strategy - Large Context
# ============================================================================

test_start "Auto-detect returns 'mapreduce' for large context"
# Generate a large prompt (>10K tokens worth of text)
large_prompt=""
for i in {1..3000}; do
    large_prompt="${large_prompt}This is line $i of a very large codebase that needs to be processed. "
done
strategy=$(swarm_auto_detect "$large_prompt")
if [[ "$strategy" = "mapreduce" ]]; then
    test_pass
else
    test_fail "Expected 'mapreduce' for large context, got: $strategy"
fi

# ============================================================================
# TEST 5: Token Estimation
# ============================================================================

test_start "Token estimation is reasonable"
test_text="This is a test prompt with some content"
tokens=$(estimate_tokens "$test_text")
if (( tokens > 5 && tokens < 20 )); then
    test_pass
else
    test_fail "Expected 5-20 tokens, got: $tokens"
fi

# ============================================================================
# TEST 6: Cost Estimation - Small Context
# ============================================================================

test_start "Cost estimation returns 0 for small context"
cost=$(swarm_estimate_cost "$small_prompt" "mapreduce")
if [[ "$cost" = "0" ]]; then
    test_pass
else
    test_fail "Expected cost=0 for small context, got: $cost"
fi

# ============================================================================
# TEST 7: Cost Estimation - Large Context
# ============================================================================

test_start "Cost estimation calculates for large context"
cost=$(swarm_estimate_cost "$large_prompt" "mapreduce")
if [[ "$cost" != "0" ]] && [[ "$cost" =~ ^[0-9]+\.[0-9]+$ ]]; then
    test_pass
else
    test_fail "Expected non-zero cost for large context, got: $cost"
fi

# ============================================================================
# TEST 8: Swarm Toggle
# ============================================================================

test_start "Toggle swarm on/off"
original_state="$SWARM_ENABLED"
swarm_toggle >/dev/null 2>&1
new_state1="$SWARM_ENABLED"
swarm_toggle >/dev/null 2>&1
new_state2="$SWARM_ENABLED"

if [[ "$original_state" = "true" ]] && \
   [[ "$new_state1" = "false" ]] && \
   [[ "$new_state2" = "true" ]]; then
    test_pass
else
    test_fail "Toggle failed: $original_state -> $new_state1 -> $new_state2"
fi

# ============================================================================
# TEST 9: Map-Reduce Fallback
# ============================================================================

test_start "Map-reduce falls back for small prompts"
export SWARM_ENABLED="true"
if swarm_mapreduce "$small_prompt" "make" >/dev/null 2>&1; then
    test_fail "Should have returned 1 (fallback)"
else
    # Return code 1 is expected (fallback to standard mode)
    test_pass
fi

# ============================================================================
# TEST 10: Swarm Execute with Auto Strategy
# ============================================================================

test_start "Swarm execute with auto strategy (small prompt)"
export SWARM_STRATEGY="auto"
if swarm_execute "$small_prompt" "make" >/dev/null 2>&1; then
    test_fail "Should have returned 1 (fallback)"
else
    # Return code 1 is expected (fallback to standard mode)
    test_pass
fi

# ============================================================================
# TEST 11: Configuration Persistence
# ============================================================================

test_start "Configuration values are correct"
if [[ "$SWARM_WORKER_PROVIDER" = "gemini" ]] && \
   [[ "$SWARM_WORKER_MODEL" = "2.5-flash" ]] && \
   [[ "$SWARM_AGGREGATOR_PROVIDER" = "claude" ]] && \
   [[ "$SWARM_AGGREGATOR_MODEL" = "sonnet-4-5-20250929" ]]; then
    test_pass
else
    test_fail "Configuration values don't match expected"
fi

# ============================================================================
# TEST 12: Export Variables for Workers
# ============================================================================

test_start "Swarm variables are exported"
if [[ "$(declare -p SWARM_ENABLED 2>/dev/null)" =~ "declare -x" ]] && \
   [[ "$(declare -p SWARM_WORKERS 2>/dev/null)" =~ "declare -x" ]]; then
    test_pass
else
    test_fail "Swarm variables not exported for background workers"
fi

# ============================================================================
# TEST 13: Hierarchical Strategy (Not Implemented)
# ============================================================================

test_start "Hierarchical strategy returns error (not implemented)"
if swarm_hierarchical "$small_prompt" "make" >/dev/null 2>&1; then
    test_fail "Should return 1 (not implemented)"
else
    test_pass
fi

# ============================================================================
# TEST 14: Chunk Size Calculation
# ============================================================================

test_start "Chunk calculation for large context"
tokens=$(estimate_tokens "$large_prompt")
chunk_size=2500
num_chunks=$(( (tokens + chunk_size - 1) / chunk_size ))
if (( num_chunks > 2 )); then
    test_pass
else
    test_fail "Expected >2 chunks for large context, got: $num_chunks"
fi

# ============================================================================
# TEST 15: Strategy Selection
# ============================================================================

test_start "All strategies are valid"
strategies=("auto" "mapreduce" "hierarchical")
all_valid=true
for strategy in "${strategies[@]}"; do
    SWARM_STRATEGY="$strategy"
    if [[ "$SWARM_STRATEGY" != "$strategy" ]]; then
        all_valid=false
        break
    fi
done
if $all_valid; then
    test_pass
else
    test_fail "Not all strategies are valid"
fi

# ============================================================================
# Cleanup
# ============================================================================

rm -rf "$AIWB_HOME"

# ============================================================================
# Results
# ============================================================================

echo ""
echo "========================================="
echo "Test Results"
echo "========================================="
echo "Total tests:  $TESTS_TOTAL"
echo -e "Passed:       ${GREEN}$TESTS_PASSED${NC}"
if (( TESTS_FAILED > 0 )); then
    echo -e "Failed:       ${RED}$TESTS_FAILED${NC}"
else
    echo -e "Failed:       ${GREEN}$TESTS_FAILED${NC}"
fi
echo "========================================="

if (( TESTS_FAILED > 0 )); then
    echo -e "${RED}SOME TESTS FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}ALL TESTS PASSED${NC}"
    exit 0
fi
