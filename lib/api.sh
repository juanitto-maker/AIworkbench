#!/usr/bin/env bash
# api.sh - API interaction helpers for AIWB

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[[ -z "${AIWB_LIB_CONFIG_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

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
    local model="${2:-gemini-1.5-flash}"
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
    local curl_error
    curl_error=$(mktemp)
    response=$(curl -fsS \
        --max-time 300 \
        --connect-timeout 10 \
        --no-buffer \
        -H "Content-Type: application/json" \
        -X POST "$url" \
        -d "$request_body" 2>"$curl_error")

    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        local error_msg
        error_msg=$(cat "$curl_error" 2>/dev/null || echo "$response")
        rm -f "$curl_error"
        err "API request failed: $error_msg"
        return 1
    fi
    rm -f "$curl_error"

    # Extract text from response
    local text
    text=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null)

    if [[ -z "$text" ]]; then
        # Check for error in response
        local error_msg
        error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
        err "API error: $error_msg"
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
    local model="${2:-claude-3-5-sonnet-latest}"
    local max_tokens="${3:-16000}"
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
    local curl_error
    curl_error=$(mktemp)
    response=$(curl -fsS "$url" \
        --max-time 300 \
        --connect-timeout 10 \
        --no-buffer \
        -H "x-api-key: $api_key" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "$request_body" 2>"$curl_error")

    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        local error_msg
        error_msg=$(cat "$curl_error" 2>/dev/null || echo "$response")
        rm -f "$curl_error"
        err "API request failed: $error_msg"
        return 1
    fi
    rm -f "$curl_error"

    # Extract text from response
    local text
    text=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null)

    if [[ -z "$text" ]]; then
        # Check for error in response
        local error_msg
        error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
        err "API error: $error_msg"
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
    local curl_error
    curl_error=$(mktemp)
    response=$(curl -fsS "$url" \
        --max-time 300 \
        --connect-timeout 10 \
        --no-buffer \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d "$request_body" 2>"$curl_error")

    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        local error_msg
        error_msg=$(cat "$curl_error" 2>/dev/null || echo "$response")
        rm -f "$curl_error"
        err "API request failed: $error_msg"
        return 1
    fi
    rm -f "$curl_error"

    # Extract text from response
    local text
    text=$(echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null)

    if [[ -z "$text" ]]; then
        # Check for error in response
        local error_msg
        error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
        err "API error: $error_msg"
        return 1
    fi

    echo "$text"
}

# ============================================================================
# API CALLS - GROQ
# ============================================================================

call_groq() {
    local prompt="$1"
    local model="${2:-llama-3.1-70b-versatile}"
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
    local curl_error
    curl_error=$(mktemp)
    response=$(curl -fsS "$url" \
        --max-time 300 \
        --connect-timeout 10 \
        --no-buffer \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d "$request_body" 2>"$curl_error")

    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        local error_msg
        error_msg=$(cat "$curl_error" 2>/dev/null || echo "$response")
        rm -f "$curl_error"
        err "API request failed: $error_msg"
        return 1
    fi
    rm -f "$curl_error"

    # Extract text from response (OpenAI-compatible format)
    local text
    text=$(echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null)

    if [[ -z "$text" ]]; then
        # Check for error in response
        local error_msg
        error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
        err "API error: $error_msg"
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
    local curl_error
    curl_error=$(mktemp)
    response=$(curl -fsS "$url" \
        --max-time 300 \
        --connect-timeout 10 \
        --no-buffer \
        -H "Content-Type: application/json" \
        -d "$request_body" 2>"$curl_error")

    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        local error_msg
        error_msg=$(cat "$curl_error" 2>/dev/null || echo "$response")
        rm -f "$curl_error"
        err "Ollama request failed: $error_msg"
        return 1
    fi
    rm -f "$curl_error"

    # Extract response
    local text
    text=$(echo "$response" | jq -r '.response // empty' 2>/dev/null)

    if [[ -z "$text" ]]; then
        err "No response from Ollama"
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
    local max_tokens="${4:-16000}"

    debug "Calling $provider API with model $model"

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

    # Pricing as of 2025 (approximate, user should update)
    case "$provider" in
        gemini)
            case "$model" in
                *flash*) [[ "$token_type" == "input" ]] && echo "0.075" || echo "0.30" ;;
                *pro*)   [[ "$token_type" == "input" ]] && echo "1.25" || echo "5.00" ;;
                *) echo "0.075" ;;
            esac
            ;;
        claude)
            case "$model" in
                *haiku*)  [[ "$token_type" == "input" ]] && echo "0.25" || echo "1.25" ;;
                *sonnet*) [[ "$token_type" == "input" ]] && echo "3.00" || echo "15.00" ;;
                *opus*)   [[ "$token_type" == "input" ]] && echo "15.00" || echo "75.00" ;;
                *) echo "3.00" ;;
            esac
            ;;
        openai)
            case "$model" in
                *gpt-4o-mini*) [[ "$token_type" == "input" ]] && echo "0.15" || echo "0.60" ;;
                *gpt-4o*)      [[ "$token_type" == "input" ]] && echo "2.50" || echo "10.00" ;;
                *) echo "0.15" ;;
            esac
            ;;
        groq)
            # Groq is extremely cheap/free for most models
            case "$model" in
                *llama-3.1-70b*) [[ "$token_type" == "input" ]] && echo "0.059" || echo "0.079" ;;
                *llama-3.1-8b*)  [[ "$token_type" == "input" ]] && echo "0.005" || echo "0.008" ;;
                *mixtral*)       [[ "$token_type" == "input" ]] && echo "0.024" || echo "0.024" ;;
                *) echo "0.01" ;;
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
