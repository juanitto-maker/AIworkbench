#!/usr/bin/env bash
# CONTEXT_COMMANDS_IMPLEMENTATION.sh
# Sample command implementations for context persistence
# These functions should be added to the main 'aiwb' script

# Source the context state library
# Add this near the top of aiwb script with other library sources:
# source "${AIWB_LIB_DIR}/context_state.sh"

# ============================================================================
# COMMAND: /contextload
# Load saved context into current session
# ============================================================================
cmd_contextload() {
    local workspace
    workspace=$(get_workspace)

    if ! context_state_exists; then
        echo "❌ No saved context found"
        echo ""
        echo "Tip: Run /scanrepo or /smartscan to build context first"
        return 1
    fi

    # Check age and warn if stale
    context_state_check_age

    # Show what will be loaded
    echo ""
    context_state_show
    echo ""

    # Prompt to confirm
    if command -v gum &>/dev/null; then
        if ! gum confirm "Load this context into current session?"; then
            echo "Cancelled"
            return 0
        fi
    else
        read -p "Load this context into current session? [Y/n] " -r
        if [[ $REPLY =~ ^[Nn] ]]; then
            echo "Cancelled"
            return 0
        fi
    fi

    # Load context files into MODE_UPLOADS
    context_state_load_into_mode

    echo ""
    echo "✅ Context loaded. Use /make, /debug, or /tweak to use it."
}

