#!/usr/bin/env bash
# api.sh - API interaction helpers for AIWB

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[[ -z "${AIWB_LIB_CONFIG_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# ============================================================================
# ERROR DISPLAY HELPERS
# ============================================================================

#############################
# Display complete API error with all details
#
# Shows formatted error information including provider details, error message,
# full API response (if available), and troubleshooting suggestions.
#
# Arguments:
#   $1 - provider name (gemini|claude|openai|groq|xai|ollama)
#   $2 - error message string
#   $3 - optional full API response (for debugging)
#   $4 - optional model name
#   $5 - optional HTTP status code
# Returns:
#   None (outputs to stderr)
# Example:
#   display_api_error "gemini" "Invalid API key" "$response" "gemini-pro" "401"
#############################
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
        err "Full API Response (DEBUG):"
        # Pretty print JSON if possible, otherwise show raw
        if echo "$response" | jq -e . >/dev/null 2>&1; then
            echo "$response" | jq -C '.' 2>/dev/null | while IFS= read -r line; do
                err "  $line"
            done
        else
            err "  $response"
        fi
        err ""
    fi

    # Add debug information section
    err "DEBUG Information:"
    err "  API Endpoint: $(get_api_endpoint_for_provider "$provider")"
    err "  API Key Set: $(has_api_key "$provider" && echo "Yes" || echo "No")"
    err "  Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"

    # Add troubleshooting tips
    err ""
    err "Common Solutions:"
    err "  1. Verify API key is correct and has proper permissions"
    err "  2. Check if model name is valid for this provider"
    err "  3. Ensure you have credits/quota available"
    err "  4. Try a different model from the available list"

    err ""
    err "═══════════════════════════════════════════════════════════════"
    echo "" >&2
}

#############################
# Get API endpoint URL for a given provider
#
# Returns the base API endpoint URL for the specified AI provider.
# Used primarily for debugging and error reporting.
#
# Arguments:
#   $1 - provider name (gemini|claude|openai|groq|xai|ollama)
# Returns:
#   API endpoint URL string, or "Unknown" if provider not recognized
# Example:
#   endpoint=$(get_api_endpoint_for_provider "claude")
#   # Returns: https://api.anthropic.com/v1/messages
#############################
get_api_endpoint_for_provider() {
    local provider="$1"
    case "$provider" in
        gemini) echo "https://generativelanguage.googleapis.com/v1beta/models" ;;
        claude) echo "https://api.anthropic.com/v1/messages" ;;
        openai) echo "https://api.openai.com/v1/chat/completions" ;;
        groq) echo "https://api.groq.com/openai/v1/chat/completions" ;;
        xai) echo "https://api.x.ai/v1/chat/completions" ;;
        ollama) echo "http://localhost:11434/api/generate" ;;
        *) echo "Unknown" ;;
    esac
}

# ============================================================================
# API KEY MANAGEMENT
# ============================================================================

#############################
# Get API key for the specified provider
#
# Retrieves the API key from either the .aiwb.env file or environment variables.
# The .aiwb.env file takes precedence if it exists. Supports multiple AI providers.
#
# Arguments:
#   $1 - provider name (gemini|claude|openai|groq|xai)
# Returns:
#   API key string, or empty string if not set
# Environment:
#   GEMINI_API_KEY, ANTHROPIC_API_KEY, OPENAI_API_KEY, GROQ_API_KEY, XAI_API_KEY
# Example:
#   key=$(get_api_key "gemini")
#   if [[ -z "$key" ]]; then
#       echo "No API key found"
#   fi
#############################
get_api_key() {
    local provider="$1"
    local env_file key
    env_file="$(get_env_file)"

    # Source env file if exists (overrides environment)
    if [[ -f "$env_file" ]]; then
        source "$env_file"
    fi

    # Get key based on provider (checks both file-sourced and environment variables)
    case "$provider" in
        gemini)
            key="${GEMINI_API_KEY:-}"
            ;;
        claude)
            key="${ANTHROPIC_API_KEY:-}"
            ;;
        openai)
            key="${OPENAI_API_KEY:-}"
            ;;
        groq)
            key="${GROQ_API_KEY:-}"
            ;;
        xai)
            key="${XAI_API_KEY:-}"
            ;;
        *)
            key=""
            ;;
    esac

    echo "$key"
}

#############################
# Check if API key is configured for a provider
#
# Verifies whether an API key has been set for the specified provider.
# Returns success (0) if key exists and is non-empty.
#
# Arguments:
#   $1 - provider name (gemini|claude|openai|groq|xai)
# Returns:
#   0 if API key is set, 1 if not set or empty
# Example:
#   if has_api_key "claude"; then
#       echo "Claude API key is configured"
#   else
#       echo "Please set up Claude API key"
#   fi
#############################
has_api_key() {
    local provider="$1"
    local key
    key="$(get_api_key "$provider")"
    [[ -n "$key" ]]
}

# ============================================================================
# IMAGE HANDLING
# ============================================================================

#############################
# Check if a file is an image based on extension
#
# Determines whether the given file is an image by checking its extension
# against a list of supported image formats.
#
# Arguments:
#   $1 - file path or name
# Returns:
#   0 if file is an image (jpg, jpeg, png, gif, webp, bmp), 1 otherwise
# Example:
#   if is_image_file "photo.jpg"; then
#       echo "This is an image file"
#   fi
#############################
is_image_file() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"  # Convert to lowercase

    case "$ext" in
        jpg|jpeg|png|gif|webp|bmp)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

