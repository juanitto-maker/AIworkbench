#!/usr/bin/env bats
# test_common.bats - Unit tests for lib/common.sh

# Setup: Source the common library before each test
setup() {
    # Source the library directly in setup
    source "${BATS_TEST_DIRNAME}/../lib/common.sh"
}

# ============================================================================
# PLATFORM DETECTION TESTS
# ============================================================================

@test "get_platform returns valid platform" {
    # Library already loaded in setup()
    run get_platform
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^(termux|macos|linux|unknown)$ ]]
}

@test "is_termux returns boolean" {
    # Library already loaded in setup()
    run is_termux
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

@test "is_macos returns boolean" {
    # Library already loaded in setup()
    run is_macos
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

@test "is_linux returns boolean" {
    # Library already loaded in setup()
    run is_linux
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

# ============================================================================
# COMMAND AVAILABILITY TESTS
# ============================================================================

@test "have() detects existing command" {
    # Library already loaded in setup()
    run have "bash"
    [ "$status" -eq 0 ]
}

@test "have() fails for non-existing command" {
    # Library already loaded in setup()
    run have "nonexistent_command_xyz123"
    [ "$status" -eq 1 ]
}

@test "supports_color returns boolean" {
    # Library already loaded in setup()
    run supports_color
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

# ============================================================================
# UTILITY FUNCTION TESTS
# ============================================================================

@test "get_aiwb_home returns a directory path" {
    # Library already loaded in setup()
    run get_aiwb_home
    [ "$status" -eq 0 ]
    [[ -n "$output" ]]
}

@test "ensure_dir creates directory if missing" {
    # Library already loaded in setup()
    local test_dir="${BATS_TMPDIR}/test_ensure_dir_$$"
    run ensure_dir "$test_dir"
    [ "$status" -eq 0 ]
    [[ -d "$test_dir" ]]
    rm -rf "$test_dir"
}
