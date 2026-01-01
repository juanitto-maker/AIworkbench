#!/usr/bin/env bash
# context_state.sh - Session context persistence for AIWB
# Part of AIWB v3.1.0 - Context Persistence Feature

# Get context state file location (dynamically based on workspace)
get_context_state_file() {
    local workspace
    workspace=$(get_workspace 2>/dev/null) || workspace="${WORKSPACE:-$HOME/.aiwb/workspace}"
    echo "$workspace/.context_state"
}

# Initialize context state structure
init_context_state() {
    local context_state_file
    context_state_file=$(get_context_state_file)

    local workspace
    workspace=$(get_workspace 2>/dev/null) || workspace="${WORKSPACE:-$HOME/.aiwb/workspace}"

    local session_id
    session_id=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "session_$(date +%s)")

    cat > "$context_state_file" <<EOF
{
  "session_id": "$session_id",
  "created_at": "$(date -Iseconds)",
  "updated_at": "$(date -Iseconds)",
  "context_files": [],
  "conversation_history": [],
  "last_scan": null,
  "active": true,
  "metadata": {
    "version": "3.1.0",
    "workspace": "$workspace"
  }
}
EOF
    chmod 600 "$context_state_file"
}

# Check if context state exists
context_state_exists() {
    local context_state_file
    context_state_file=$(get_context_state_file)
    [[ -f "$context_state_file" ]]
}

# Get context state value using jq (fallback to grep if jq not available)
context_state_get() {
    local key="$1"
    local context_state_file
    context_state_file=$(get_context_state_file)

    if ! context_state_exists; then
        return 1
    fi

    if command -v jq &>/dev/null; then
        jq -r ".$key // empty" "$context_state_file" 2>/dev/null
    else
        # Fallback: simple grep-based extraction (limited functionality)
        grep "\"$key\"" "$context_state_file" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/'
    fi
}

# Update context state timestamp
context_state_touch() {
    local context_state_file
    context_state_file=$(get_context_state_file)

    if ! context_state_exists; then
        return 1
    fi

    if command -v jq &>/dev/null; then
        local tmp_file
        tmp_file=$(mktemp)
        jq --arg ts "$(date -Iseconds)" '.updated_at = $ts' "$context_state_file" > "$tmp_file"
        mv "$tmp_file" "$context_state_file"
        chmod 600 "$context_state_file"
    fi
}

# Add file to context state
context_state_add_file() {
    local file_path="$1"
    local context_type="${2:-manual}"  # manual, scan, auto
    local context_state_file
    context_state_file=$(get_context_state_file)

    if ! context_state_exists; then
        init_context_state
    fi

    # Check if file exists
    if [[ ! -e "$file_path" ]]; then
        echo "Error: File not found: $file_path" >&2
        return 1
    fi

    # Get absolute path
    file_path=$(realpath "$file_path" 2>/dev/null || readlink -f "$file_path" 2>/dev/null || echo "$file_path")

    if command -v jq &>/dev/null; then
        local tmp_file
        tmp_file=$(mktemp)
        jq --arg path "$file_path" \
           --arg type "$context_type" \
           --arg ts "$(date -Iseconds)" \
           '.context_files += [{"path": $path, "added_at": $ts, "type": $type}] | .updated_at = $ts' \
           "$context_state_file" > "$tmp_file"
        mv "$tmp_file" "$context_state_file"
        chmod 600 "$context_state_file"
        return 0
    else
        echo "Warning: jq not available, context state not updated" >&2
        return 1
    fi
}

# Remove file from context state
context_state_remove_file() {
    local file_path="$1"
    local context_state_file
    context_state_file=$(get_context_state_file)

    if ! context_state_exists; then
        echo "Error: No context state found" >&2
        return 1
    fi

    # Get absolute path
    file_path=$(realpath "$file_path" 2>/dev/null || readlink -f "$file_path" 2>/dev/null || echo "$file_path")

    if command -v jq &>/dev/null; then
        local tmp_file
        tmp_file=$(mktemp)
        jq --arg path "$file_path" \
           --arg ts "$(date -Iseconds)" \
           '.context_files = [.context_files[] | select(.path != $path)] | .updated_at = $ts' \
           "$context_state_file" > "$tmp_file"
        mv "$tmp_file" "$context_state_file"
        chmod 600 "$context_state_file"
        return 0
    else
        echo "Warning: jq not available, context state not updated" >&2
        return 1
    fi
}

# Get list of context files
context_state_list_files() {
    local context_state_file
    context_state_file=$(get_context_state_file)

    if ! context_state_exists; then
        return 1
    fi

    if command -v jq &>/dev/null; then
        jq -r '.context_files[]? | .path' "$context_state_file" 2>/dev/null
    else
        # Fallback: extract paths with grep
        grep '"path":' "$context_state_file" | sed 's/.*"path": *"\([^"]*\)".*/\1/'
    fi
}

