#!/usr/bin/env bats
# test_config.bats - Unit tests for lib/config.sh constants and configuration

# Setup: Source the libraries before each test
setup() {
    source "${BATS_TEST_DIRNAME}/../lib/common.sh"
    source "${BATS_TEST_DIRNAME}/../lib/config.sh"
}

# ============================================================================
# CONSTANT DEFINITION TESTS
# ============================================================================

@test "AIWB_MAX_TOKENS_DEFAULT is defined" {
    [ -n "$AIWB_MAX_TOKENS_DEFAULT" ]
    [ "$AIWB_MAX_TOKENS_DEFAULT" -eq 16000 ]
}

@test "AIWB_TEMPERATURE_DEFAULT is defined" {
    [ -n "$AIWB_TEMPERATURE_DEFAULT" ]
    [[ "$AIWB_TEMPERATURE_DEFAULT" == "0.2" ]]
}

@test "AIWB_API_TIMEOUT is defined" {
    [ -n "$AIWB_API_TIMEOUT" ]
    [ "$AIWB_API_TIMEOUT" -eq 300 ]
}

@test "AIWB_API_CONNECT_TIMEOUT is defined" {
    [ -n "$AIWB_API_CONNECT_TIMEOUT" ]
    [ "$AIWB_API_CONNECT_TIMEOUT" -eq 10 ]
}

@test "AIWB_MAX_FILE_SIZE is defined" {
    [ -n "$AIWB_MAX_FILE_SIZE" ]
    [ "$AIWB_MAX_FILE_SIZE" -eq 100000 ]
}

@test "AIWB_UI_SHORT_DELAY is defined" {
    [ -n "$AIWB_UI_SHORT_DELAY" ]
    [[ "$AIWB_UI_SHORT_DELAY" == "0.1" ]]
}

@test "AIWB_UI_MEDIUM_DELAY is defined" {
    [ -n "$AIWB_UI_MEDIUM_DELAY" ]
    [[ "$AIWB_UI_MEDIUM_DELAY" == "0.5" ]]
}

@test "AIWB_ERROR_RETRY_DELAY is defined" {
    [ -n "$AIWB_ERROR_RETRY_DELAY" ]
    [ "$AIWB_ERROR_RETRY_DELAY" -eq 60 ]
}

@test "AIWB_RESPONSE_LINES_THRESHOLD is defined" {
    [ -n "$AIWB_RESPONSE_LINES_THRESHOLD" ]
    [ "$AIWB_RESPONSE_LINES_THRESHOLD" -eq 100 ]
}

@test "AIWB_EDITOR_PREVIEW_THRESHOLD is defined" {
    [ -n "$AIWB_EDITOR_PREVIEW_THRESHOLD" ]
    [ "$AIWB_EDITOR_PREVIEW_THRESHOLD" -eq 30 ]
}

@test "AIWB_MIN_API_KEY_LENGTH is defined" {
    [ -n "$AIWB_MIN_API_KEY_LENGTH" ]
    [ "$AIWB_MIN_API_KEY_LENGTH" -eq 30 ]
}

@test "AIWB_CONTEXT_STATE_MAX_AGE_DAYS is defined" {
    [ -n "$AIWB_CONTEXT_STATE_MAX_AGE_DAYS" ]
    [ "$AIWB_CONTEXT_STATE_MAX_AGE_DAYS" -eq 7 ]
}

@test "AIWB_HTTP_ERROR_THRESHOLD is defined" {
    [ -n "$AIWB_HTTP_ERROR_THRESHOLD" ]
    [ "$AIWB_HTTP_ERROR_THRESHOLD" -eq 400 ]
}

@test "AIWB_EXIT_SUCCESS is defined" {
    [ -n "$AIWB_EXIT_SUCCESS" ]
    [ "$AIWB_EXIT_SUCCESS" -eq 0 ]
}

@test "AIWB_EXIT_ERROR is defined" {
    [ -n "$AIWB_EXIT_ERROR" ]
    [ "$AIWB_EXIT_ERROR" -eq 1 ]
}

@test "AIWB_EXIT_SIGINT is defined" {
    [ -n "$AIWB_EXIT_SIGINT" ]
    [ "$AIWB_EXIT_SIGINT" -eq 130 ]
}

# ============================================================================
# CONFIGURATION FUNCTION TESTS
# ============================================================================

@test "get_default_model returns valid model for gemini" {
    run get_default_model "gemini"
    [ "$status" -eq 0 ]
    [ "$output" = "2.5-flash" ]
}

@test "get_default_model returns valid model for claude" {
    run get_default_model "claude"
    [ "$status" -eq 0 ]
    [ "$output" = "haiku-4-5-20251001" ]
}

@test "get_default_model returns valid model for openai" {
    run get_default_model "openai"
    [ "$status" -eq 0 ]
    [ "$output" = "gpt-4o-mini-2024-07-18" ]
}

@test "get_available_models returns non-empty list for gemini" {
    run get_available_models "gemini"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "2.5-flash" ]]
}

@test "get_available_models returns non-empty list for claude" {
    run get_available_models "claude"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "haiku" ]]
}
