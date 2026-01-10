#!/usr/bin/env bats
# test_error_handlers.bats - Unit tests for standardized error handling helpers

# Setup: Source the libraries before each test
setup() {
    source "${BATS_TEST_DIRNAME}/../lib/common.sh"
    source "${BATS_TEST_DIRNAME}/../lib/config.sh"
    source "${BATS_TEST_DIRNAME}/../lib/error.sh"

    # Create temp directory for test files
    TEST_DIR=$(mktemp -d)
}

# Teardown: Clean up temp files
teardown() {
    rm -rf "$TEST_DIR"
}

# ============================================================================
# REQUIRE_FILE TESTS
# ============================================================================

@test "require_file succeeds when file exists" {
    # Create a test file
    touch "$TEST_DIR/test.txt"

    # require_file should succeed
    run require_file "$TEST_DIR/test.txt"
    [ "$status" -eq 0 ]
}

@test "require_file exits when file does not exist" {
    # require_file should exit with error
    run require_file "$TEST_DIR/nonexistent.txt"
    [ "$status" -ne 0 ]
}

# ============================================================================
# REQUIRE_DIR TESTS
# ============================================================================

@test "require_dir succeeds when directory exists" {
    # Create a test directory
    mkdir -p "$TEST_DIR/subdir"

    # require_dir should succeed
    run require_dir "$TEST_DIR/subdir"
    [ "$status" -eq 0 ]
}

@test "require_dir exits when directory does not exist" {
    # require_dir should exit with error
    run require_dir "$TEST_DIR/nonexistent_dir"
    [ "$status" -ne 0 ]
}

# ============================================================================
# VALIDATE_NONEMPTY TESTS
# ============================================================================

@test "validate_nonempty succeeds with non-empty string" {
    # validate_nonempty should succeed
    run validate_nonempty "test_value" "test_field"
    [ "$status" -eq 0 ]
}

@test "validate_nonempty exits with empty string" {
    # validate_nonempty should exit with error
    run validate_nonempty "" "test_field"
    [ "$status" -ne 0 ]
}

# ============================================================================
# TRY_OR_DIE TESTS
# ============================================================================

@test "try_or_die succeeds with successful command" {
    # try_or_die should succeed with a simple command
    run try_or_die "true" "Command should succeed"
    [ "$status" -eq 0 ]
}

@test "try_or_die exits with failed command" {
    # try_or_die should exit with error
    run try_or_die "false" "Command should fail"
    [ "$status" -ne 0 ]
}

@test "try_or_die succeeds with file creation" {
    # try_or_die should succeed with file creation
    run try_or_die "touch $TEST_DIR/created.txt" "Create file"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/created.txt" ]
}

# ============================================================================
# ERROR CODE CONSTANT TESTS
# ============================================================================

@test "E_GENERAL error code is defined" {
    [ -n "$E_GENERAL" ]
}

@test "E_FILE_NOT_FOUND error code is defined" {
    [ -n "$E_FILE_NOT_FOUND" ]
}

@test "E_INVALID_INPUT error code is defined" {
    [ -n "$E_INVALID_INPUT" ]
}

@test "E_API_CALL error code is defined" {
    [ -n "$E_API_CALL" ]
}

@test "E_AUTH error code is defined" {
    [ -n "$E_AUTH" ]
}