# ============================================================================
# COMMAND: /contextsave
# Save current context (MODE_UPLOADS) to state file
# ============================================================================
cmd_contextsave() {
    if [[ ${#MODE_UPLOADS[@]} -eq 0 ]]; then
        echo "❌ No files in context to save"
        echo ""
        echo "Tip: Use /context to add files, or run /scanrepo first"
        return 1
    fi

    # Save MODE_UPLOADS to context state
    context_state_save_from_mode

    # Show summary
    echo ""
    context_state_show
}

# ============================================================================
# COMMAND: /contextshow
# Display current context state
# ============================================================================
cmd_contextshow() {
    if ! context_state_exists; then
        echo "❌ No active context state"
        echo ""
        echo "Tip: Run /scanrepo or add files with /context to create context"
        return 1
    fi

    context_state_show

    # Also check size
    echo ""
    context_state_check_size
}

# ============================================================================
# COMMAND: /contextclear
# Clear all context and start fresh
# ============================================================================
cmd_contextclear() {
    if ! context_state_exists && [[ ${#MODE_UPLOADS[@]} -eq 0 ]]; then
        echo "❌ No context to clear"
        return 0
    fi

    # Confirm before clearing
    echo "⚠️  This will clear:"
    echo "   • All context files"
    echo "   • Conversation history"
    echo "   • Scan results"
    echo ""

    if command -v gum &>/dev/null; then
        if ! gum confirm "Clear all context?"; then
            echo "Cancelled"
            return 0
        fi
    else
        read -p "Clear all context? [y/N] " -r
        if [[ ! $REPLY =~ ^[Yy] ]]; then
            echo "Cancelled"
            return 0
        fi
    fi

    # Clear context state
    context_state_clear

    # Clear MODE_UPLOADS
    MODE_UPLOADS=()

    # Clear mode settings
    MODE_PROMPT=""
    MODE_INSTRUCT_FILE=""

    echo "✅ All context cleared"
}

# ============================================================================
# COMMAND: /contextrefresh
# Re-scan repository and update context
# ============================================================================
cmd_contextrefresh() {
    echo "🔄 Refreshing context..."
    echo ""

    # Detect current scan type from context state
    local scan_type="full"

    if context_state_exists; then
        scan_type=$(context_state_get "last_scan.type")
        if [[ -z "$scan_type" || "$scan_type" == "null" ]]; then
            scan_type="full"
        fi
    fi

    echo "Previous scan type: $scan_type"
    echo ""

    # Prompt for scan type
    if command -v gum &>/dev/null; then
        scan_type=$(gum choose "full" "selective" --header "Choose scan type:")
    else
        echo "Choose scan type:"
        echo "  1) full     - Scan entire repository"
        echo "  2) selective - Scan key files only"
        read -p "Enter choice [1-2]: " -r choice
        case "$choice" in
            1) scan_type="full" ;;
            2) scan_type="selective" ;;
            *) scan_type="full" ;;
        esac
    fi

    # Clear old context first
    context_state_clear
    MODE_UPLOADS=()

    # Run appropriate scan
    if [[ "$scan_type" == "selective" ]]; then
        cmd_smartscan
    else
        cmd_scanrepo
    fi

    echo ""
    echo "✅ Context refreshed"
    context_state_show
}

# ============================================================================
# COMMAND: /contextremove
# Remove specific file from context
# ============================================================================
cmd_contextremove() {
    if ! context_state_exists; then
        echo "❌ No context to remove from"
        return 1
    fi

    # Get list of context files
    local files
    mapfile -t files < <(context_state_list_files)

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "❌ No files in context"
        return 1
    fi

    # Interactive selection
    local file_to_remove

    if command -v gum &>/dev/null; then
        file_to_remove=$(printf '%s\n' "${files[@]}" | gum filter --placeholder "Select file to remove")
    else
        echo "Files in context:"
        local i=1
        for file in "${files[@]}"; do
            echo "  $i) $file"
            ((i++))
        done
        echo ""
        read -p "Enter number to remove: " -r choice
        file_to_remove="${files[$((choice-1))]}"
    fi

    if [[ -z "$file_to_remove" ]]; then
        echo "Cancelled"
        return 0
    fi

    # Remove from context state
    context_state_remove_file "$file_to_remove"

    # Also remove from MODE_UPLOADS if present
    local new_uploads=()
    for file in "${MODE_UPLOADS[@]}"; do
        if [[ "$file" != "$file_to_remove" ]]; then
            new_uploads+=("$file")
        fi
    done
    MODE_UPLOADS=("${new_uploads[@]}")

    echo "✅ Removed: $file_to_remove"
}

# ============================================================================
# MODIFIED: cmd_scanrepo
# Add context persistence after scan
# ============================================================================
cmd_scanrepo_with_persistence() {
    # ... existing scanrepo code ...
    # After the scan completes and output file is created:

    local output_file="$WORKSPACE/outputs/repo_analysis_$(date +%Y%m%d_%H%M%S).md"
    local file_count=127  # This would be the actual count from build_repo_context

    # Save scan result to context state
    context_state_save_scan "full" "$output_file" "$file_count"

    echo ""
    echo "✅ Scan saved to context state"
    echo "   Run /contextshow to view details"
}

# ============================================================================
# MODIFIED: cmd_smartscan
# Add context persistence after scan
# ============================================================================
cmd_smartscan_with_persistence() {
    # ... existing smartscan code ...
    # After the scan completes and output file is created:

    local output_file="$WORKSPACE/outputs/repo_analysis_$(date +%Y%m%d_%H%M%S).md"
    local file_count=42  # This would be the actual count from build_repo_context

    # Save scan result to context state
    context_state_save_scan "selective" "$output_file" "$file_count"

    echo ""
    echo "✅ Scan saved to context state"
    echo "   Run /contextshow to view details"
}

# ============================================================================
# MODIFIED: handle_chat_message
# Add conversation history to context
# ============================================================================
handle_chat_message_with_history() {
    local message="$1"

    local provider model
    provider=$(config_get model_provider)
    model=$(config_get model_name)

    # Add user message to context history
    context_state_add_message "user" "$message"

    # Call API (original behavior)
    local response
    response=$(call_api "$message" "$provider" "$model")

    # Add assistant response to context history
    context_state_add_message "assistant" "$response"

    # Track usage
    track_usage "$provider" "$model" "$message" "$response"

    echo "$response"
}

# ============================================================================
# NEW: handle_chat_message_with_threading
# Enhanced version with conversation threading (Phase 2)
# ============================================================================
handle_chat_message_with_threading() {
    local message="$1"

    local provider model
    provider=$(config_get model_provider)
    model=$(config_get model_name)

    # Check if threading is enabled
    local threading_enabled
    threading_enabled=$(config_get conversation.threading_enabled)

    if [[ "$threading_enabled" == "true" ]]; then
        # Build conversation payload with history
        local conversation_payload
        conversation_payload=$(build_conversation_payload "$message")

        # Call API with history
        local response
        response=$(call_api_with_history "$conversation_payload" "$provider" "$model")

        # Add to history
        context_state_add_message "user" "$message"
        context_state_add_message "assistant" "$response"

        echo "$response"
    else
        # Fallback to simple message (backward compatible)
        handle_chat_message_with_history "$message"
    fi
}

# ============================================================================
# NEW: build_conversation_payload
# Build multi-turn conversation payload for API
# ============================================================================
build_conversation_payload() {
    local current_message="$1"

    local max_turns
    max_turns=$(config_get conversation.max_turns)
    max_turns=${max_turns:-10}

    # Get conversation history
    local history
    mapfile -t history < <(context_state_get_history "$max_turns")

    # Build payload based on provider
    local provider
    provider=$(config_get model_provider)

    case "$provider" in
        gemini)
            build_gemini_conversation_payload "$current_message" "${history[@]}"
            ;;
        anthropic|claude)
            build_claude_conversation_payload "$current_message" "${history[@]}"
            ;;
        openai|deepseek|groq|openrouter)
            build_openai_conversation_payload "$current_message" "${history[@]}"
            ;;
        *)
            # Fallback: just return current message
            echo "$current_message"
            ;;
    esac
}

