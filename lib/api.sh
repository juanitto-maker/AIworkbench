#!/usr/bin/env bash
# api.sh - API interaction helpers for AIWB

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[[ -z "${AIWB_LIB_CONFIG_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# ============================================================================
# ERROR DISPLAY HELPERS
# ============================================================================

# Display complete API error with all details
display_api_error() {
    local provider="$1"
    local error_msg="$2"
    local response="${3:-}"
    local model="${4:-}"
    local http_code="${5:-}"

    echo "" >&2
    err "═══════════════════════════════════════════════════════════════"
    err "API ERROR - Complete Details"
    err "═══════════════════════════════════════════════════════════════"
    err ""
    err "Provider: $provider"
    [[ -n "$model" ]] && err "Model: $model"
    [[ -n "$http_code" ]] && err "HTTP Status Code: $http_code"
    err ""
    err "Error Message:"
    err "  $error_msg"
    err ""

    # Display full response if available
    if [[ -n "$response" ]]; then
        err "Full API Response:"
        # Pretty print JSON if possible, otherwise show raw
        if echo "$response" | jq -e . >/dev/null 2>&1; then
            echo "$response" | jq -C '.' 2>/dev/null | while IFS= read -r line; do
                err "  $line"
            done
        else
            err "  $response"
        fi
    fi

    err ""
    err "═══════════════════════════════════════════════════════════════"
    echo "" >&2
}

# ============================================================================
# API KEY MANAGEMENT
# ============================================================================

# Get API key for provider
get_api_key() {
    local provider="$1"
    local env_file
    env_file="$(get_env_file)"

    # Source env file if exists
    [[ -f "$env_file" ]] && source "$env_file"

    case "$provider" in
        gemini)
            echo "${GEMINI_API_KEY:-}"
            ;;
        claude)
            echo "${ANTHROPIC_API_KEY:-}"
            ;;
        openai)
            echo "${OPENAI_API_KEY:-}"
            ;;
        groq)
            echo "${GROQ_API_KEY:-}"
            ;;
        xai)
            echo "${XAI_API_KEY:-}"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Check if API key is set
has_api_key() {
    local provider="$1"
    local key
    key="$(get_api_key "$provider")"
    [[ -n "$key" ]]
}

# ============================================================================
# TOKEN ESTIMATION
# ============================================================================