#############################
# Get MIME type for an image file
#
# Returns the appropriate MIME type based on the image file extension.
# Falls back to "image/jpeg" for unknown extensions.
#
# Arguments:
#   $1 - image file path or name
# Returns:
#   MIME type string (e.g., "image/png", "image/jpeg")
# Example:
#   mime=$(get_image_mime_type "photo.png")
#   # Returns: image/png
#############################
get_image_mime_type() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"

    case "$ext" in
        jpg|jpeg) echo "image/jpeg" ;;
        png) echo "image/png" ;;
        gif) echo "image/gif" ;;
        webp) echo "image/webp" ;;
        bmp) echo "image/bmp" ;;
        *) echo "image/jpeg" ;;  # default fallback
    esac
}

# Encode image to base64
encode_image_base64() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        err "Image file not found: $file"
        return 1
    fi
    base64 < "$file" | tr -d '\n'
}

# ============================================================================
# TOKEN ESTIMATION
# ============================================================================

# Estimate token count (rough approximation)
estimate_tokens() {
    local text="$1"
    # Improved estimate: 1 token ≈ 4 characters (more accurate for most modern tokenizers)
    # This gives a better approximation than chars/3 which tends to overestimate significantly
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
    local max_tokens="${3:-$AIWB_MAX_TOKENS_DEFAULT}"
    local temperature="${4:-$AIWB_TEMPERATURE_DEFAULT}"

    local api_key
    api_key="$(get_api_key gemini)"
    [[ -z "$api_key" ]] && { err "GEMINI_API_KEY not set"; return 1; }

    local url="https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${api_key}"

    # Handle large prompts by using a temp file instead of command-line args
    local request_body
    local prompt_file=$(mktemp)
    echo -n "$prompt" > "$prompt_file"

    request_body=$(jq -n \
        --rawfile text "$prompt_file" \
        --argjson max "$max_tokens" \
        --argjson temp "$temperature" \
        '{
            contents: [{role: "user", parts: [{text: $text}]}],
            generationConfig: {
                temperature: $temp,
                maxOutputTokens: $max
            }
        }')
    rm -f "$prompt_file"

    local response
    local curl_error curl_output request_file
    curl_error=$(mktemp -t aiwb_curl_err_XXXXXX)
    curl_output=$(mktemp -t aiwb_curl_out_XXXXXX)
    request_file=$(mktemp -t aiwb_curl_req_XXXXXX)

    # Write request body to file to avoid ARG_MAX limits
    echo "$request_body" > "$request_file"

    # Use curl with proper output/error separation and make it interruptible
    set +e  # Temporarily disable exit on error
    curl -fsS \
        --max-time $AIWB_API_TIMEOUT \
        --connect-timeout $AIWB_API_CONNECT_TIMEOUT \
        --no-buffer \
        -H "Content-Type: application/json" \
        -X POST "$url" \
        -d @"$request_file" \
        -o "$curl_output" \
        2>"$curl_error" &
    local curl_pid=$!

    # Wait for curl to complete and check for interrupts
    wait $curl_pid
    local exit_code=$?
    set -e  # Re-enable exit on error

    # Check if interrupted (exit code 130 is SIGINT)
    if [[ $exit_code -eq 130 ]]; then
        rm -f "$curl_error" "$curl_output" "$request_file"
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

        rm -f "$curl_error" "$curl_output" "$request_file"
        display_api_error "Gemini" "$error_msg" "$response_data" "$model" "$error_code"
        return 1
    fi

    response=$(cat "$curl_output" 2>/dev/null || echo "")
    rm -f "$curl_error" "$curl_output" "$request_file"

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
        # Check finish reason before treating as error
        local finish_reason
        finish_reason=$(echo "$response" | jq -r '.candidates[0].finishReason // ""' 2>/dev/null)

        # If finish reason is STOP but no text, try alternative extraction paths
        if [[ "$finish_reason" == "STOP" ]]; then
            # Try extracting all parts text (some responses might have multiple parts)
            text=$(echo "$response" | jq -r '[.candidates[0].content.parts[]? | select(.text != null) | .text] | join("\n")' 2>/dev/null)
        fi

        # If still empty, check for actual API error
        if [[ -z "$text" ]]; then
            local error_msg error_code
            error_msg=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
            error_code=$(echo "$response" | jq -r '.error.code // ""' 2>/dev/null)

            # Only display error if there's an actual error message, otherwise provide helpful context
            if [[ -n "$error_msg" ]]; then
                display_api_error "Gemini" "$error_msg" "$response" "$model" "$error_code"
                return 1
            else
                # No error but no text - check for content filtering or empty response
                case "$finish_reason" in
                    "SAFETY")
                        display_api_error "Gemini" "Response blocked by safety filters" "$response" "$model"
                        ;;
                    "RECITATION")
                        display_api_error "Gemini" "Response blocked due to recitation concerns" "$response" "$model"
                        ;;
                    "MAX_TOKENS")
                        display_api_error "Gemini" "Response truncated - maximum token limit reached" "$response" "$model"
                        ;;
                    *)
                        display_api_error "Gemini" "Empty response from API (finishReason: ${finish_reason:-UNKNOWN}). Response structure may have changed." "$response" "$model"
                        ;;
                esac
                return 1
            fi
        fi
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