# Save scan result to context state
context_state_save_scan() {
    local scan_type="$1"        # full or selective
    local output_file="$2"       # path to analysis file
    local file_count="$3"        # number of files scanned
    local context_state_file
    context_state_file=$(get_context_state_file)

    if ! context_state_exists; then
        init_context_state
        context_state_file=$(get_context_state_file)  # Re-get after init
    fi

    if command -v jq &>/dev/null; then
        local tmp_file
        tmp_file=$(mktemp)
        jq --arg type "$scan_type" \
           --arg file "$output_file" \
           --arg count "$file_count" \
           --arg ts "$(date -Iseconds)" \
           '.last_scan = {"type": $type, "output_file": $file, "timestamp": $ts, "file_count": ($count | tonumber)} | .updated_at = $ts' \
           "$context_state_file" > "$tmp_file"
        mv "$tmp_file" "$context_state_file"
        chmod 600 "$context_state_file"

        # Also add the output file to context_files
        context_state_add_file "$output_file" "scan"

        return 0
    else
        echo "Warning: jq not available, scan result not saved to context state" >&2
        return 1
    fi
}

# Add message to conversation history
context_state_add_message() {
    local role="$1"      # user or assistant
    local content="$2"   # message content
    local context_state_file
    context_state_file=$(get_context_state_file)

    if ! context_state_exists; then
        init_context_state
    fi

    if command -v jq &>/dev/null; then
        local tmp_file
        tmp_file=$(mktemp)

        # Escape content for JSON
        local escaped_content
        escaped_content=$(echo "$content" | jq -Rs .)

        jq --arg role "$role" \
           --argjson content "$escaped_content" \
           --arg ts "$(date -Iseconds)" \
           '.conversation_history += [{"role": $role, "content": $content, "timestamp": $ts}] | .updated_at = $ts' \
           "$context_state_file" > "$tmp_file"
        mv "$tmp_file" "$context_state_file"
        chmod 600 "$context_state_file"
        return 0
    else
        # Fallback: append to a separate history file if jq not available
        local workspace
        workspace=$(get_workspace 2>/dev/null) || workspace="${WORKSPACE:-$HOME/.aiwb/workspace}"
        local history_file="$workspace/.conversation_history.log"
        echo "[$(date -Iseconds)] $role: $content" >> "$history_file"
        return 0
    fi
}

# Get conversation history (last N messages)
context_state_get_history() {
    local limit="${1:-10}"  # Default to last 10 messages
    local context_state_file
    context_state_file=$(get_context_state_file)

    if ! context_state_exists; then
        return 1
    fi

    if command -v jq &>/dev/null; then
        jq -r --arg limit "$limit" \
           '.conversation_history[-($limit | tonumber):] | .[]? | "\(.role): \(.content)"' \
           "$context_state_file" 2>/dev/null
    else
        # Fallback: read from history log file
        local workspace
        workspace=$(get_workspace 2>/dev/null) || workspace="${WORKSPACE:-$HOME/.aiwb/workspace}"
        local history_file="$workspace/.conversation_history.log"
        if [[ -f "$history_file" ]]; then
            tail -n "$((limit * 2))" "$history_file"
        fi
    fi
}

# Clear context state
context_state_clear() {
    local context_state_file
    context_state_file=$(get_context_state_file)

    if context_state_exists; then
        rm -f "$context_state_file"
    fi

    # Also clear conversation history log if it exists
    local workspace
    workspace=$(get_workspace 2>/dev/null) || workspace="${WORKSPACE:-$HOME/.aiwb/workspace}"
    local history_file="$workspace/.conversation_history.log"
    if [[ -f "$history_file" ]]; then
        rm -f "$history_file"
    fi

    echo "✅ Context cleared"
}