# Estimate token count (rough approximation)
estimate_tokens() {
    local text="$1"
    # Rough estimate: 1 token ≈ 4 characters
    local chars=${#text}
    echo $((chars / 4))
}

# Read file and estimate tokens
estimate_file_tokens() {
    local file="$1"
    [[ ! -f "$file" ]] && { err "File not found: $file"; return 1; }

    local content
    content="$(cat "$file")"
    estimate_tokens "$content"
}

# ============================================================================
# API CALLS - GEMINI
# ============================================================================

call_gemini() {
    local prompt="$1"
    local model="${2:-gemini-2.5-flash}"
    local max_tokens="${3:-16000}"
    local temperature="${4:-0.2}"

    local api_key
    api_key="$(get_api_key gemini)"
    [[ -z "$api_key" ]] && { err "GEMINI_API_KEY not set"; return 1; }

    local url="https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${api_key}"

    local request_body
    request_body=$(jq -n \
        --arg text "$prompt" \
        --argjson max "$max_tokens" \
        --argjson temp "$temperature" \
        '{
            contents: [{role: "user", parts: [{text: $text}]}],
            generationConfig: {
                temperature: $temp,
                maxOutputTokens: $max
            }
        }')

    local response
    local curl_error curl_output
    curl_error=$(mktemp -t aiwb_curl_err_XXXXXX)
    curl_output=$(mktemp -t aiwb_curl_out_XXXXXX)

    # Use curl with proper output/error separation and make it interruptible
    set +e  # Temporarily disable exit on error
    curl -fsS \
        --max-time 300 \
        --connect-timeout 10 \
        --no-buffer \
        -H "Content-Type: application/json" \
        -X POST "$url" \
        -d "$request_body" \
        -o "$curl_output" \
        2>"$curl_error" &
    local curl_pid=$!

    # Wait for curl to complete and check for interrupts
    wait $curl_pid
    local exit_code=$?
    set -e  # Re-enable exit on error

    # Check if interrupted (exit code 130 is SIGINT)
    if [[ $exit_code -eq 130 ]]; then
        rm -f "$curl_error" "$curl_output"
        echo "" >&2
        err "Request interrupted by user"
        return 130
    fi

    if [[ $exit_code -ne 0 ]]; then
        local error_msg error_code
        local response_data=$(cat "$curl_output" 2>/dev/null || echo "")
        local curl_error_msg=$(cat "$curl_error" 2>/dev/null || echo "Curl failed with exit code $exit_code")

        # Try to extract actual API error from response
        if [[ -n "$response_data" ]] && echo "$response_data" | jq -e '.error' >/dev/null 2>&1; then
            error_msg=$(echo "$response_data" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
            error_code=$(echo "$response_data" | jq -r '.error.code // ""' 2>/dev/null)
        else
            # Fallback to curl error if no JSON error
            error_msg="$curl_error_msg"
            error_code="$exit_code"
        fi

        rm -f "$curl_error" "$curl_output"
        display_api_error "Gemini" "$error_msg" "$response_data" "$model" "$error_code"
        return 1
    fi

    response=$(cat "$curl_output" 2>/dev/null || echo "")
    rm -f "$curl_error" "$curl_output"

    # Check for API errors in response
    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        local api_error_msg api_error_code
        api_error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"')
        api_error_code=$(echo "$response" | jq -r '.error.code // ""' 2>/dev/null)
        display_api_error "Gemini" "$api_error_msg" "$response" "$model" "$api_error_code"
        return 1
    fi

    # Extract text from response
    local text
    text=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null)

    if [[ -z "$text" ]]; then
        # Check for error in response
        local error_msg error_code
        error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error or empty response"' 2>/dev/null)
        error_code=$(echo "$response" | jq -r '.error.code // ""' 2>/dev/null)
        display_api_error "Gemini" "$error_msg" "$response" "$model" "$error_code"
        return 1
    fi

    echo "$text"
}

# Stream Gemini response (if supported)
stream_gemini() {
    local prompt="$1"
    local model="${2:-gemini-1.5-flash}"

    # Note: Streaming requires different API endpoint and handling
    # For now, fall back to regular call
    call_gemini "$prompt" "$model"
}

# ============================================================================
# API CALLS - CLAUDE
# ============================================================================

call_claude() {
    local prompt="$1"
    local model="${2:-claude-3-haiku-20240307}"
    local max_tokens="${3:-4096}"  # Claude 3 Haiku max is 4096
    local temperature="${4:-0.2}"

    local api_key
    api_key="$(get_api_key claude)"
    [[ -z "$api_key" ]] && { err "ANTHROPIC_API_KEY not set"; return 1; }

    local url="https://api.anthropic.com/v1/messages"

    local request_body
    request_body=$(jq -n \
        --arg model "$model" \
        --arg content "$prompt" \
        --argjson max "$max_tokens" \
        --argjson temp "$temperature" \
        '{
            model: $model,
            max_tokens: $max,
            temperature: $temp,
            messages: [{role: "user", content: $content}]
        }')

    local response
    local curl_error curl_output
    curl_error=$(mktemp -t aiwb_curl_err_XXXXXX)
    curl_output=$(mktemp -t aiwb_curl_out_XXXXXX)

    # Use curl with proper output/error separation and make it interruptible
    set +e  # Temporarily disable exit on error
    curl -sS "$url" \
        --max-time 300 \
        --connect-timeout 10 \
        --no-buffer \
        -H "x-api-key: $api_key" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "$request_body" \
        -o "$curl_output" \
        2>"$curl_error" &
    local curl_pid=$!

    # Wait for curl to complete and check for interrupts
    wait $curl_pid
    local exit_code=$?
    set -e  # Re-enable exit on error

    # Check if interrupted (exit code 130 is SIGINT)
    if [[ $exit_code -eq 130 ]]; then
        rm -f "$curl_error" "$curl_output"
        echo "" >&2
        err "Request interrupted by user"
        return 130
    fi

    # Check for curl errors
    if [[ $exit_code -ne 0 ]]; then
        local error_msg
        error_msg=$(cat "$curl_error" 2>/dev/null || echo "Curl failed with exit code $exit_code")
        local response_data=$(cat "$curl_output" 2>/dev/null || echo "")
        rm -f "$curl_error" "$curl_output"
        display_api_error "Claude" "$error_msg" "$response_data" "$model" "$exit_code"
        return 1
    fi

    response=$(cat "$curl_output" 2>/dev/null || echo "")
    rm -f "$curl_error" "$curl_output"

    # Check for API errors in response
    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        local api_error_type api_error_msg api_error_code
        api_error_type=$(echo "$response" | jq -r '.error.type // ""')
        api_error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"')
        api_error_code=$(echo "$response" | jq -r '.error.status_code // ""' 2>/dev/null)
        local full_error="$api_error_type: $api_error_msg"
        display_api_error "Claude" "$full_error" "$response" "$model" "$api_error_code"
        return 1
    fi

    # Extract text from response
    local text
    text=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null)

    if [[ -z "$text" ]]; then
        # Check for error in response
        local error_msg
        error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error or empty response"' 2>/dev/null)
        display_api_error "Claude" "$error_msg" "$response" "$model"
        return 1
    fi

    echo "$text"
}