# Call Gemini with vision support (images)
call_gemini_vision() {
    local prompt="$1"
    local model="${2:-gemini-2.0-flash-exp}"
    local max_tokens="${3:-$AIWB_MAX_TOKENS_DEFAULT}"
    local temperature="${4:-$AIWB_TEMPERATURE_DEFAULT}"
    shift 4
    local image_files=("$@")  # Remaining args are image file paths

    local api_key
    api_key="$(get_api_key gemini)"
    [[ -z "$api_key" ]] && { err "GEMINI_API_KEY not set"; return 1; }

    local url="https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${api_key}"

    # Build parts array with text and images
    local parts_json="["

    # Add text part first
    parts_json+="{\"text\": $(echo "$prompt" | jq -Rs .)}"

    # Add image parts
    for img_file in "${image_files[@]}"; do
        if [[ -f "$img_file" ]] && is_image_file "$img_file"; then
            local mime_type=$(get_image_mime_type "$img_file")
            local base64_data=$(encode_image_base64 "$img_file")
            parts_json+=",{\"inline_data\": {\"mime_type\": \"$mime_type\", \"data\": \"$base64_data\"}}"
        fi
    done

    parts_json+="]"

    local request_body
    request_body=$(jq -n \
        --argjson parts "$parts_json" \
        --argjson max "$max_tokens" \
        --argjson temp "$temperature" \
        '{
            contents: [{role: "user", parts: $parts}],
            generationConfig: {
                temperature: $temp,
                maxOutputTokens: $max
            }
        }')

    local response
    local curl_error curl_output request_file
    curl_error=$(mktemp -t aiwb_curl_err_XXXXXX)
    curl_output=$(mktemp -t aiwb_curl_out_XXXXXX)
    request_file=$(mktemp -t aiwb_curl_req_XXXXXX)

    # Write request body to file to avoid ARG_MAX limits
    echo "$request_body" > "$request_file"

    set +e
    curl -fsS \
        --max-time $AIWB_API_TIMEOUT \
        --connect-timeout $AIWB_API_CONNECT_TIMEOUT \
        --no-buffer \
        -H "Content-Type: application/json" \
        -X POST "$url" \
        -d @"$request_file" \
        -o "$curl_output" \
        2>"$curl_error" &
    local curl_pid=$!

    wait $curl_pid
    local exit_code=$?
    set -e

    if [[ $exit_code -eq 130 ]]; then
        rm -f "$curl_error" "$curl_output" "$request_file"
        echo "" >&2
        err "Request interrupted by user"
        return 130
    fi

    if [[ $exit_code -ne 0 ]]; then
        local error_msg error_code
        local response_data=$(cat "$curl_output" 2>/dev/null || echo "")
        local curl_error_msg=$(cat "$curl_error" 2>/dev/null || echo "Curl failed with exit code $exit_code")

        if [[ -n "$response_data" ]] && echo "$response_data" | jq -e '.error' >/dev/null 2>&1; then
            error_msg=$(echo "$response_data" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
            error_code=$(echo "$response_data" | jq -r '.error.code // ""' 2>/dev/null)
        else
            error_msg="$curl_error_msg"
            error_code="$exit_code"
        fi

        rm -f "$curl_error" "$curl_output" "$request_file"
        display_api_error "Gemini Vision" "$error_msg" "$response_data" "$model" "$error_code"
        return 1
    fi

    response=$(cat "$curl_output" 2>/dev/null || echo "")
    rm -f "$curl_error" "$curl_output" "$request_file"

    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        local api_error_msg api_error_code
        api_error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"')
        api_error_code=$(echo "$response" | jq -r '.error.code // ""' 2>/dev/null)
        display_api_error "Gemini Vision" "$api_error_msg" "$response" "$model" "$api_error_code"
        return 1
    fi

    local text
    text=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null)

    if [[ -z "$text" ]]; then
        # Check finish reason before treating as error
        local finish_reason
        finish_reason=$(echo "$response" | jq -r '.candidates[0].finishReason // ""' 2>/dev/null)

        # If finish reason is STOP but no text, try alternative extraction paths
        if [[ "$finish_reason" == "STOP" ]]; then
            # Try extracting all parts text (some responses might have multiple parts)
            text=$(echo "$response" | jq -r '[.candidates[0].content.parts[]? | select(.text != null) | .text] | join("\n")' 2>/dev/null)
        fi

        # If still empty, check for actual API error
        if [[ -z "$text" ]]; then
            local error_msg error_code
            error_msg=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
            error_code=$(echo "$response" | jq -r '.error.code // ""' 2>/dev/null)

            # Only display error if there's an actual error message, otherwise provide helpful context
            if [[ -n "$error_msg" ]]; then
                display_api_error "Gemini Vision" "$error_msg" "$response" "$model" "$error_code"
                return 1
            else
                # No error but no text - check for content filtering or empty response
                case "$finish_reason" in
                    "SAFETY")
                        display_api_error "Gemini Vision" "Response blocked by safety filters" "$response" "$model"
                        ;;
                    "RECITATION")
                        display_api_error "Gemini Vision" "Response blocked due to recitation concerns" "$response" "$model"
                        ;;
                    "MAX_TOKENS")
                        display_api_error "Gemini Vision" "Response truncated - maximum token limit reached" "$response" "$model"
                        ;;
                    *)
                        display_api_error "Gemini Vision" "Empty response from API (finishReason: ${finish_reason:-UNKNOWN}). Response structure may have changed." "$response" "$model"
                        ;;
                esac
                return 1
            fi
        fi
    fi

    echo "$text"
}

# ============================================================================
# API CALLS - CLAUDE
# ============================================================================

