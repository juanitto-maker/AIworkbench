#!/usr/bin/env bash
# editor.sh - Direct file editing for AIWB (like Claude Code)
# Enables AI to read, edit, and write files directly in your repo

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[[ -z "${AIWB_LIB_CONFIG_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
[[ -z "${AIWB_LIB_UI_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"
[[ -z "${AIWB_LIB_API_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/api.sh"

# ============================================================================
# REPO CONTEXT
# ============================================================================

# Global repo context
AIWB_REPO_PATH=""
AIWB_REPO_NAME=""
AIWB_REPO_BRANCH=""
AIWB_REPO_REMOTE=""
AIWB_REPO_ENABLED=false

# Detect if we're in a git repository OR any directory
detect_repo() {
    # Default to current directory - ANY folder can be contextualized
    # Use safe_cwd to handle missing CWD on Termux
    AIWB_REPO_ENABLED=true
    AIWB_REPO_PATH="$(safe_cwd)"
    AIWB_REPO_NAME="$(basename "$AIWB_REPO_PATH" 2>/dev/null || echo "workspace")"
    AIWB_REPO_BRANCH="local"
    AIWB_REPO_REMOTE=""

    # Check if git is available and if we're in a git repo
    if have git && git rev-parse --git-dir >/dev/null 2>&1; then
        # Override with git info if available
        AIWB_REPO_PATH="$(git rev-parse --show-toplevel 2>/dev/null || safe_cwd)"
        AIWB_REPO_NAME="$(basename "$AIWB_REPO_PATH" 2>/dev/null || echo "workspace")"
        AIWB_REPO_BRANCH="$(git branch --show-current 2>/dev/null || echo "local")"
        AIWB_REPO_REMOTE="$(git remote get-url origin 2>/dev/null || echo "")"
    fi

    return 0  # Always succeed
}

# Check if repo mode is enabled
is_repo_mode() {
    [[ "$AIWB_REPO_ENABLED" == "true" ]]
}

# Get repo status summary
get_repo_status() {
    if ! is_repo_mode; then
        echo "No repo"
        return
    fi

    local status_line="$AIWB_REPO_NAME ($AIWB_REPO_BRANCH)"

    # Check for uncommitted changes
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        status_line="$status_line *"
    fi

    # Check ahead/behind
    local ahead behind
    ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
    behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")

    if [[ "$ahead" != "0" ]] || [[ "$behind" != "0" ]]; then
        status_line="$status_line [↑$ahead ↓$behind]"
    fi

    echo "$status_line"
}

# ============================================================================
# FILE OPERATIONS
# ============================================================================

# Read a file from the repo
read_file() {
    local file_path="$1"
    local full_path

    # Handle relative vs absolute paths
    if [[ "$file_path" = /* ]]; then
        full_path="$file_path"
    elif is_repo_mode; then
        full_path="$AIWB_REPO_PATH/$file_path"
    else
        full_path="$(safe_cwd)/$file_path"
    fi

    if [[ ! -f "$full_path" ]]; then
        err "File not found: $file_path"
        return 1
    fi

    cat "$full_path"
}

# Write content to a file
write_file() {
    local file_path="$1"
    local content="$2"
    local full_path

    # Handle relative vs absolute paths
    if [[ "$file_path" = /* ]]; then
        full_path="$file_path"
    elif is_repo_mode; then
        full_path="$AIWB_REPO_PATH/$file_path"
    else
        full_path="$(safe_cwd)/$file_path"
    fi

    # Create directory if needed
    local dir
    dir="$(dirname "$full_path")"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi

    echo "$content" > "$full_path"
    success "Written: $file_path"
}

# List files in repo/directory
list_files() {
    local path="${1:-.}"
    local pattern="${2:-*}"

    local base_path
    if is_repo_mode; then
        base_path="$AIWB_REPO_PATH/$path"
    else
        base_path="$(safe_cwd)/$path"
    fi

    find "$base_path" -name "$pattern" -type f 2>/dev/null | head -50
}

# Find files matching pattern
find_files() {
    local pattern="$1"
    local base_path

    if is_repo_mode; then
        base_path="$AIWB_REPO_PATH"
    else
        base_path="$(safe_cwd)"
    fi

    # Use git ls-files if in repo (respects .gitignore)
    if is_repo_mode; then
        git -C "$base_path" ls-files "*$pattern*" 2>/dev/null | head -20
    else
        find "$base_path" -name "*$pattern*" -type f 2>/dev/null | head -20
    fi
}

# ============================================================================
# DIFF AND PREVIEW
# ============================================================================

# Show diff between original and new content
show_diff() {
    local file_path="$1"
    local new_content="$2"
    local full_path

    if [[ "$file_path" = /* ]]; then
        full_path="$file_path"
    elif is_repo_mode; then
        full_path="$AIWB_REPO_PATH/$file_path"
    else
        full_path="$(safe_cwd)/$file_path"
    fi

    # Create temp file with new content
    local tmp_new
    tmp_new=$(aiwb_mktemp)
    echo "$new_content" > "$tmp_new"

    echo ""
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo "${BOLD}DIFF PREVIEW: $file_path${RESET}"
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""

    if [[ -f "$full_path" ]]; then
        # Show unified diff with colors
        diff -u "$full_path" "$tmp_new" 2>/dev/null | while IFS= read -r line; do
            case "$line" in
                ---*) echo "${RED}$line${RESET}" ;;
                +++*) echo "${GREEN}$line${RESET}" ;;
                @@*) echo "${CYAN}$line${RESET}" ;;
                -*) echo "${RED}$line${RESET}" ;;
                +*) echo "${GREEN}$line${RESET}" ;;
                *) echo "$line" ;;
            esac
        done
    else
        echo "${GREEN}(New file)${RESET}"
        echo ""
        # Show first 30 lines of new file
        echo "$new_content" | head -"$AIWB_EDITOR_PREVIEW_THRESHOLD"
        local total_lines
        total_lines=$(echo "$new_content" | wc -l)
        if [[ $total_lines -gt $AIWB_EDITOR_PREVIEW_THRESHOLD ]]; then
            echo "${DIM}... ($((total_lines - AIWB_EDITOR_PREVIEW_THRESHOLD)) more lines)${RESET}"
        fi
    fi

    echo ""
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    rm -f "$tmp_new"
}

# Apply changes with confirmation
apply_changes() {
    local file_path="$1"
    local new_content="$2"
    local skip_confirm="${3:-false}"

    # Show diff
    show_diff "$file_path" "$new_content"

    # Ask for confirmation unless skipped
    if [[ "$skip_confirm" != "true" ]]; then
        echo ""
        local choice
        if $GUM_AVAILABLE; then
            choice=$(gum choose --header "Apply changes to $file_path?" "Yes, apply" "No, cancel" "Edit more")
        else
            echo "Apply changes? [y]es / [n]o / [e]dit more: "
            read -r choice
        fi

        case "$choice" in
            "Yes, apply"|[Yy]|[Yy]es)
                write_file "$file_path" "$new_content"
                return 0
                ;;
            "Edit more"|[Ee]|[Ee]dit*)
                return 2  # Signal to continue editing
                ;;
            *)
                info "Changes cancelled"
                return 1
                ;;
        esac
    else
        write_file "$file_path" "$new_content"
        return 0
    fi
}

# ============================================================================
# AI-POWERED EDITING
# ============================================================================

# Build context from file(s) for AI
build_file_context() {
    local files=("$@")
    local context=""

    for file in "${files[@]}"; do
        local content
        content=$(read_file "$file" 2>/dev/null)
        if [[ -n "$content" ]]; then
            context+="
=== FILE: $file ===
$content
=== END FILE ===
"
        fi
    done

    echo "$context"
}

# Edit a file using AI
edit_file_with_ai() {
    local file_path="$1"
    local instructions="$2"
    local provider="${3:-$(config_get model_provider)}"
    local model="${4:-$(config_get model_name)}"

    # Read the file
    local file_content
    file_content=$(read_file "$file_path")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    # Build prompt for AI
    local prompt="You are a code editor. Edit the following file according to the instructions.

IMPORTANT: Return ONLY the complete modified file content. No explanations, no markdown code blocks, no comments about what you changed. Just the raw file content that should replace the original.

FILE: $file_path
CURRENT CONTENT:
$file_content

INSTRUCTIONS: $instructions

Return the complete modified file content now:"

    # Show progress
    ui_blink "Generating edit..."

    # Call AI
    local response
    response=$(call_api "$prompt" "$provider" "$model")
    local exit_code=$?

    ui_clear_line

    if [[ $exit_code -ne 0 ]]; then
        err "AI request failed"
        return 1
    fi

    # Clean up response (remove markdown code blocks if present)
    local cleaned_response
    cleaned_response=$(echo "$response" | sed -E 's/^```[a-zA-Z]*$//' | sed -E 's/^```$//')

    # Remove leading/trailing empty lines
    cleaned_response=$(echo "$cleaned_response" | sed '/./,$!d' | sed ':a;/^$/N;/\n$/ba')

    # Apply changes with confirmation
    apply_changes "$file_path" "$cleaned_response"
}

# Create a new file using AI
create_file_with_ai() {
    local file_path="$1"
    local instructions="$2"
    local provider="${3:-$(config_get model_provider)}"
    local model="${4:-$(config_get model_name)}"

    # Check if file already exists
    local full_path
    if [[ "$file_path" = /* ]]; then
        full_path="$file_path"
    elif is_repo_mode; then
        full_path="$AIWB_REPO_PATH/$file_path"
    else
        full_path="$(safe_cwd)/$file_path"
    fi

    if [[ -f "$full_path" ]]; then
        warn "File already exists: $file_path"
        if ! ui_confirm "Overwrite existing file?"; then
            return 1
        fi
    fi

    # Determine file type from extension
    local ext="${file_path##*.}"

    # Build prompt for AI
    local prompt="You are a code generator. Create a new file according to the instructions.

IMPORTANT: Return ONLY the file content. No explanations, no markdown code blocks, no comments. Just the raw file content.

FILE TO CREATE: $file_path
FILE TYPE: $ext

INSTRUCTIONS: $instructions

Return the complete file content now:"

    # Show progress
    ui_blink "Generating file..."

    # Call AI
    local response
    response=$(call_api "$prompt" "$provider" "$model")
    local exit_code=$?

    ui_clear_line

    if [[ $exit_code -ne 0 ]]; then
        err "AI request failed"
        return 1
    fi

    # Clean up response
    local cleaned_response
    cleaned_response=$(echo "$response" | sed -E 's/^```[a-zA-Z]*$//' | sed -E 's/^```$//')
    cleaned_response=$(echo "$cleaned_response" | sed '/./,$!d' | sed ':a;/^$/N;/\n$/ba')

    # Apply changes with confirmation
    apply_changes "$file_path" "$cleaned_response"
}

# Smart edit - AI figures out which files to modify
smart_edit() {
    local instructions="$1"
    local provider="${2:-$(config_get model_provider)}"
    local model="${3:-$(config_get model_name)}"

    if ! is_repo_mode; then
        err "Smart edit requires a git repository context"
        err "Please run aiwb from within a git repository"
        return 1
    fi

    # Get list of files in repo
    local file_list
    file_list=$(git -C "$AIWB_REPO_PATH" ls-files 2>/dev/null | head -100)

    # First, ask AI which files need to be modified
    local analysis_prompt="You are a code assistant. Based on the user's request, determine which files need to be modified.

PROJECT FILES:
$file_list

USER REQUEST: $instructions

Respond with ONLY a JSON array of file paths that need to be modified or created. Example:
[\"src/components/Button.jsx\", \"src/styles/button.css\"]

If you need to create a new file, include it in the list.
If no files need modification, respond with: []

Files to modify:"

    ui_blink "Analyzing request..."

    local analysis
    analysis=$(call_api "$analysis_prompt" "$provider" "$model")

    ui_clear_line

    # Parse the file list from AI response
    local files_to_edit
    files_to_edit=$(echo "$analysis" | grep -oE '\["[^]]+"\]' | head -1)

    if [[ -z "$files_to_edit" ]] || [[ "$files_to_edit" == "[]" ]]; then
        info "AI determined no files need modification for this request."
        echo ""
        echo "You can specify a file directly:"
        echo "  /edit <file> <instructions>"
        return 0
    fi

    # Extract file paths
    local files=()
    while IFS= read -r file; do
        file=$(echo "$file" | tr -d '", ')
        [[ -n "$file" ]] && files+=("$file")
    done < <(echo "$files_to_edit" | tr ',' '\n' | sed 's/\[//g;s/\]//g')

    if [[ ${#files[@]} -eq 0 ]]; then
        info "No files identified for modification"
        return 0
    fi

    echo ""
    msg "Files to modify:"
    for f in "${files[@]}"; do
        echo "  - $f"
    done
    echo ""

    if ! ui_confirm "Proceed with editing these files?"; then
        return 1
    fi

    # Edit each file
    local modified=0
    for file in "${files[@]}"; do
        echo ""
        msg "Editing: $file"

        # Check if file exists or needs to be created
        local full_path="$AIWB_REPO_PATH/$file"
        if [[ -f "$full_path" ]]; then
            edit_file_with_ai "$file" "$instructions" "$provider" "$model"
        else
            create_file_with_ai "$file" "$instructions" "$provider" "$model"
        fi

        if [[ $? -eq 0 ]]; then
            ((modified++))
        fi
    done

    echo ""
    if [[ $modified -gt 0 ]]; then
        success "Modified $modified file(s)"
        echo ""
        echo "Next steps:"
        echo "  /github status     - Review changes"
        echo "  /github commit     - Commit changes"
        echo "  /github push       - Push to remote"
    fi
}

# ============================================================================
# INTERACTIVE COMMANDS
# ============================================================================

# Main edit command handler
cmd_edit() {
    local args="$*"

    if [[ -z "$args" ]]; then
        # Show help
        cat <<'EOF'
Usage: /edit <file> <instructions>
       /edit <instructions>  (AI determines files)

Examples:
  /edit src/app.js "Add error handling to the login function"
  /edit "Add a dark mode toggle to the settings page"
  /edit README.md "Update installation instructions"

The AI will:
1. Read the file(s)
2. Generate the changes
3. Show you a diff preview
4. Apply changes after your confirmation
EOF
        return 0
    fi

    # Check if first argument is a file path
    local first_word="${args%% *}"
    local rest="${args#* }"

    # Determine if first word looks like a file path
    if [[ "$first_word" == *"/"* ]] || [[ "$first_word" == *"."* ]]; then
        # Explicit file path given
        if [[ "$rest" == "$args" ]]; then
            err "Please provide editing instructions"
            echo "Usage: /edit <file> <instructions>"
            return 1
        fi

        local full_path
        if is_repo_mode; then
            full_path="$AIWB_REPO_PATH/$first_word"
        else
            full_path="$(safe_cwd)/$first_word"
        fi

        if [[ -f "$full_path" ]]; then
            edit_file_with_ai "$first_word" "$rest"
        else
            echo "File not found: $first_word"
            if ui_confirm "Create new file?"; then
                create_file_with_ai "$first_word" "$rest"
            fi
        fi
    else
        # No explicit file - use smart edit
        smart_edit "$args"
    fi
}

# ============================================================================
# EXPORTS
# ============================================================================

export AIWB_LIB_EDITOR_LOADED=1