# ============================================================================
# API CALLS - OPENAI
# ============================================================================

call_openai() {
    local prompt="$1"
    local model="${2:-gpt-4o-mini}"
    local max_tokens="${3:-16000}"
    local temperature="${4:-0.2}"

    local api_key
    api_key="$(get_api_key openai)"
    [[ -z "$api_key" ]] && { err "OPENAI_API_KEY not set"; return 1; }

    local url="https://api.openai.com/v1/chat/completions"

    local request_body
    request_body=$(jq -n \
        --arg model "$model" \
        --arg content "$prompt" \
        --argjson max "$max_tokens" \
        --argjson temp "$temperature" \
        '{
            model: $model,
            max_tokens: $max,
            temperature: $temp,
            messages: [{role: "user", content: $content}]
        }')

    local response
    local curl_error curl_output
    curl_error=$(mktemp -t aiwb_curl_err_XXXXXX)
    curl_output=$(mktemp -t aiwb_curl_out_XXXXXX)

    # Use curl with proper output/error separation and make it interruptible
    set +e  # Temporarily disable exit on error
    curl -fsS "$url" \
        --max-time 300 \
        --connect-timeout 10 \
        --no-buffer \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d "$request_body" \
        -o "$curl_output" \
        2>"$curl_error" &
    local curl_pid=$!

    # Wait for curl to complete and check for interrupts
    wait $curl_pid
    local exit_code=$?
    set -e  # Re-enable exit on error

    # Check if interrupted (exit code 130 is SIGINT)
    if [[ $exit_code -eq 130 ]]; then
        rm -f "$curl_error" "$curl_output"
        echo "" >&2
        err "Request interrupted by user"
        return 130
    fi

    if [[ $exit_code -ne 0 ]]; then
        local error_msg error_code
        local response_data=$(cat "$curl_output" 2>/dev/null || echo "")
        local curl_error_msg=$(cat "$curl_error" 2>/dev/null || echo "Curl failed with exit code $exit_code")

        # Try to extract actual API error from response
        if [[ -n "$response_data" ]] && echo "$response_data" | jq -e '.error' >/dev/null 2>&1; then
            error_msg=$(echo "$response_data" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
            error_code=$(echo "$response_data" | jq -r '.error.code // ""' 2>/dev/null)

            # Add helpful context for common errors
            if [[ "$error_msg" == *"does not exist"* ]] || [[ "$error_msg" == *"model_not_found"* ]]; then
                error_msg="$error_msg

Possible reasons:
  - The model name is incorrect or doesn't exist
  - The model hasn't been released yet (e.g., gpt-5 is not available)
  - You don't have access to this model with your API key

Available OpenAI models: gpt-4o, gpt-4o-mini, gpt-4-turbo, o1, o1-mini, o3-mini"
            fi
        else
            # Fallback to curl error if no JSON error
            error_msg="$curl_error_msg"
            error_code="$exit_code"
        fi

        rm -f "$curl_error" "$curl_output"
        display_api_error "OpenAI" "$error_msg" "$response_data" "$model" "$error_code"
        return 1
    fi

    response=$(cat "$curl_output" 2>/dev/null || echo "")
    rm -f "$curl_error" "$curl_output"

    # Check for API errors in response (even with 200 status)
    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        local api_error_msg api_error_code
        api_error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"')
        api_error_code=$(echo "$response" | jq -r '.error.code // ""' 2>/dev/null)
        display_api_error "OpenAI" "$api_error_msg" "$response" "$model" "$api_error_code"
        return 1
    fi

    # Extract text from response
    local text
    text=$(echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null)

    if [[ -z "$text" ]]; then
        # Check for error in response
        local error_msg error_code
        error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error or empty response"' 2>/dev/null)
        error_code=$(echo "$response" | jq -r '.error.code // ""' 2>/dev/null)
        display_api_error "OpenAI" "$error_msg" "$response" "$model" "$error_code"
        return 1
    fi

    echo "$text"
}

# ============================================================================
# API CALLS - GROQ
# ============================================================================

call_groq() {
    local prompt="$1"
    local model="${2:-llama-3.3-70b-versatile}"
    local max_tokens="${3:-16000}"
    local temperature="${4:-0.2}"

    local api_key
    api_key="$(get_api_key groq)"
    [[ -z "$api_key" ]] && { err "GROQ_API_KEY not set"; return 1; }

    local url="https://api.groq.com/openai/v1/chat/completions"

    local request_body
    request_body=$(jq -n \
        --arg model "$model" \
        --arg content "$prompt" \
        --argjson max "$max_tokens" \
        --argjson temp "$temperature" \
        '{
            model: $model,
            max_tokens: $max,
            temperature: $temp,
            messages: [{role: "user", content: $content}]
        }')

    local response
    local curl_error curl_output
    curl_error=$(mktemp -t aiwb_curl_err_XXXXXX)
    curl_output=$(mktemp -t aiwb_curl_out_XXXXXX)

    # Use curl with proper output/error separation and make it interruptible
    set +e  # Temporarily disable exit on error
    curl -fsS "$url" \
        --max-time 300 \
        --connect-timeout 10 \
        --no-buffer \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d "$request_body" \
        -o "$curl_output" \
        2>"$curl_error" &
    local curl_pid=$!

    # Wait for curl to complete and check for interrupts
    wait $curl_pid
    local exit_code=$?
    set -e  # Re-enable exit on error

    # Check if interrupted (exit code 130 is SIGINT)
    if [[ $exit_code -eq 130 ]]; then
        rm -f "$curl_error" "$curl_output"
        echo "" >&2
        err "Request interrupted by user"
        return 130
    fi

    if [[ $exit_code -ne 0 ]]; then
        local error_msg error_code
        local response_data=$(cat "$curl_output" 2>/dev/null || echo "")
        local curl_error_msg=$(cat "$curl_error" 2>/dev/null || echo "Curl failed with exit code $exit_code")

        # Try to extract actual API error from response
        if [[ -n "$response_data" ]] && echo "$response_data" | jq -e '.error' >/dev/null 2>&1; then
            error_msg=$(echo "$response_data" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
            error_code=$(echo "$response_data" | jq -r '.error.code // ""' 2>/dev/null)
        else
            # Fallback to curl error if no JSON error
            error_msg="$curl_error_msg"
            error_code="$exit_code"
        fi

        rm -f "$curl_error" "$curl_output"
        display_api_error "Groq" "$error_msg" "$response_data" "$model" "$error_code"
        return 1
    fi

    response=$(cat "$curl_output" 2>/dev/null || echo "")
    rm -f "$curl_error" "$curl_output"

    # Validate JSON response
    if ! validate_json "$response"; then
        display_api_error "Groq" "Invalid JSON response from API" "$response" "$model"
        return 1
    fi

    # Check for API errors in response
    local api_error error_code
    api_error=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
    error_code=$(echo "$response" | jq -r '.error.code // ""' 2>/dev/null)
    if [[ -n "$api_error" ]]; then
        display_api_error "Groq" "$api_error" "$response" "$model" "$error_code"
        return 1
    fi

    # Extract text from response (OpenAI-compatible format)
    local text
    text=$(echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null)

    if [[ -z "$text" ]]; then
        # Try alternative error format
        local error_msg
        error_msg=$(echo "$response" | jq -r '.error // "No response or empty content from API"' 2>/dev/null)
        display_api_error "Groq" "$error_msg" "$response" "$model"
        return 1
    fi

    echo "$text"
}

# ============================================================================
# API CALLS - XAI (Grok)
# ============================================================================

call_xai() {
    local prompt="$1"
    local model="${2:-grok-3}"
    local max_tokens="${3:-16000}"
    local temperature="${4:-0.2}"

    local api_key
    api_key="$(get_api_key xai)"
    [[ -z "$api_key" ]] && { err "XAI_API_KEY not set"; return 1; }

    local url="https://api.x.ai/v1/chat/completions"

    local request_body
    request_body=$(jq -n \
        --arg model "$model" \
        --arg content "$prompt" \
        --argjson max "$max_tokens" \
        --argjson temp "$temperature" \
        '{
            model: $model,
            max_tokens: $max,
            temperature: $temp,
            messages: [{role: "user", content: $content}]
        }')

    local response
    local curl_error curl_output
    curl_error=$(mktemp -t aiwb_curl_err_XXXXXX)
    curl_output=$(mktemp -t aiwb_curl_out_XXXXXX)

    # Use curl with proper output/error separation and make it interruptible
    set +e  # Temporarily disable exit on error
    curl -fsS "$url" \
        --max-time 300 \
        --connect-timeout 10 \
        --no-buffer \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d "$request_body" \
        -o "$curl_output" \
        2>"$curl_error" &
    local curl_pid=$!

    # Wait for curl to complete and check for interrupts
    wait $curl_pid
    local exit_code=$?
    set -e  # Re-enable exit on error

    # Check if interrupted (exit code 130 is SIGINT)
    if [[ $exit_code -eq 130 ]]; then
        rm -f "$curl_error" "$curl_output"
        echo "" >&2
        err "Request interrupted by user"
        return 130
    fi

    if [[ $exit_code -ne 0 ]]; then
        local error_msg error_code
        local response_data=$(cat "$curl_output" 2>/dev/null || echo "")
        local curl_error_msg=$(cat "$curl_error" 2>/dev/null || echo "Curl failed with exit code $exit_code")

        # Try to extract actual API error from response
        if [[ -n "$response_data" ]] && echo "$response_data" | jq -e '.error' >/dev/null 2>&1; then
            error_msg=$(echo "$response_data" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
            error_code=$(echo "$response_data" | jq -r '.error.code // ""' 2>/dev/null)
        else
            # Fallback to curl error if no JSON error
            error_msg="$curl_error_msg"
            error_code="$exit_code"
        fi

        rm -f "$curl_error" "$curl_output"
        display_api_error "xAI (Grok)" "$error_msg" "$response_data" "$model" "$error_code"
        return 1
    fi

    response=$(cat "$curl_output" 2>/dev/null || echo "")
    rm -f "$curl_error" "$curl_output"

    # Validate JSON response
    if ! validate_json "$response"; then
        display_api_error "xAI (Grok)" "Invalid JSON response from API" "$response" "$model"
        return 1
    fi

    # Check for API errors in response
    local api_error error_code
    api_error=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
    error_code=$(echo "$response" | jq -r '.error.code // ""' 2>/dev/null)
    if [[ -n "$api_error" ]]; then
        display_api_error "xAI (Grok)" "$api_error" "$response" "$model" "$error_code"
        return 1
    fi

    # Extract text from response (OpenAI-compatible format)
    local text
    text=$(echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null)

    if [[ -z "$text" ]]; then
        # Try alternative error format
        local error_msg
        error_msg=$(echo "$response" | jq -r '.error // "No response or empty content from API"' 2>/dev/null)
        display_api_error "xAI (Grok)" "$error_msg" "$response" "$model"
        return 1
    fi

    echo "$text"
}

# ============================================================================
# API CALLS - OLLAMA (Local)
# ============================================================================

call_ollama() {
    local prompt="$1"
    local model="${2:-llama3.2:latest}"
    local endpoint="${OLLAMA_ENDPOINT:-http://localhost:11434}"

    if ! have ollama && ! curl -fsS "$endpoint" >/dev/null 2>&1; then
        err "Ollama not available. Install from https://ollama.ai"
        return 1
    fi

    local url="$endpoint/api/generate"

    local request_body
    request_body=$(jq -n \
        --arg model "$model" \
        --arg prompt "$prompt" \
        '{
            model: $model,
            prompt: $prompt,
            stream: false
        }')

    local response
    local curl_error curl_output
    curl_error=$(mktemp -t aiwb_curl_err_XXXXXX)
    curl_output=$(mktemp -t aiwb_curl_out_XXXXXX)

    # Use curl with proper output/error separation and make it interruptible
    set +e  # Temporarily disable exit on error
    curl -fsS "$url" \
        --max-time 300 \
        --connect-timeout 10 \
        --no-buffer \
        -H "Content-Type: application/json" \
        -d "$request_body" \
        -o "$curl_output" \
        2>"$curl_error" &
    local curl_pid=$!

    # Wait for curl to complete and check for interrupts
    wait $curl_pid
    local exit_code=$?
    set -e  # Re-enable exit on error

    # Check if interrupted (exit code 130 is SIGINT)
    if [[ $exit_code -eq 130 ]]; then
        rm -f "$curl_error" "$curl_output"
        echo "" >&2
        err "Request interrupted by user"
        return 130
    fi

    if [[ $exit_code -ne 0 ]]; then
        local error_msg error_code
        local response_data=$(cat "$curl_output" 2>/dev/null || echo "")
        local curl_error_msg=$(cat "$curl_error" 2>/dev/null || echo "Curl failed with exit code $exit_code")

        # Try to extract actual API error from response
        if [[ -n "$response_data" ]] && echo "$response_data" | jq -e '.error' >/dev/null 2>&1; then
            error_msg=$(echo "$response_data" | jq -r '.error // "Unknown error"' 2>/dev/null)
            error_code="$exit_code"
        else
            # Fallback to curl error if no JSON error
            error_msg="$curl_error_msg"
            error_code="$exit_code"
        fi

        rm -f "$curl_error" "$curl_output"
        display_api_error "Ollama" "$error_msg" "$response_data" "$model" "$error_code"
        return 1
    fi

    response=$(cat "$curl_output" 2>/dev/null || echo "")
    rm -f "$curl_error" "$curl_output"

    # Extract response
    local text
    text=$(echo "$response" | jq -r '.response // empty' 2>/dev/null)

    if [[ -z "$text" ]]; then
        local error_msg
        error_msg=$(echo "$response" | jq -r '.error // "No response from Ollama"' 2>/dev/null)
        display_api_error "Ollama" "$error_msg" "$response" "$model"
        return 1
    fi

    echo "$text"
}

# ============================================================================
# UNIFIED API CALL
# ============================================================================

# Call API based on configured provider
call_api() {
    local prompt="$1"
    local provider="${2:-$(config_get model_provider)}"
    local model="${3:-$(config_get model_name)}"
    local max_tokens="${4:-}"

    # Set appropriate max_tokens based on provider/model if not specified
    if [[ -z "$max_tokens" ]]; then
        case "$provider" in
            claude)
                # Claude 3 Haiku has 4096 max, Sonnet/Opus have 8192
                if [[ "$model" == *"haiku"* ]]; then
                    max_tokens=4096
                else
                    max_tokens=8192
                fi
                ;;
            *)
                max_tokens=16000
                ;;
        esac
    fi

    debug "Calling $provider API with model $model (max_tokens: $max_tokens)"

    case "$provider" in
        gemini)
            call_gemini "$prompt" "gemini-${model}" "$max_tokens"
            ;;
        claude)
            call_claude "$prompt" "claude-${model}" "$max_tokens"
            ;;
        openai)
            call_openai "$prompt" "$model" "$max_tokens"
            ;;
        groq)
            call_groq "$prompt" "$model" "$max_tokens"
            ;;
        xai)
            call_xai "$prompt" "$model" "$max_tokens"
            ;;
        ollama)
            call_ollama "$prompt" "$model"
            ;;
        *)
            err "Unknown provider: $provider"
            return 1
            ;;
    esac
}