call_claude() {
    local prompt="$1"
    local model="${2:-claude-3-haiku-20240307}"
    local max_tokens="${3:-4096}"  # Claude 3 Haiku max is 4096
    local temperature="${4:-$AIWB_TEMPERATURE_DEFAULT}"

    local api_key
    api_key="$(get_api_key claude)"
    [[ -z "$api_key" ]] && { err "ANTHROPIC_API_KEY not set"; return 1; }

    local url="https://api.anthropic.com/v1/messages"

    # Handle large prompts by using a temp file
    local prompt_file=$(mktemp -t aiwb_prompt_XXXXXX)
    echo -n "$prompt" > "$prompt_file"

    local request_body
    request_body=$(jq -n \
        --arg model "$model" \
        --rawfile content "$prompt_file" \
        --argjson max "$max_tokens" \
        --argjson temp "$temperature" \
        '{
            model: $model,
            max_tokens: $max,
            temperature: $temp,
            messages: [{role: "user", content: $content}]
        }')
    rm -f "$prompt_file"

    local response
    local curl_error curl_output request_file
    curl_error=$(mktemp -t aiwb_curl_err_XXXXXX)
    curl_output=$(mktemp -t aiwb_curl_out_XXXXXX)
    request_file=$(mktemp -t aiwb_curl_req_XXXXXX)

    # Write request body to file to avoid ARG_MAX limits
    echo "$request_body" > "$request_file"

    # Use curl with proper output/error separation and make it interruptible
    set +e  # Temporarily disable exit on error
    curl -sS "$url" \
        --max-time $AIWB_API_TIMEOUT \
        --connect-timeout $AIWB_API_CONNECT_TIMEOUT \
        --no-buffer \
        -H "x-api-key: $api_key" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d @"$request_file" \
        -o "$curl_output" \
        2>"$curl_error" &
    local curl_pid=$!

    # Wait for curl to complete and check for interrupts
    wait $curl_pid
    local exit_code=$?
    set -e  # Re-enable exit on error

    # Check if interrupted (exit code 130 is SIGINT)
    if [[ $exit_code -eq 130 ]]; then
        rm -f "$curl_error" "$curl_output" "$request_file"
        echo "" >&2
        err "Request interrupted by user"
        return 130
    fi

    # Check for curl errors
    if [[ $exit_code -ne 0 ]]; then
        local error_msg
        error_msg=$(cat "$curl_error" 2>/dev/null || echo "Curl failed with exit code $exit_code")
        local response_data=$(cat "$curl_output" 2>/dev/null || echo "")
        rm -f "$curl_error" "$curl_output" "$request_file"
        display_api_error "Claude" "$error_msg" "$response_data" "$model" "$exit_code"
        return 1
    fi

    response=$(cat "$curl_output" 2>/dev/null || echo "")
    rm -f "$curl_error" "$curl_output" "$request_file"

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
        # Try extracting from all content blocks
        text=$(echo "$response" | jq -r '[.content[]? | select(.text != null) | .text] | join("\n")' 2>/dev/null)

        # If still empty, check for actual API error
        if [[ -z "$text" ]]; then
            local error_msg stop_reason
            error_msg=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
            stop_reason=$(echo "$response" | jq -r '.stop_reason // ""' 2>/dev/null)

            # Only display error if there's an actual error message
            if [[ -n "$error_msg" ]]; then
                display_api_error "Claude" "$error_msg" "$response" "$model"
                return 1
            else
                # No error but no text - provide context
                display_api_error "Claude" "Empty response from API (stop_reason: ${stop_reason:-UNKNOWN}). Response structure may have changed." "$response" "$model"
                return 1
            fi
        fi
    fi

    echo "$text"
}

# Call Claude with vision support (images)
call_claude_vision() {
    local prompt="$1"
    local model="${2:-claude-3-5-sonnet-20240620}"
    local max_tokens="${3:-4096}"
    local temperature="${4:-$AIWB_TEMPERATURE_DEFAULT}"
    shift 4
    local image_files=("$@")  # Remaining args are image file paths

    local api_key
    api_key="$(get_api_key claude)"
    [[ -z "$api_key" ]] && { err "ANTHROPIC_API_KEY not set"; return 1; }

    local url="https://api.anthropic.com/v1/messages"

    # Build content array with text and images
    local content_json="["

    # Add image parts first (Claude prefers images before text)
    local first=true
    for img_file in "${image_files[@]}"; do
        if [[ -f "$img_file" ]] && is_image_file "$img_file"; then
            [[ "$first" = false ]] && content_json+=","
            first=false

            local mime_type=$(get_image_mime_type "$img_file")
            local base64_data=$(encode_image_base64 "$img_file")
            content_json+="{\"type\": \"image\", \"source\": {\"type\": \"base64\", \"media_type\": \"$mime_type\", \"data\": \"$base64_data\"}}"
        fi
    done

    # Add text part last
    [[ "$first" = false ]] && content_json+=","
    content_json+="{\"type\": \"text\", \"text\": $(echo "$prompt" | jq -Rs .)}"
    content_json+="]"

    local request_body
    request_body=$(jq -n \
        --arg model "$model" \
        --argjson content "$content_json" \
        --argjson max "$max_tokens" \
        --argjson temp "$temperature" \
        '{
            model: $model,
            max_tokens: $max,
            temperature: $temp,
            messages: [{role: "user", content: $content}]
        }')

    local response
    local curl_error curl_output request_file
    curl_error=$(mktemp -t aiwb_curl_err_XXXXXX)
    curl_output=$(mktemp -t aiwb_curl_out_XXXXXX)
    request_file=$(mktemp -t aiwb_curl_req_XXXXXX)

    # Write request body to file to avoid ARG_MAX limits
    echo "$request_body" > "$request_file"

    set +e
    curl -sS "$url" \
        --max-time $AIWB_API_TIMEOUT \
        --connect-timeout $AIWB_API_CONNECT_TIMEOUT \
        --no-buffer \
        -H "x-api-key: $api_key" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d @"$request_file" \
        -o "$curl_output" \
        2>"$curl_error" &
    local curl_pid=$!

    wait $curl_pid
    local exit_code=$?
    set -e

    if [[ $exit_code -eq 130 ]]; then
        rm -f "$curl_error" "$curl_output" "$request_file"
        echo "" >&2
        err "Request interrupted by user"
        return 130
    fi

    if [[ $exit_code -ne 0 ]]; then
        local error_msg
        error_msg=$(cat "$curl_error" 2>/dev/null || echo "Curl failed with exit code $exit_code")
        local response_data=$(cat "$curl_output" 2>/dev/null || echo "")
        rm -f "$curl_error" "$curl_output" "$request_file"
        display_api_error "Claude Vision" "$error_msg" "$response_data" "$model" "$exit_code"
        return 1
    fi

    response=$(cat "$curl_output" 2>/dev/null || echo "")
    rm -f "$curl_error" "$curl_output" "$request_file"

    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        local api_error_type api_error_msg api_error_code
        api_error_type=$(echo "$response" | jq -r '.error.type // ""')
        api_error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"')
        api_error_code=$(echo "$response" | jq -r '.error.status_code // ""' 2>/dev/null)
        local full_error="$api_error_type: $api_error_msg"
        display_api_error "Claude Vision" "$full_error" "$response" "$model" "$api_error_code"
        return 1
    fi

    local text
    text=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null)

    if [[ -z "$text" ]]; then
        # Try extracting from all content blocks
        text=$(echo "$response" | jq -r '[.content[]? | select(.text != null) | .text] | join("\n")' 2>/dev/null)

        # If still empty, check for actual API error
        if [[ -z "$text" ]]; then
            local error_msg stop_reason
            error_msg=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
            stop_reason=$(echo "$response" | jq -r '.stop_reason // ""' 2>/dev/null)

            # Only display error if there's an actual error message
            if [[ -n "$error_msg" ]]; then
                display_api_error "Claude Vision" "$error_msg" "$response" "$model"
                return 1
            else
                # No error but no text - provide context
                display_api_error "Claude Vision" "Empty response from API (stop_reason: ${stop_reason:-UNKNOWN}). Response structure may have changed." "$response" "$model"
                return 1
            fi
        fi
    fi

    echo "$text"
}