# ============================================================================
# NEW: build_gemini_conversation_payload
# Build Gemini-style conversation payload
# ============================================================================
build_gemini_conversation_payload() {
    local current_message="$1"
    shift
    local history=("$@")

    # Start building JSON payload
    local payload='{"contents":['

    # Add history messages
    for msg in "${history[@]}"; do
        local role content
        role=$(echo "$msg" | cut -d':' -f1)
        content=$(echo "$msg" | cut -d':' -f2-)

        # Map role names (user/assistant -> user/model for Gemini)
        if [[ "$role" == "assistant" ]]; then
            role="model"
        fi

        # Escape content for JSON
        content=$(echo "$content" | jq -Rs .)

        payload+="{\"role\":\"$role\",\"parts\":[{\"text\":$content}]},"
    done

    # Add current message
    local escaped_message
    escaped_message=$(echo "$current_message" | jq -Rs .)
    payload+="{\"role\":\"user\",\"parts\":[{\"text\":$escaped_message}]}"

    payload+=']}'

    echo "$payload"
}

# ============================================================================
# NEW: build_claude_conversation_payload
# Build Claude-style conversation payload
# ============================================================================
build_claude_conversation_payload() {
    local current_message="$1"
    shift
    local history=("$@")

    local payload='{"messages":['

    # Add history messages
    for msg in "${history[@]}"; do
        local role content
        role=$(echo "$msg" | cut -d':' -f1)
        content=$(echo "$msg" | cut -d':' -f2-)

        content=$(echo "$content" | jq -Rs .)
        payload+="{\"role\":\"$role\",\"content\":$content},"
    done

    # Add current message
    local escaped_message
    escaped_message=$(echo "$current_message" | jq -Rs .)
    payload+="{\"role\":\"user\",\"content\":$escaped_message}"

    payload+=']}'

    echo "$payload"
}

# ============================================================================
# NEW: build_openai_conversation_payload
# Build OpenAI-style conversation payload
# ============================================================================
build_openai_conversation_payload() {
    local current_message="$1"
    shift
    local history=("$@")

    local payload='{"messages":['

    # Add history messages
    for msg in "${history[@]}"; do
        local role content
        role=$(echo "$msg" | cut -d':' -f1)
        content=$(echo "$msg" | cut -d':' -f2-)

        content=$(echo "$content" | jq -Rs .)
        payload+="{\"role\":\"$role\",\"content\":$content},"
    done

    # Add current message
    local escaped_message
    escaped_message=$(echo "$current_message" | jq -Rs .)
    payload+="{\"role\":\"user\",\"content\":$escaped_message}"

    payload+=']}'

    echo "$payload"
}

# ============================================================================
# MODIFIED: Main script initialization
# Check for existing context on startup
# ============================================================================
main_with_context_check() {
    # ... existing initialization code ...

    # Check if context state exists from previous session
    if context_state_exists; then
        local resume_enabled
        resume_enabled=$(config_get context_management.resume_on_start)
        resume_enabled=${resume_enabled:-prompt}

        if [[ "$resume_enabled" == "prompt" ]]; then
            # Calculate age
            local created_at age_msg
            created_at=$(context_state_get "created_at")

            if [[ -n "$created_at" ]]; then
                local created_epoch now_epoch age_days
                created_epoch=$(date -d "$created_at" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${created_at:0:19}" +%s 2>/dev/null || echo "0")
                now_epoch=$(date +%s)
                age_days=$(( (now_epoch - created_epoch) / 86400 ))

                if [[ $age_days -eq 0 ]]; then
                    age_msg="today"
                elif [[ $age_days -eq 1 ]]; then
                    age_msg="yesterday"
                else
                    age_msg="$age_days days ago"
                fi

                echo ""
                echo "⚠️  Found context from previous session ($age_msg)"

                if command -v gum &>/dev/null; then
                    if gum confirm "Resume with previous context?"; then
                        context_state_load_into_mode
                        echo ""
                        context_state_show
                    fi
                else
                    read -p "   Resume with previous context? [Y/n] " -r
                    if [[ ! $REPLY =~ ^[Nn] ]]; then
                        context_state_load_into_mode
                        echo ""
                        context_state_show
                    fi
                fi
                echo ""
            fi
        elif [[ "$resume_enabled" == "true" ]]; then
            # Auto-resume
            context_state_load_into_mode
            context_state_show
            echo ""
        fi
    fi

    # ... continue with existing main menu ...
}

# ============================================================================
# COMMAND MAP ADDITIONS
# Add these to the command handling switch statement
# ============================================================================
handle_slash_command_additions() {
    local cmd="$1"

    case "$cmd" in
        /contextload)
            cmd_contextload
            ;;
        /contextsave)
            cmd_contextsave
            ;;
        /contextshow)
            cmd_contextshow
            ;;
        /contextclear)
            cmd_contextclear
            ;;
        /contextrefresh)
            cmd_contextrefresh
            ;;
        /contextremove)
            cmd_contextremove
            ;;
        *)
            # ... existing command handling ...
            ;;
    esac
}

# ============================================================================
# HELP TEXT ADDITIONS
# Add to the help command output
# ============================================================================
help_text_context_commands() {
    cat <<'HELP'

Context Management:
  /contextload      Load saved context into current session
  /contextsave      Save current context to state file
  /contextshow      Display current context state
  /contextclear     Clear all context and start fresh
  /contextrefresh   Re-scan repository and update context
  /contextremove    Remove specific file from context

HELP
}
