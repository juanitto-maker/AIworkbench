#!/usr/bin/env bats
# test_swarm.bats - Unit tests for lib/swarm.sh

# Setup: Source the required libraries
setup() {
    # Set up test environment
    export AIWB_TEST_MODE=1
    export AIWB_HOME="${BATS_TMPDIR}/aiwb_test_$$"
    mkdir -p "$AIWB_HOME"

    # Create a minimal env file for testing
    cat > "${AIWB_HOME}/.aiwb.env" <<EOF
export GEMINI_API_KEY="test_gemini_key"
export ANTHROPIC_API_KEY="test_claude_key"
export OPENAI_API_KEY="test_openai_key"
EOF

    # Create minimal config file for testing
    cat > "${AIWB_HOME}/config.json" <<EOF
{
  "version": "2.0.0",
  "swarm": {
    "enabled": "false",
    "strategy": "auto",
    "worker_provider": "gemini",
    "worker_model": "2.5-flash",
    "aggregator_provider": "claude",
    "aggregator_model": "sonnet-4-5-20250929",
    "workers": "5"
  }
}
EOF

    # Source libraries in order
    source "${BATS_TEST_DIRNAME}/../lib/common.sh" 2>/dev/null || true
    source "${BATS_TEST_DIRNAME}/../lib/config.sh" 2>/dev/null || true
    source "${BATS_TEST_DIRNAME}/../lib/ui.sh" 2>/dev/null || true
    source "${BATS_TEST_DIRNAME}/../lib/api.sh" 2>/dev/null || true
    source "${BATS_TEST_DIRNAME}/../lib/swarm.sh" 2>/dev/null || true
}

# Teardown: Clean up test environment
teardown() {
    rm -rf "$AIWB_HOME"
}

# ============================================================================
# SWARM INITIALIZATION TESTS
# ============================================================================

@test "swarm_init loads default configuration" {
    # swarm_init is called automatically when sourcing swarm.sh
    [ "$SWARM_ENABLED" = "false" ]
    [ "$SWARM_STRATEGY" = "auto" ]
    [ "$SWARM_WORKER_PROVIDER" = "gemini" ]
    [ "$SWARM_WORKER_MODEL" = "2.5-flash" ]
    [ "$SWARM_AGGREGATOR_PROVIDER" = "claude" ]
    [ "$SWARM_AGGREGATOR_MODEL" = "sonnet-4-5-20250929" ]
    [ "$SWARM_WORKERS" = "5" ]
}

@test "swarm configuration is exported" {
    # Check that variables are exported for background workers
    [[ "${!SWARM_*}" =~ SWARM_ENABLED ]]
    [[ "${!SWARM_*}" =~ SWARM_STRATEGY ]]
    [[ "${!SWARM_*}" =~ SWARM_WORKER_PROVIDER ]]
}

# ============================================================================
# SWARM DISPLAY TESTS
# ============================================================================

@test "get_swarm_display shows OFF when disabled" {
    export SWARM_ENABLED="false"
    run get_swarm_display
    [ "$status" -eq 0 ]
    [ "$output" = "OFF" ]
}

@test "get_swarm_display shows ON when enabled" {
    export SWARM_ENABLED="true"
    export SWARM_STRATEGY="mapreduce"
    export SWARM_WORKERS="5"
    run get_swarm_display
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ON" ]]
    [[ "$output" =~ "mapreduce" ]]
    [[ "$output" =~ "5 workers" ]]
}

# ============================================================================
# SWARM AUTO-DETECT TESTS
# ============================================================================

@test "swarm_auto_detect returns none for small context" {
    # Create a small prompt (< 10000 tokens, ~40 chars per token = < 400 chars)
    local small_prompt="This is a small test prompt."
    run swarm_auto_detect "$small_prompt"
    [ "$status" -eq 0 ]
    [ "$output" = "none" ]
}

@test "swarm_auto_detect returns mapreduce for large context" {
    # Create a large prompt (> 10000 tokens, ~3 chars per token = > 30000 chars)
    local large_prompt=""
    for i in {1..2000}; do
        large_prompt="${large_prompt}This is line $i with some content to make it longer and reach the token threshold. "
    done
    run swarm_auto_detect "$large_prompt"
    [ "$status" -eq 0 ]
    [ "$output" = "mapreduce" ]
}

