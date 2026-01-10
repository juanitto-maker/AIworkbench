#!/usr/bin/env bats
# test_common.bats - Unit tests for lib/common.sh

# Setup: Source the common library
setup() {
    load_lib() {
        source "${BATS_TEST_DIRNAME}/../lib/common.sh"
    }
}

# ============================================================================
# PLATFORM DETECTION TESTS
# ============================================================================

@test "get_platform returns valid platform" {
    load_lib
    run get_platform
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^(termux|macos|linux|unknown)$ ]]
}

@test "is_termux returns boolean" {
    load_lib
    run is_termux
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

@test "is_macos returns boolean" {
    load_lib
    run is_macos
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

@test "is_linux returns boolean" {
    load_lib
    run is_linux
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

# ============================================================================
# COMMAND AVAILABILITY TESTS
# ============================================================================

@test "have() detects existing command" {
    load_lib
    run have "bash"
    [ "$status" -eq 0 ]
}

@test "have() fails for non-existing command" {
    load_lib
    run have "nonexistent_command_xyz123"
    [ "$status" -eq 1 ]
}

@test "supports_color returns boolean" {
    load_lib
    run supports_color
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

# ============================================================================
# PATH UTILITIES TESTS
# ============================================================================

@test "realpath_portable works on existing path" {
    load_lib
    run realpath_portable "/tmp"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^/ ]]
}

@test "get_script_dir returns valid directory" {
    load_lib
    # This function returns the directory of the calling script
    # In bats tests, it should return a valid path
    run bash -c "source ${BATS_TEST_DIRNAME}/../lib/common.sh; get_script_dir"
    [ "$status" -eq 0 ]
    [[ -n "$output" ]]
}