# ============================================================================
# API CALLS - OPENAI
# ============================================================================

call_openai() {
    local prompt="$1"
    local model="${2:-gpt-4o-mini}"
    local max_tokens="${3:-$AIWB_MAX_TOKENS_DEFAULT}"
    local temperature="${4:-$AIWB_TEMPERATURE_DEFAULT}"

    local api_key
    api_key="$(get_api_key openai)"
    [[ -z "$api_key" ]] && { err "OPENAI_API_KEY not set"; return 1; }

    local url="https://api.openai.com/v1/chat/completions"

    # Handle large prompts by using a temp file
    local prompt_file=$(mktemp -t aiwb_prompt_XXXXXX)
    echo -n "$prompt" > "$prompt_file"

    local request_body
    request_body=$(jq -n \
        --arg model "$model" \
        --rawfile content "$prompt_file" \
        --argjson max "$max_tokens" \
        --argjson temp "$temperature" \
        '{
            model: $model,
            max_tokens: $max,
            temperature: $temp,
            messages: [{role: "user", content: $content}]
        }')
    rm -f "$prompt_file"

    local response
    local curl_error curl_output request_file
    curl_error=$(mktemp -t aiwb_curl_err_XXXXXX)
    curl_output=$(mktemp -t aiwb_curl_out_XXXXXX)
    request_file=$(mktemp -t aiwb_curl_req_XXXXXX)

    # Write request body to file to avoid ARG_MAX limits
    echo "$request_body" > "$request_file"

    # Use curl with proper output/error separation and make it interruptible
    set +e  # Temporarily disable exit on error
    curl -fsS "$url" \
        --max-time $AIWB_API_TIMEOUT \
        --connect-timeout $AIWB_API_CONNECT_TIMEOUT \
        --no-buffer \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d @"$request_file" \
        -o "$curl_output" \
        2>"$curl_error" &
    local curl_pid=$!

    # Wait for curl to complete and check for interrupts
    wait $curl_pid
    local exit_code=$?
    set -e  # Re-enable exit on error

    # Check if interrupted (exit code 130 is SIGINT)
    if [[ $exit_code -eq 130 ]]; then
        rm -f "$curl_error" "$curl_output" "$request_file"
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
  - The model hasn't been released yet
  - You don't have access to this model with your API key

Available OpenAI models: gpt-4o, gpt-4o-mini, gpt-4-turbo, o1, o1-mini, o1-preview, o3, o3-mini, o3-pro"
            fi
        else
            # Fallback to curl error if no JSON error
            error_msg="$curl_error_msg"
            error_code="$exit_code"
        fi

        rm -f "$curl_error" "$curl_output" "$request_file"
        display_api_error "OpenAI" "$error_msg" "$response_data" "$model" "$error_code"
        return 1
    fi

    response=$(cat "$curl_output" 2>/dev/null || echo "")
    rm -f "$curl_error" "$curl_output" "$request_file"

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
        # Try extracting from all choices
        text=$(echo "$response" | jq -r '[.choices[]? | select(.message.content != null) | .message.content] | join("\n")' 2>/dev/null)

        # If still empty, check for actual API error
        if [[ -z "$text" ]]; then
            local error_msg error_code finish_reason
            error_msg=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
            error_code=$(echo "$response" | jq -r '.error.code // ""' 2>/dev/null)
            finish_reason=$(echo "$response" | jq -r '.choices[0].finish_reason // ""' 2>/dev/null)

            # Only display error if there's an actual error message
            if [[ -n "$error_msg" ]]; then
                display_api_error "OpenAI" "$error_msg" "$response" "$model" "$error_code"
                return 1
            else
                # No error but no text - provide context
                display_api_error "OpenAI" "Empty response from API (finish_reason: ${finish_reason:-UNKNOWN}). Response structure may have changed." "$response" "$model"
                return 1
            fi
        fi
    fi

    echo "$text"
}

# ============================================================================
# API CALLS - GROQ
# ============================================================================

