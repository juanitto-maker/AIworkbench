#!/usr/bin/env bats
# test_api.bats - Unit tests for lib/api.sh

# Setup: Source the required libraries
setup() {
    # Set up test environment
    export AIWB_TEST_MODE=1
    export AIWB_CONFIG_DIR="${BATS_TMPDIR}/aiwb_test_$$"
    mkdir -p "$AIWB_CONFIG_DIR"

    # Create a minimal env file for testing
    cat > "${AIWB_CONFIG_DIR}/.aiwb.env" <<EOF
export GEMINI_API_KEY="test_gemini_key"
export ANTHROPIC_API_KEY="test_claude_key"
export OPENAI_API_KEY="test_openai_key"
EOF

    load_lib() {
        source "${BATS_TEST_DIRNAME}/../lib/common.sh"
        source "${BATS_TEST_DIRNAME}/../lib/config.sh"
        source "${BATS_TEST_DIRNAME}/../lib/api.sh"
    }
}

# Teardown: Clean up test environment
teardown() {
    rm -rf "$AIWB_CONFIG_DIR"
}

# ============================================================================
# API KEY MANAGEMENT TESTS
# ============================================================================

@test "get_api_key returns key for valid provider" {
    load_lib
    export GEMINI_API_KEY="test_key_123"
    run get_api_key "gemini"
    [ "$status" -eq 0 ]
    [ "$output" = "test_key_123" ]
}

@test "get_api_key returns empty for invalid provider" {
    load_lib
    run get_api_key "invalid_provider"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "has_api_key returns 0 when key is set" {
    load_lib
    export ANTHROPIC_API_KEY="test_key_456"
    run has_api_key "claude"
    [ "$status" -eq 0 ]
}

@test "has_api_key returns 1 when key is not set" {
    load_lib
    unset GROQ_API_KEY
    run has_api_key "groq"
    [ "$status" -eq 1 ]
}

@test "get_api_key supports multiple providers" {
    load_lib
    export GEMINI_API_KEY="gemini_key"
    export ANTHROPIC_API_KEY="claude_key"
    export OPENAI_API_KEY="openai_key"
    export GROQ_API_KEY="groq_key"
    export XAI_API_KEY="xai_key"

    providers=("gemini" "claude" "openai" "groq" "xai")
    for provider in "${providers[@]}"; do
        key=$(get_api_key "$provider")
        [ -n "$key" ]
    done
}

# ============================================================================
# IMAGE HANDLING TESTS
# ============================================================================

@test "is_image_file detects jpg" {
    load_lib
    run is_image_file "photo.jpg"
    [ "$status" -eq 0 ]
}

@test "is_image_file detects png" {
    load_lib
    run is_image_file "image.png"
    [ "$status" -eq 0 ]
}

@test "is_image_file detects uppercase extensions" {
    load_lib
    run is_image_file "PHOTO.JPG"
    [ "$status" -eq 0 ]
}

@test "is_image_file rejects non-image" {
    load_lib
    run is_image_file "document.txt"
    [ "$status" -eq 1 ]
}

@test "get_image_mime_type returns correct MIME for jpg" {
    load_lib
    run get_image_mime_type "photo.jpg"
    [ "$status" -eq 0 ]
    [ "$output" = "image/jpeg" ]
}

@test "get_image_mime_type returns correct MIME for png" {
    load_lib
    run get_image_mime_type "image.png"
    [ "$status" -eq 0 ]
    [ "$output" = "image/png" ]
}

@test "get_image_mime_type returns correct MIME for gif" {
    load_lib
    run get_image_mime_type "animation.gif"
    [ "$status" -eq 0 ]
    [ "$output" = "image/gif" ]
}

@test "get_image_mime_type returns correct MIME for webp" {
    load_lib
    run get_image_mime_type "photo.webp"
    [ "$status" -eq 0 ]
    [ "$output" = "image/webp" ]
}

# ============================================================================
# API ENDPOINT TESTS
# ============================================================================

@test "get_api_endpoint_for_provider returns valid endpoint for gemini" {
    load_lib
    run get_api_endpoint_for_provider "gemini"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^https:// ]]
}

@test "get_api_endpoint_for_provider returns valid endpoint for claude" {
    load_lib
    run get_api_endpoint_for_provider "claude"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^https:// ]]
}

@test "get_api_endpoint_for_provider returns valid endpoint for openai" {
    load_lib
    run get_api_endpoint_for_provider "openai"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^https:// ]]
}

@test "get_api_endpoint_for_provider returns Unknown for invalid provider" {
    load_lib
    run get_api_endpoint_for_provider "invalid_provider"
    [ "$status" -eq 0 ]
    [ "$output" = "Unknown" ]
}
