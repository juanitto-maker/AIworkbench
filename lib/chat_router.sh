#!/usr/bin/env bash
# chat_router.sh - Smart intent detection and routing for chat messages
# Enables chat-first workflow by detecting keywords and routing to appropriate actions

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[[ -z "${AIWB_LIB_UI_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"

# ============================================================================
# INTENT DETECTION
# ============================================================================

# Detect the intent of a chat message based on keywords
# Returns: "edit", "generate", "chat"
detect_message_intent() {
    local message="$1"
    local lowercase=$(echo "$message" | tr '[:upper:]' '[:lower:]')

    # Keywords for different intents
    local edit_keywords="implement|add|create|update|modify|change|edit|fix|debug|resolve|patch|remove|delete|refactor|tweak|improve"
    local generate_keywords="generate|scaffold|boilerplate|build from scratch"
    local explain_keywords="how |what |why |explain|show me|tell me|help me understand|documentation|guide|describe"

    # Check for edit/implement intent (high priority - most common)
    if echo "$lowercase" | grep -Eq "\b($edit_keywords)\b"; then
        echo "edit"
        return 0
    fi

    # Check for generate intent
    if echo "$lowercase" | grep -Eq "\b($generate_keywords)\b"; then
        echo "generate"
        return 0
    fi

    # Check for explanation intent (questions)
    if echo "$lowercase" | grep -Eq "($explain_keywords)"; then
        echo "chat"
        return 0
    fi

    # Default to chat for ambiguous cases
    echo "chat"
}

# Check if a message is asking a question (should stay in chat mode)
is_question() {
    local message="$1"
    local lowercase=$(echo "$message" | tr '[:upper:]' '[:lower:]')

    # Question indicators
    if echo "$lowercase" | grep -Eq "^(how|what|why|when|where|who|which|can|could|would|should|is|are|does|do)"; then
        return 0  # true
    fi

    if echo "$lowercase" | grep -Eq "\?"; then
        return 0  # true
    fi

    return 1  # false
}

# ============================================================================
# AUTO-ROUTING FUNCTIONS
# ============================================================================

# Auto-route to /make mode with repo integration
auto_make_with_integration() {
    local description="$1"

    # Set up mode state
    MODE_CURRENT="make"
    MODE_PROMPT="$description"
    MODE_MODEL_PROVIDER="${MODE_MODEL_PROVIDER:-$(config_get model_provider)}"
    MODE_MODEL_NAME="${MODE_MODEL_NAME:-$(config_get model_name)}"
    MODE_CHECK_PROVIDER="auto"  # Enable auto-verification

    # Show what we're doing
    msg "🤖 Starting code generation workflow..."
    echo ""

    # Run the mode
    mode_run

    # Clean up
    reset_mode
}

# ============================================================================
# SMART CHAT MESSAGE HANDLER
# ============================================================================

# Enhanced chat message handler with smart routing
# This replaces the basic handle_chat_message for chat-first workflow
handle_chat_message_routed() {
    local message="$1"
    local provider model
    provider="$(config_get model_provider)"
    model="$(config_get model_name)"

    # Debug mode (set AIWB_DEBUG_ROUTER=1 to enable)
    if [[ "${AIWB_DEBUG_ROUTER:-0}" == "1" ]]; then
        echo "[DEBUG] handle_chat_message_routed called with: $message" >&2
    fi

    # Detect intent
    local intent=$(detect_message_intent "$message")

    if [[ "${AIWB_DEBUG_ROUTER:-0}" == "1" ]]; then
        echo "[DEBUG] Detected intent: $intent" >&2
    fi

    # Special case: questions should always use chat mode
    if is_question "$message"; then
        intent="chat"
        if [[ "${AIWB_DEBUG_ROUTER:-0}" == "1" ]]; then
            echo "[DEBUG] Overriding to chat (question detected)" >&2
        fi
    fi

    case "$intent" in
        "edit")
            # Check if required functions exist
            if ! type smart_edit &>/dev/null; then
                if [[ "${AIWB_DEBUG_ROUTER:-0}" == "1" ]]; then
                    echo "[DEBUG] smart_edit not found, falling back to chat" >&2
                fi
                warn "Edit functionality not available (smart_edit function missing)"
                # Don't return, fall through to chat handler below
            # Check if we're in a git repository
            elif ! type is_repo_mode &>/dev/null || ! is_repo_mode; then
                if [[ "${AIWB_DEBUG_ROUTER:-0}" == "1" ]]; then
                    echo "[DEBUG] Not in repo mode, falling back to chat" >&2
                fi
                warn "Code editing requires a git repository context"
                echo ""
                echo "To enable repository editing:"
                echo "  1. cd into your git repository"
                echo "  2. Run: aiwb"
                echo "  3. Or use: /repo to set repository path"
                echo ""
                echo "Falling back to chat mode for now..."
                echo ""
                # Don't return, fall through to chat handler below
            else
                # Auto-route to edit workflow
                msg "🤖 Detected code change request. Analyzing repository..."
                echo ""

                # Call smart_edit directly
                smart_edit "$message"
                local edit_exit=$?

                # Return the same exit code (only return if edit was successful)
                return $edit_exit
            fi
            # Fall through to chat handler if conditions failed
            ;;

        "generate")
            # Route to /make mode with repo integration
            auto_make_with_integration "$message"
            return $?
            ;;
    esac

    # If we get here, use regular chat (intent="chat" or fallback)
    if [[ "${AIWB_DEBUG_ROUTER:-0}" == "1" ]]; then
        echo "[DEBUG] Executing chat handler for message: $message" >&2
    fi

    # Build message with context using centralized function
    local enhanced_message
    if type build_prompt_with_context &>/dev/null; then
        enhanced_message=$(build_prompt_with_context "$message" "false")
    else
        # Fallback if function doesn't exist
        enhanced_message="$message"
    fi

    # Show blinking cursor while API call runs
    if type ui_blink &>/dev/null; then
        ui_blink "Thinking..."
    fi

    # Call API
    local response
    if type call_api &>/dev/null; then
        response=$(call_api "$enhanced_message" "$provider" "$model" 2>&1)
        local exit_code=$?
    else
        err "call_api function not available"
        return 1
    fi

    # Clear the blinking cursor line
    if type ui_clear_line &>/dev/null; then
        ui_clear_line
    fi

    # Check if interrupted (exit code 130)
    if [[ $exit_code -eq 130 ]]; then
        echo ""
        return 130
    fi

    if [[ $exit_code -ne 0 ]]; then
        err "Failed to get response from API (exit code: $exit_code)"
        if [[ "${AIWB_DEBUG_ROUTER:-0}" == "1" ]]; then
            echo "[DEBUG] API response: $response" >&2
        fi
        return 1
    fi

    if [[ -z "$response" ]]; then
        err "Received empty response from API"
        return 1
    fi

    # Display response (redirect to stderr to avoid duplicate output)
    printf "\n" >&2
    printf "%b\n" "${BOLD}AI:${RESET}" >&2
    printf "%b\n" "\033[0;33m${response}${RESET}" >&2
    printf "\n" >&2

    # Track cost first (use enhanced_message to reflect actual tokens sent)
    if type track_usage &>/dev/null; then
        track_usage "$provider" "$model" "$enhanced_message" "$response"
    fi

    # Show status footer (will include the cost just tracked)
    if type show_status_footer &>/dev/null; then
        show_status_footer >&2
        echo "" >&2
    fi

    # Return only the response text for logging
    echo "$response"
}

# ============================================================================
# EXPORTS
# ============================================================================

export -f detect_message_intent is_question
export -f auto_make_with_integration
export -f handle_chat_message_routed

export AIWB_LIB_CHAT_ROUTER_LOADED=1