call_groq() {
    local prompt="$1"
    local model="${2:-llama-3.3-70b-versatile}"
    local max_tokens="${3:-$AIWB_MAX_TOKENS_DEFAULT}"
    local temperature="${4:-$AIWB_TEMPERATURE_DEFAULT}"

    local api_key
    api_key="$(get_api_key groq)"
    [[ -z "$api_key" ]] && { err "GROQ_API_KEY not set"; return 1; }

    local url="https://api.groq.com/openai/v1/chat/completions"

    # Handle large prompts by using a temp file
    local prompt_file=$(mktemp -t aiwb_prompt_XXXXXX)
    echo -n "$prompt" > "$prompt_file"

    local request_body
    request_body=$(jq -n \
        --arg model "$model" \
        --rawfile content "$prompt_file" \
        --argjson max "$max_tokens" \
        --argjson temp "$temperature" \
        '{
            model: $model,
            max_tokens: $max,
            temperature: $temp,
            messages: [{role: "user", content: $content}]
        }')
    rm -f "$prompt_file"

    local response
    local curl_error curl_output request_file
    curl_error=$(mktemp -t aiwb_curl_err_XXXXXX)
    curl_output=$(mktemp -t aiwb_curl_out_XXXXXX)
    request_file=$(mktemp -t aiwb_curl_req_XXXXXX)

    # Write request body to file to avoid ARG_MAX limits
    echo "$request_body" > "$request_file"

    # Use curl with proper output/error separation and make it interruptible
    set +e  # Temporarily disable exit on error
    curl -fsS "$url" \
        --max-time $AIWB_API_TIMEOUT \
        --connect-timeout $AIWB_API_CONNECT_TIMEOUT \
        --no-buffer \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d @"$request_file" \
        -o "$curl_output" \
        2>"$curl_error" &
    local curl_pid=$!

    # Wait for curl to complete and check for interrupts
    wait $curl_pid
    local exit_code=$?
    set -e  # Re-enable exit on error

    # Check if interrupted (exit code 130 is SIGINT)
    if [[ $exit_code -eq 130 ]]; then
        rm -f "$curl_error" "$curl_output" "$request_file"
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

        rm -f "$curl_error" "$curl_output" "$request_file"
        display_api_error "Groq" "$error_msg" "$response_data" "$model" "$error_code"
        return 1
    fi

    response=$(cat "$curl_output" 2>/dev/null || echo "")
    rm -f "$curl_error" "$curl_output" "$request_file"

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
        # Try extracting from all choices
        text=$(echo "$response" | jq -r '[.choices[]? | select(.message.content != null) | .message.content] | join("\n")' 2>/dev/null)

        # If still empty, check for actual API error
        if [[ -z "$text" ]]; then
            local error_msg finish_reason
            error_msg=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
            finish_reason=$(echo "$response" | jq -r '.choices[0].finish_reason // ""' 2>/dev/null)

            # Only display error if there's an actual error message
            if [[ -n "$error_msg" ]]; then
                display_api_error "Groq" "$error_msg" "$response" "$model"
                return 1
            else
                # No error but no text - provide context
                display_api_error "Groq" "Empty response from API (finish_reason: ${finish_reason:-UNKNOWN}). Response structure may have changed." "$response" "$model"
                return 1
            fi
        fi
    fi

    echo "$text"
}

# ============================================================================
# API CALLS - XAI (Grok)
# ============================================================================