# Check context age and warn if stale
context_state_check_age() {
    if ! context_state_exists; then
        return 0
    fi

    local created_at
    created_at=$(context_state_get "created_at")

    if [[ -z "$created_at" ]]; then
        return 0
    fi

    # Calculate age in days (platform-independent)
    local created_epoch
    local now_epoch
    local age_days

    created_epoch=$(date -d "$created_at" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${created_at:0:19}" +%s 2>/dev/null || echo "0")
    now_epoch=$(date +%s)
    age_days=$(( (now_epoch - created_epoch) / 86400 ))

    if [[ $age_days -gt 7 ]]; then
        echo "⚠️  Context is $age_days days old. Consider running /contextrefresh or /contextclear"
        return 1
    fi

    return 0
}

# Display context state summary
context_state_show() {
    local context_state_file
    context_state_file=$(get_context_state_file)

    if ! context_state_exists; then
        echo "No active context state"
        return 1
    fi

    echo "📋 Context State"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if command -v jq &>/dev/null; then
        local session_id created_at updated_at file_count message_count scan_type scan_time

        session_id=$(jq -r '.session_id // "unknown"' "$context_state_file")
        created_at=$(jq -r '.created_at // "unknown"' "$context_state_file")
        updated_at=$(jq -r '.updated_at // "unknown"' "$context_state_file")
        file_count=$(jq -r '.context_files | length' "$context_state_file")
        message_count=$(jq -r '.conversation_history | length' "$context_state_file")
        scan_type=$(jq -r '.last_scan.type // "none"' "$context_state_file")
        scan_time=$(jq -r '.last_scan.timestamp // "never"' "$context_state_file")

        echo "Session ID:  $session_id"
        echo "Created:     $created_at"
        echo "Updated:     $updated_at"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Files:       $file_count"
        echo "Messages:    $message_count"
        echo "Last Scan:   $scan_type ($scan_time)"

        if [[ $file_count -gt 0 ]]; then
            echo ""
            echo "Context Files:"
            jq -r '.context_files[] | "  • \(.path) (\(.type))"' "$context_state_file"
        fi
    else
        echo "Session:     $(grep session_id "$context_state_file" | head -1)"
        echo "Created:     $(grep created_at "$context_state_file" | head -1)"
        echo ""
        echo "⚠️  Install 'jq' for detailed context information"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Load context files into MODE_UPLOADS array
context_state_load_into_mode() {
    if ! context_state_exists; then
        echo "No context to load"
        return 1
    fi

    local file_count=0
    local files

    # Get list of context files
    if command -v jq &>/dev/null; then
        mapfile -t files < <(jq -r '.context_files[]? | .path' "$context_state_file" 2>/dev/null)
    else
        mapfile -t files < <(grep '"path":' "$context_state_file" | sed 's/.*"path": *"\([^"]*\)".*/\1/')
    fi

    # Load into MODE_UPLOADS
    for file in "${files[@]}"; do
        if [[ -e "$file" ]]; then
            MODE_UPLOADS+=("$file")
            ((file_count++))
        else
            echo "⚠️  Context file not found: $file"
        fi
    done

    if [[ $file_count -gt 0 ]]; then
        echo "✅ Loaded $file_count file(s) into context"
        return 0
    else
        echo "No valid context files to load"
        return 1
    fi
}

# Save current MODE_UPLOADS to context state
context_state_save_from_mode() {
    if [[ ${#MODE_UPLOADS[@]} -eq 0 ]]; then
        echo "No files in context to save"
        return 1
    fi

    # Initialize if needed
    if ! context_state_exists; then
        init_context_state
    fi

    # Clear existing context files
    if command -v jq &>/dev/null; then
        local tmp_file
        tmp_file=$(mktemp)
        jq '.context_files = []' "$context_state_file" > "$tmp_file"
        mv "$tmp_file" "$context_state_file"
        chmod 600 "$context_state_file"
    fi

    # Add all MODE_UPLOADS files
    local saved_count=0
    for file in "${MODE_UPLOADS[@]}"; do
        if context_state_add_file "$file" "manual"; then
            ((saved_count++))
        fi
    done

    echo "✅ Saved $saved_count file(s) to context state"
    return 0
}

# Estimate token count for current context
context_state_estimate_tokens() {
    if ! context_state_exists; then
        echo "0"
        return 0
    fi

    local total_size=0
    local files

    # Get list of context files
    mapfile -t files < <(context_state_list_files)

    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            local size
            size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
            total_size=$((total_size + size))
        fi
    done

    # Rough estimate: 1 token ≈ 4 characters
    local estimated_tokens=$((total_size / 4))

    echo "$estimated_tokens"
}

# Check if context exceeds recommended size
context_state_check_size() {
    local tokens
    tokens=$(context_state_estimate_tokens)

    local threshold=50000  # 50k tokens threshold

    if [[ $tokens -gt $threshold ]]; then
        echo "⚠️  Context size: ~${tokens} tokens"
        echo "    This may exceed API limits. Consider using /contextoptimize"
        return 1
    fi

    return 0
}

# Export functions for use in main script
export -f init_context_state
export -f context_state_exists
export -f context_state_get
export -f context_state_touch
export -f context_state_add_file
export -f context_state_remove_file
export -f context_state_list_files
export -f context_state_save_scan
export -f context_state_add_message
export -f context_state_get_history
export -f context_state_clear
export -f context_state_check_age
export -f context_state_show
export -f context_state_load_into_mode
export -f context_state_save_from_mode
export -f context_state_estimate_tokens
export -f context_state_check_size