# ============================================================================
# COST CALCULATION
# ============================================================================

# Get pricing for model (per 1M tokens)
get_pricing() {
    local provider="$1"
    local model="$2"
    local token_type="${3:-input}"  # input or output

    # Pricing as of 2025 (updated with latest models)
    case "$provider" in
        gemini)
            case "$model" in
                *2.5-flash-lite*|*flash-2.5-lite*) [[ "$token_type" == "input" ]] && echo "0.10" || echo "0.40" ;;
                *2.5-flash*|*flash-2.5*)           [[ "$token_type" == "input" ]] && echo "0.30" || echo "2.50" ;;
                *2.5-pro*|*pro-2.5*)               [[ "$token_type" == "input" ]] && echo "1.25" || echo "10.00" ;;
                *2.0-flash-lite*|*flash-2.0-lite*) [[ "$token_type" == "input" ]] && echo "0.075" || echo "0.30" ;;
                *flash*)                           [[ "$token_type" == "input" ]] && echo "0.075" || echo "0.30" ;;
                *pro*)                             [[ "$token_type" == "input" ]] && echo "1.25" || echo "5.00" ;;
                *) echo "0.30" ;;
            esac
            ;;
        claude)
            case "$model" in
                *haiku-4.5*|*4.5-haiku*) [[ "$token_type" == "input" ]] && echo "1.00" || echo "5.00" ;;
                *haiku*)                 [[ "$token_type" == "input" ]] && echo "0.25" || echo "1.25" ;;
                *sonnet-4.5*|*4.5-sonnet*|*sonnet-4*|*4-sonnet*) [[ "$token_type" == "input" ]] && echo "3.00" || echo "15.00" ;;
                *sonnet*)                [[ "$token_type" == "input" ]] && echo "3.00" || echo "15.00" ;;
                *opus-4.1*|*4.1-opus*)   [[ "$token_type" == "input" ]] && echo "15.00" || echo "75.00" ;;
                *opus*)                  [[ "$token_type" == "input" ]] && echo "15.00" || echo "75.00" ;;
                *) echo "3.00" ;;
            esac
            ;;
        openai)
            case "$model" in
                *gpt-5-nano*)  [[ "$token_type" == "input" ]] && echo "0.05" || echo "0.40" ;;
                *gpt-5-mini*)  [[ "$token_type" == "input" ]] && echo "0.25" || echo "2.00" ;;
                *gpt-5*)       [[ "$token_type" == "input" ]] && echo "1.25" || echo "10.00" ;;
                *o4-mini*)     [[ "$token_type" == "input" ]] && echo "0.60" || echo "2.40" ;;
                *o3*)          [[ "$token_type" == "input" ]] && echo "2.50" || echo "10.00" ;;
                *gpt-4o-mini*) [[ "$token_type" == "input" ]] && echo "0.15" || echo "0.60" ;;
                *gpt-4o*)      [[ "$token_type" == "input" ]] && echo "2.50" || echo "10.00" ;;
                *o1*)          [[ "$token_type" == "input" ]] && echo "2.50" || echo "10.00" ;;
                *) echo "0.15" ;;
            esac
            ;;
        groq)
            # Groq pricing updated with Llama 4 models
            case "$model" in
                *llama-4-maverick*) [[ "$token_type" == "input" ]] && echo "0.50" || echo "0.77" ;;
                *llama-4-scout*)    [[ "$token_type" == "input" ]] && echo "0.11" || echo "0.34" ;;
                *llama-3.3-70b*)    [[ "$token_type" == "input" ]] && echo "0.059" || echo "0.079" ;;
                *llama-3.2*)        [[ "$token_type" == "input" ]] && echo "0.005" || echo "0.008" ;;
                *mixtral*)          [[ "$token_type" == "input" ]] && echo "0.024" || echo "0.024" ;;
                *gemma*)            [[ "$token_type" == "input" ]] && echo "0.005" || echo "0.008" ;;
                *) echo "0.05" ;;
            esac
            ;;
        xai)
            # xAI Grok pricing updated with Grok 3 and 4
            case "$model" in
                *grok-4-heavy*)   [[ "$token_type" == "input" ]] && echo "3.00" || echo "15.00" ;;
                *grok-4-fast*)    [[ "$token_type" == "input" ]] && echo "0.20" || echo "0.50" ;;
                *grok-4*)         [[ "$token_type" == "input" ]] && echo "3.00" || echo "15.00" ;;
                *grok-3-mini*)    [[ "$token_type" == "input" ]] && echo "0.30" || echo "0.50" ;;
                *grok-3*)         [[ "$token_type" == "input" ]] && echo "3.00" || echo "15.00" ;;
                *grok-beta*)      [[ "$token_type" == "input" ]] && echo "5.00" || echo "15.00" ;;
                *grok-code-fast*) [[ "$token_type" == "input" ]] && echo "5.00" || echo "15.00" ;;
                *grok-2*)         [[ "$token_type" == "input" ]] && echo "2.00" || echo "10.00" ;;
                *) echo "3.00" ;;
            esac
            ;;
        ollama)
            echo "0"  # Local, no cost
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Calculate cost
calculate_cost() {
    local provider="$1"
    local model="$2"
    local input_tokens="$3"
    local output_tokens="$4"

    local input_price output_price
    input_price="$(get_pricing "$provider" "$model" "input")"
    output_price="$(get_pricing "$provider" "$model" "output")"

    # Calculate in dollars (per 1M tokens)
    local input_cost output_cost total_cost
    input_cost=$(awk "BEGIN {printf \"%.6f\", ($input_tokens / 1000000) * $input_price}")
    output_cost=$(awk "BEGIN {printf \"%.6f\", ($output_tokens / 1000000) * $output_price}")
    total_cost=$(awk "BEGIN {printf \"%.6f\", $input_cost + $output_cost}")

    echo "$total_cost"
}

# ============================================================================
# EXPORTS
# ============================================================================

export AIWB_LIB_API_LOADED=1