call_xai() {
    local prompt="$1"
    local model="${2:-grok-beta}"
    local max_tokens="${3:-$AIWB_MAX_TOKENS_DEFAULT}"
    local temperature="${4:-$AIWB_TEMPERATURE_DEFAULT}"

    local api_key
    api_key="$(get_api_key xai)"
    [[ -z "$api_key" ]] && { err "XAI_API_KEY not set"; return 1; }

    local url="https://api.x.ai/v1/chat/completions"

    # Handle large prompts by using a temp file
    local prompt_file=$(mktemp -t aiwb_prompt_XXXXXX)
    echo -n "$prompt" > "$prompt_file"

    local request_body
    request_body=$(jq -n \
        --arg model "$model" \
        --rawfile content "$prompt_file" \
        --argjson max "$max_tokens" \
        --argjson temp "$temperature" \
        '{
            model: $model,
            max_tokens: $max,
            temperature: $temp,
            messages: [{role: "user", content: $content}]
        }')
    rm -f "$prompt_file"

    local response
    local curl_error curl_output request_file
    curl_error=$(mktemp -t aiwb_curl_err_XXXXXX)
    curl_output=$(mktemp -t aiwb_curl_out_XXXXXX)
    request_file=$(mktemp -t aiwb_curl_req_XXXXXX)

    # Write request body to file to avoid ARG_MAX limits
    echo "$request_body" > "$request_file"

    # Use curl with proper output/error separation and make it interruptible
    set +e  # Temporarily disable exit on error
    curl -fsS "$url" \
        --max-time $AIWB_API_TIMEOUT \
        --connect-timeout $AIWB_API_CONNECT_TIMEOUT \
        --no-buffer \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d @"$request_file" \
        -o "$curl_output" \
        2>"$curl_error" &
    local curl_pid=$!

    # Wait for curl to complete and check for interrupts
    wait $curl_pid
    local exit_code=$?
    set -e  # Re-enable exit on error

    # Check if interrupted (exit code 130 is SIGINT)
    if [[ $exit_code -eq 130 ]]; then
        rm -f "$curl_error" "$curl_output" "$request_file"
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

        rm -f "$curl_error" "$curl_output" "$request_file"
        display_api_error "xAI (Grok)" "$error_msg" "$response_data" "$model" "$error_code"
        return 1
    fi

    response=$(cat "$curl_output" 2>/dev/null || echo "")
    rm -f "$curl_error" "$curl_output" "$request_file"

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
        # Try extracting from all choices
        text=$(echo "$response" | jq -r '[.choices[]? | select(.message.content != null) | .message.content] | join("\n")' 2>/dev/null)

        # If still empty, check for actual API error
        if [[ -z "$text" ]]; then
            local error_msg finish_reason
            error_msg=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
            finish_reason=$(echo "$response" | jq -r '.choices[0].finish_reason // ""' 2>/dev/null)

            # Only display error if there's an actual error message
            if [[ -n "$error_msg" ]]; then
                display_api_error "xAI (Grok)" "$error_msg" "$response" "$model"
                return 1
            else
                # No error but no text - provide context
                display_api_error "xAI (Grok)" "Empty response from API (finish_reason: ${finish_reason:-UNKNOWN}). Response structure may have changed." "$response" "$model"
                return 1
            fi
        fi
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

    # Handle large prompts by using a temp file
    local prompt_file=$(mktemp -t aiwb_prompt_XXXXXX)
    echo -n "$prompt" > "$prompt_file"

    local request_body
    request_body=$(jq -n \
        --arg model "$model" \
        --rawfile prompt "$prompt_file" \
        '{
            model: $model,
            prompt: $prompt,
            stream: false
        }')
    rm -f "$prompt_file"

    local response
    local curl_error curl_output request_file
    curl_error=$(mktemp -t aiwb_curl_err_XXXXXX)
    curl_output=$(mktemp -t aiwb_curl_out_XXXXXX)
    request_file=$(mktemp -t aiwb_curl_req_XXXXXX)

    # Write request body to file to avoid ARG_MAX limits
    echo "$request_body" > "$request_file"

    # Use curl with proper output/error separation and make it interruptible
    set +e  # Temporarily disable exit on error
    curl -fsS "$url" \
        --max-time $AIWB_API_TIMEOUT \
        --connect-timeout $AIWB_API_CONNECT_TIMEOUT \
        --no-buffer \
        -H "Content-Type: application/json" \
        -d @"$request_file" \
        -o "$curl_output" \
        2>"$curl_error" &
    local curl_pid=$!

    # Wait for curl to complete and check for interrupts
    wait $curl_pid
    local exit_code=$?
    set -e  # Re-enable exit on error

    # Check if interrupted (exit code 130 is SIGINT)
    if [[ $exit_code -eq 130 ]]; then
        rm -f "$curl_error" "$curl_output" "$request_file"
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

        rm -f "$curl_error" "$curl_output" "$request_file"
        display_api_error "Ollama" "$error_msg" "$response_data" "$model" "$error_code"
        return 1
    fi

    response=$(cat "$curl_output" 2>/dev/null || echo "")
    rm -f "$curl_error" "$curl_output" "$request_file"

    # Extract response
    local text
    text=$(echo "$response" | jq -r '.response // empty' 2>/dev/null)

    if [[ -z "$text" ]]; then
        # Check for actual API error
        local error_msg done_status
        error_msg=$(echo "$response" | jq -r '.error // empty' 2>/dev/null)
        done_status=$(echo "$response" | jq -r '.done // ""' 2>/dev/null)

        # Only display error if there's an actual error message
        if [[ -n "$error_msg" ]]; then
            display_api_error "Ollama" "$error_msg" "$response" "$model"
            return 1
        else
            # No error but no text - provide context
            display_api_error "Ollama" "Empty response from API (done: ${done_status:-UNKNOWN}). Response structure may have changed." "$response" "$model"
            return 1
        fi
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
                max_tokens=$AIWB_MAX_TOKENS_DEFAULT
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

# Call API with image support
# Usage: call_api_with_images "prompt" "provider" "model" "max_tokens" image_file1 image_file2 ...
call_api_with_images() {
    local prompt="$1"
    local provider="${2:-$(config_get model_provider)}"
    local model="${3:-$(config_get model_name)}"
    local max_tokens="${4:-}"
    shift 4
    local image_files=("$@")

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
                max_tokens=$AIWB_MAX_TOKENS_DEFAULT
                ;;
        esac
    fi

    debug "Calling $provider API with vision support, model $model (max_tokens: $max_tokens, images: ${#image_files[@]})"

    case "$provider" in
        gemini)
            call_gemini_vision "$prompt" "gemini-${model}" "$max_tokens" 0.2 "${image_files[@]}"
            ;;
        claude)
            call_claude_vision "$prompt" "claude-${model}" "$max_tokens" 0.2 "${image_files[@]}"
            ;;
        openai)
            # TODO: Add OpenAI vision support
            warn "Vision not yet implemented for OpenAI, falling back to text-only"
            call_openai "$prompt" "$model" "$max_tokens"
            ;;
        groq)
            # TODO: Add Groq vision support if available
            warn "Vision not supported for Groq, falling back to text-only"
            call_groq "$prompt" "$model" "$max_tokens"
            ;;
        xai)
            # TODO: Add xAI vision support if available
            warn "Vision not supported for xAI, falling back to text-only"
            call_xai "$prompt" "$model" "$max_tokens"
            ;;
        ollama)
            # TODO: Add Ollama vision support if available
            warn "Vision not supported for Ollama, falling back to text-only"
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

    # Pricing as of 2025 (updated with latest models from working_code_models_14.11.txt)
    case "$provider" in
        gemini)
            case "$model" in
                *2.5-flash-lite*|*flash-2.5-lite*) [[ "$token_type" == "input" ]] && echo "0.10" || echo "0.40" ;;
                *2.5-flash*|*flash-2.5*)           [[ "$token_type" == "input" ]] && echo "0.30" || echo "2.50" ;;
                *2.5-pro*|*pro-2.5*)               [[ "$token_type" == "input" ]] && echo "1.25" || echo "10.00" ;;
                *2.0-flash-lite*|*flash-2.0-lite*) [[ "$token_type" == "input" ]] && echo "0.075" || echo "0.30" ;;
                *2.0-flash-001*|*flash-2.0-001*)   [[ "$token_type" == "input" ]] && echo "0.075" || echo "0.30" ;;
                *flash*)                           [[ "$token_type" == "input" ]] && echo "0.075" || echo "0.30" ;;
                *pro*)                             [[ "$token_type" == "input" ]] && echo "1.25" || echo "5.00" ;;
                *) echo "0.30" ;;
            esac
            ;;
        claude)
            case "$model" in
                *haiku-4-5*|*4-5-haiku*)             [[ "$token_type" == "input" ]] && echo "1.00" || echo "5.00" ;;
                *haiku*)                             [[ "$token_type" == "input" ]] && echo "0.25" || echo "1.25" ;;
                *sonnet-4-5*|*4-5-sonnet*)           [[ "$token_type" == "input" ]] && echo "3.00" || echo "15.00" ;;
                *sonnet-4*|*4-sonnet*)               [[ "$token_type" == "input" ]] && echo "3.00" || echo "15.00" ;;
                *3-7-sonnet*)                        [[ "$token_type" == "input" ]] && echo "3.00" || echo "15.00" ;;
                *sonnet*)                            [[ "$token_type" == "input" ]] && echo "3.00" || echo "15.00" ;;
                *opus-4-1*|*4-1-opus*)               [[ "$token_type" == "input" ]] && echo "15.00" || echo "75.00" ;;
                *opus-4*|*4-opus*)                   [[ "$token_type" == "input" ]] && echo "15.00" || echo "75.00" ;;
                *opus*)                              [[ "$token_type" == "input" ]] && echo "15.00" || echo "75.00" ;;
                *) echo "3.00" ;;
            esac
            ;;
        openai)
            case "$model" in
                *gpt-5.1*)     [[ "$token_type" == "input" ]] && echo "3.00" || echo "12.00" ;;
                *gpt-5-pro*)   [[ "$token_type" == "input" ]] && echo "2.50" || echo "10.00" ;;
                *gpt-5-mini*)  [[ "$token_type" == "input" ]] && echo "0.20" || echo "0.80" ;;
                *gpt-5-nano*)  [[ "$token_type" == "input" ]] && echo "0.10" || echo "0.40" ;;
                *gpt-5*)       [[ "$token_type" == "input" ]] && echo "2.50" || echo "10.00" ;;
                *gpt-4.1*)     [[ "$token_type" == "input" ]] && echo "2.50" || echo "10.00" ;;
                *gpt-4o-mini*) [[ "$token_type" == "input" ]] && echo "0.15" || echo "0.60" ;;
                *gpt-4o*)      [[ "$token_type" == "input" ]] && echo "2.50" || echo "10.00" ;;
                *gpt-4*)       [[ "$token_type" == "input" ]] && echo "2.50" || echo "10.00" ;;
                *gpt-3.5*)     [[ "$token_type" == "input" ]] && echo "0.50" || echo "1.50" ;;
                *codex*)       [[ "$token_type" == "input" ]] && echo "0.30" || echo "1.20" ;;
                *o3*)          [[ "$token_type" == "input" ]] && echo "2.50" || echo "10.00" ;;
                *o1*)          [[ "$token_type" == "input" ]] && echo "2.50" || echo "10.00" ;;
                *) echo "0.15" ;;
            esac
            ;;
        groq)
            # Groq pricing for available models (updated with new models)
            case "$model" in
                *gpt-oss-120b*)     [[ "$token_type" == "input" ]] && echo "0.10" || echo "0.15" ;;
                *gpt-oss-20b*)      [[ "$token_type" == "input" ]] && echo "0.05" || echo "0.08" ;;
                *compound-min*)     [[ "$token_type" == "input" ]] && echo "0.05" || echo "0.08" ;;
                *llama-4-maverick*) [[ "$token_type" == "input" ]] && echo "0.50" || echo "0.77" ;;
                *llama-4-scout*)    [[ "$token_type" == "input" ]] && echo "0.11" || echo "0.34" ;;
                *llama-3.3-70b*)    [[ "$token_type" == "input" ]] && echo "0.059" || echo "0.079" ;;
                *llama-3.2*)        [[ "$token_type" == "input" ]] && echo "0.005" || echo "0.008" ;;
                *llama-3.1-70b*)    [[ "$token_type" == "input" ]] && echo "0.059" || echo "0.079" ;;
                *llama-3.1-8b*)     [[ "$token_type" == "input" ]] && echo "0.005" || echo "0.008" ;;
                *mixtral*)          [[ "$token_type" == "input" ]] && echo "0.024" || echo "0.024" ;;
                *gemma*)            [[ "$token_type" == "input" ]] && echo "0.005" || echo "0.008" ;;
                *) echo "0.05" ;;
            esac
            ;;
        xai)
            # xAI Grok pricing (as of January 2025 - updated with official models)
            case "$model" in
                *grok-4-0709*)              [[ "$token_type" == "input" ]] && echo "5.00" || echo "15.00" ;;
                *grok-4-fast-reasoning*)    [[ "$token_type" == "input" ]] && echo "5.00" || echo "15.00" ;;
                *grok-4-fast-non-reasoning*)[[ "$token_type" == "input" ]] && echo "3.00" || echo "10.00" ;;
                *grok-4*)                   [[ "$token_type" == "input" ]] && echo "5.00" || echo "15.00" ;;
                *grok-3-mini*)              [[ "$token_type" == "input" ]] && echo "0.30" || echo "0.50" ;;
                *grok-3*)                   [[ "$token_type" == "input" ]] && echo "3.00" || echo "15.00" ;;
                *grok-code-fast*)           [[ "$token_type" == "input" ]] && echo "3.00" || echo "15.00" ;;
                *grok-2-vision*)            [[ "$token_type" == "input" ]] && echo "2.00" || echo "10.00" ;;
                *grok-2*)                   [[ "$token_type" == "input" ]] && echo "2.00" || echo "10.00" ;;
                *grok-beta*)                [[ "$token_type" == "input" ]] && echo "5.00" || echo "15.00" ;;
                *) echo "5.00" ;;
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