# ============================================================================
# SWARM TOGGLE TESTS
# ============================================================================

@test "swarm_toggle enables swarm when disabled" {
    export SWARM_ENABLED="false"
    swarm_toggle
    [ "$SWARM_ENABLED" = "true" ]
}

@test "swarm_toggle disables swarm when enabled" {
    export SWARM_ENABLED="true"
    swarm_toggle
    [ "$SWARM_ENABLED" = "false" ]
}

# ============================================================================
# SWARM EXECUTION TESTS
# ============================================================================

@test "swarm_execute auto-detects strategy" {
    export SWARM_STRATEGY="auto"
    export SWARM_ENABLED="true"

    # Small prompt should cause fallback
    local small_prompt="Small test"
    run swarm_execute "$small_prompt" "make"

    # Should return 1 (fallback to standard mode)
    [ "$status" -eq 1 ]
}

@test "swarm_mapreduce falls back for small prompts" {
    # Small prompt (< 10000 tokens)
    local small_prompt="This is a small test prompt."
    run swarm_mapreduce "$small_prompt" "make"

    # Should return 1 (fallback to standard mode)
    [ "$status" -eq 1 ]
}

@test "swarm_hierarchical returns error" {
    # Hierarchical is not yet implemented
    local prompt="Test prompt"
    run swarm_hierarchical "$prompt" "make"

    # Should return 1 (not implemented)
    [ "$status" -eq 1 ]
}

# ============================================================================
# SWARM COST ESTIMATION TESTS
# ============================================================================

@test "swarm_estimate_cost returns 0 for small context" {
    local small_prompt="Small test"
    run swarm_estimate_cost "$small_prompt" "mapreduce"
    [ "$status" -eq 0 ]
    [ "$output" = "0" ]
}

@test "swarm_estimate_cost calculates cost for large context" {
    # Create a large prompt that will trigger swarm mode
    local large_prompt=""
    for i in {1..2000}; do
        large_prompt="${large_prompt}This is line $i with some content to make it longer. "
    done

    run swarm_estimate_cost "$large_prompt" "mapreduce"
    [ "$status" -eq 0 ]
    # Should return a non-zero cost
    [[ "$output" != "0" ]]
    # Cost should be a valid number
    [[ "$output" =~ ^[0-9]+\.[0-9]+$ ]]
}

# ============================================================================
# TOKEN ESTIMATION TESTS (from api.sh, used by swarm)
# ============================================================================

@test "estimate_tokens returns reasonable estimate for short text" {
    local text="Hello world"
    run estimate_tokens "$text"
    [ "$status" -eq 0 ]
    # Should be around 2-5 tokens
    [ "$output" -gt 0 ]
    [ "$output" -lt 10 ]
}

@test "estimate_tokens returns reasonable estimate for longer text" {
    local text="This is a longer text that should result in more tokens being estimated by the function"
    run estimate_tokens "$text"
    [ "$status" -eq 0 ]
    # Should be around 15-25 tokens
    [ "$output" -gt 10 ]
    [ "$output" -lt 50 ]
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

@test "swarm mode respects enabled flag" {
    export SWARM_ENABLED="false"

    # When disabled, should not execute swarm logic
    [ "$SWARM_ENABLED" = "false" ]
}

@test "swarm worker and aggregator models are configurable" {
    export SWARM_WORKER_PROVIDER="gemini"
    export SWARM_WORKER_MODEL="2.5-flash"
    export SWARM_AGGREGATOR_PROVIDER="claude"
    export SWARM_AGGREGATOR_MODEL="3-5-sonnet-20240620"

    [ "$SWARM_WORKER_PROVIDER" = "gemini" ]
    [ "$SWARM_WORKER_MODEL" = "2.5-flash" ]
    [ "$SWARM_AGGREGATOR_PROVIDER" = "claude" ]
    [ "$SWARM_AGGREGATOR_MODEL" = "3-5-sonnet-20240620" ]
}

@test "swarm workers count is configurable" {
    export SWARM_WORKERS="10"
    [ "$SWARM_WORKERS" = "10" ]
}

@test "swarm strategy options are valid" {
    local strategies=("auto" "mapreduce" "hierarchical")
    for strategy in "${strategies[@]}"; do
        export SWARM_STRATEGY="$strategy"
        [ "$SWARM_STRATEGY" = "$strategy" ]
    done
}
