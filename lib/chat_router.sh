#!/usr/bin/env bash
# chat_router.sh - Smart intent detection and routing for chat messages
# Enables chat-first workflow by detecting keywords and routing to appropriate actions

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[[ -z "${AIWB_LIB_UI_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"

# ============================================================================
# INTENT DETECTION
# ============================================================================

# Detect the intent of a chat message based on keywords
# Returns: "edit", "generate", "scan", "analyze", "context", "swarm", "status", "chat"
detect_message_intent() {
    local message="$1"
    local lowercase=$(echo "$message" | tr '[:upper:]' '[:lower:]')

    # Keywords for different intents (ordered by priority)

    # Scan/analyze repository intent
    local scan_keywords="scan repo|scan repository|scan codebase|analyze repo|analyze repository|analyze codebase|scan this|scan project|scan folder"
    if echo "$lowercase" | grep -Eq "($scan_keywords)"; then
        echo "scan"
        return 0
    fi

    # Context management intent
    local context_keywords="load context|save context|show context|clear context|list context|context files|what.*context|view context"
    if echo "$lowercase" | grep -Eq "($context_keywords)"; then
        echo "context"
        return 0
    fi

    # Swarm mode intent
    local swarm_keywords="use swarm|enable swarm|swarm mode|activate swarm|turn on swarm|swarm config"
    if echo "$lowercase" | grep -Eq "($swarm_keywords)"; then
        echo "swarm"
        return 0
    fi

    # Status/info intent
    local status_keywords="show status|check status|current status|what.*status|project status|system status"
    if echo "$lowercase" | grep -Eq "($status_keywords)"; then
        echo "status"
        return 0
    fi

    # Edit/implement intent (high priority - most common)
    local edit_keywords="implement|add|create|update|modify|change|edit|fix|debug|resolve|patch|remove|delete|refactor|tweak|improve"
    if echo "$lowercase" | grep -Eq "\b($edit_keywords)\b"; then
        echo "edit"
        return 0
    fi

    # Generate intent
    local generate_keywords="generate|scaffold|boilerplate|build from scratch"
    if echo "$lowercase" | grep -Eq "\b($generate_keywords)\b"; then
        echo "generate"
        return 0
    fi

    # Analyze intent (AI analysis of codebase)
    local analyze_keywords="analyze.*app|analyze.*application|analyze.*code|code analysis|review code|examine code"
    if echo "$lowercase" | grep -Eq "($analyze_keywords)"; then
        echo "analyze"
        return 0
    fi

    # Explanation intent (questions)
    local explain_keywords="how |what |why |explain|show me|tell me|help me understand|documentation|guide|describe"
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

# Auto-route to repository scan
auto_scan_repo() {
    msg "🔍 Scanning repository..."
    echo ""

    # Call cmd_scanrepo if available
    if type cmd_scanrepo &>/dev/null; then
        cmd_scanrepo
    elif type cmd_smartscan &>/dev/null; then
        cmd_smartscan
    else
        err "Scan functionality not available"
        return 1
    fi
}

# Auto-route to code analysis with AI
auto_analyze_code() {
    local description="$1"

    msg "🔍 Analyzing codebase with AI..."
    echo ""

    # First scan if not already scanned
    if type context_state_exists &>/dev/null && ! context_state_exists; then
        msg "No context found, scanning repository first..."
        if type cmd_smartscan &>/dev/null; then
            cmd_smartscan
        fi
    fi

    # Then use /make mode to analyze
    MODE_CURRENT="make"
    MODE_PROMPT="$description"
    MODE_MODEL_PROVIDER="${MODE_MODEL_PROVIDER:-$(config_get model_provider)}"
    MODE_MODEL_NAME="${MODE_MODEL_NAME:-$(config_get model_name)}"
    MODE_CHECK_PROVIDER="auto"

    msg "🤖 Analyzing with AI..."
    mode_run
    reset_mode
}

# Auto-route to context operations
auto_handle_context() {
    local message="$1"
    local lowercase=$(echo "$message" | tr '[:upper:]' '[:lower:]')

    # Detect specific context operation
    if echo "$lowercase" | grep -Eq "load.*context"; then
        msg "📂 Loading saved context..."
        if type cmd_contextload &>/dev/null; then
            cmd_contextload
        else
            err "Context load functionality not available"
        fi
    elif echo "$lowercase" | grep -Eq "save.*context"; then
        msg "💾 Saving context..."
        if type cmd_contextsave &>/dev/null; then
            cmd_contextsave
        else
            err "Context save functionality not available"
        fi
    elif echo "$lowercase" | grep -Eq "show.*context|list.*context|view.*context"; then
        msg "📋 Showing context..."
        if type cmd_contextshow &>/dev/null; then
            cmd_contextshow
        else
            err "Context show functionality not available"
        fi
    elif echo "$lowercase" | grep -Eq "clear.*context"; then
        msg "🗑️ Clearing context..."
        if type cmd_contextclear &>/dev/null; then
            cmd_contextclear
        else
            err "Context clear functionality not available"
        fi
    else
        # Default: show context menu
        if type cmd_context &>/dev/null; then
            cmd_context
        else
            err "Context functionality not available"
        fi
    fi
}

# Auto-route to swarm operations
auto_handle_swarm() {
    local message="$1"
    local lowercase=$(echo "$message" | tr '[:upper:]' '[:lower:]')

    msg "🐝 Swarm Mode Configuration"
    echo ""

    # Show current status
    if type get_swarm_display &>/dev/null; then
        local swarm_status
        swarm_status=$(get_swarm_display)
        echo "Current Status: $swarm_status"
        echo ""
    fi

    # Check if they want to enable/use swarm
    if echo "$lowercase" | grep -Eq "enable|activate|turn on|use"; then
        msg "To use swarm mode for analysis:"
        echo "  1. Swarm is now enabled"
        echo "  2. Add context: run scan or add files"
        echo "  3. Use /make with your prompt"
        echo "  4. Swarm will activate for large contexts"
        echo ""

        # Enable swarm
        if type swarm_toggle &>/dev/null; then
            SWARM_ENABLED=true
            if type config_set &>/dev/null; then
                config_set "swarm.enabled" "true"
            fi
            success "Swarm mode enabled!"
        fi
    else
        # Show swarm menu
        if type cmd_swarm &>/dev/null; then
            cmd_swarm
        elif type menu_swarm &>/dev/null; then
            menu_swarm
        else
            err "Swarm configuration not available"
        fi
    fi
}

# Auto-route to status display
auto_show_status() {
    msg "📊 Current Status"
    echo ""

    if type cmd_status_overview &>/dev/null; then
        cmd_status_overview
    else
        err "Status functionality not available"
    fi
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
        "scan")
            # Route to repository scan
            auto_scan_repo
            return $?
            ;;

        "analyze")
            # Route to AI-powered code analysis
            auto_analyze_code "$message"
            return $?
            ;;

        "context")
            # Route to context operations
            auto_handle_context "$message"
            return $?
            ;;

        "swarm")
            # Route to swarm configuration
            auto_handle_swarm "$message"
            return $?
            ;;

        "status")
            # Route to status display
            auto_show_status
            return $?
            ;;

        "edit")
            # Check if required functions exist
            if ! type smart_edit &>/dev/null; then
                if [[ "${AIWB_DEBUG_ROUTER:-0}" == "1" ]]; then
                    echo "[DEBUG] smart_edit not found, falling back to chat" >&2
                fi
                warn "Edit functionality not available (smart_edit function missing)"
                # Explicitly fall back to chat mode
                intent="chat"
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
                # Explicitly fall back to chat mode
                intent="chat"
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
            # If intent was changed to chat, fall through to chat handler
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
        response=$(call_api "$enhanced_message" "$provider" "$model")
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
    if [[ $exit_code -eq $AIWB_EXIT_SIGINT ]]; then
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
export -f auto_scan_repo auto_analyze_code
export -f auto_handle_context auto_handle_swarm auto_show_status
export -f handle_chat_message_routed

export AIWB_LIB_CHAT_ROUTER_LOADED=1
