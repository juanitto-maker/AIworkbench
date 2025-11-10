#!/usr/bin/env bash
# modes.sh - Mode-based workflow system (/make, /tweak, /debug)

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[[ -z "${AIWB_LIB_UI_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"
[[ -z "${AIWB_LIB_CONFIG_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Load swarm.sh with error checking
if [[ -z "${AIWB_LIB_SWARM_LOADED:-}" ]]; then
    if source "$(dirname "${BASH_SOURCE[0]}")/swarm.sh"; then
        echo "DEBUG: swarm.sh loaded successfully (AIWB_LIB_SWARM_LOADED=$AIWB_LIB_SWARM_LOADED)" >&2
    else
        echo "ERROR: Failed to load swarm.sh!" >&2
    fi
fi

# ============================================================================
# MODE STATE MANAGEMENT
# ============================================================================

# Global mode state variables
MODE_CURRENT=""
MODE_PROMPT=""
MODE_INSTRUCT_FILE=""
MODE_MODEL_PROVIDER=""
MODE_MODEL_NAME=""
MODE_UPLOADS=()
MODE_CHECK_PROVIDER=""
MODE_CHECK_MODEL=""
MODE_CHECK_INSTRUCT=""

# Initialize mode
init_mode() {
    local mode="$1"
    MODE_CURRENT="$mode"

    # Keep model settings from last run or use defaults
    if [[ -z "$MODE_MODEL_PROVIDER" ]]; then
        MODE_MODEL_PROVIDER="$(config_get model_provider)"
        MODE_MODEL_NAME="$(config_get model_name)"
    fi

    # Don't clear state - persist across menu visits
}

# Reset mode state
reset_mode() {
    MODE_CURRENT=""
    MODE_PROMPT=""
    MODE_INSTRUCT_FILE=""
    MODE_UPLOADS=()
    MODE_CHECK_PROVIDER=""
    MODE_CHECK_MODEL=""
    MODE_CHECK_INSTRUCT=""
    # Keep model settings for next time
}

# Get current instruction display
get_instruction_display() {
    if [[ -n "$MODE_PROMPT" ]]; then
        echo "Text: ${MODE_PROMPT:0:30}..."
    elif [[ -n "$MODE_INSTRUCT_FILE" ]]; then
        echo "File: $(basename "$MODE_INSTRUCT_FILE")"
    else
        echo "(not set)"
    fi
}

# Get model display
get_model_display() {
    echo "$MODE_MODEL_PROVIDER $MODE_MODEL_NAME"
}

# Get uploads display
get_uploads_display() {
    if [[ ${#MODE_UPLOADS[@]} -gt 0 ]]; then
        echo "${#MODE_UPLOADS[@]} items"
    else
        echo "(none)"
    fi
}

# Get check display
get_check_display() {
    if [[ -n "$MODE_CHECK_PROVIDER" ]]; then
        if [[ "$MODE_CHECK_PROVIDER" == "auto" ]]; then
            echo "Auto"
        else
            echo "$MODE_CHECK_PROVIDER $MODE_CHECK_MODEL"
        fi
    else
        echo "(not set)"
    fi
}

# ============================================================================
# MODE MENU FUNCTIONS
# ============================================================================

# Prompt menu (text instruction)
menu_prompt() {
    local text
    text=$(ui_input "Enter instructions:")

    if [[ -n "$text" ]]; then
        MODE_PROMPT="$text"
        MODE_INSTRUCT_FILE=""  # Clear file if text is set
        success "Prompt set (${#text} characters)"
    fi
}

# URL input and download menu
menu_url_input() {
    local mode="$1"  # "upload" or "instruct"
    local url
    url=$(ui_input "Enter URL (GitHub repo, raw file, etc.):")

    if [[ -z "$url" ]]; then
        return 0
    fi

    local workspace download_dir
    workspace="$(get_workspace)"
    download_dir="$workspace/downloads"
    ensure_dir "$download_dir"

    # Check if it's a GitHub repo URL
    if [[ "$url" =~ github\.com.*\.git$ ]] || [[ "$url" =~ ^https://github\.com/[^/]+/[^/]+/?$ ]]; then
        # Clone GitHub repository
        msg "Cloning repository from $url..."
        local repo_name=$(basename "$url" .git)
        local target_dir="$download_dir/$repo_name"

        if [[ -d "$target_dir" ]]; then
            warn "Repository already exists: $target_dir"
            if ui_confirm "Use existing repository?" "yes"; then
                if [[ "$mode" == "upload" ]]; then
                    MODE_UPLOADS+=("$target_dir")
                    success "Added repository: $target_dir"
                else
                    err "Cannot use directory as instruction file. Please select a specific file."
                fi
                return 0
            else
                msg "Removing existing repository..."
                rm -rf "$target_dir"
            fi
        fi

        if git clone "$url" "$target_dir" 2>/dev/null; then
            success "Repository cloned to: $target_dir"
            if [[ "$mode" == "upload" ]]; then
                MODE_UPLOADS+=("$target_dir")
                success "Added repository as context"
            else
                # For instruct mode, let user browse the cloned repo
                local selected_file
                selected_file=$(menu_file_browser "$target_dir")
                if [[ -f "$selected_file" ]]; then
                    MODE_INSTRUCT_FILE="$selected_file"
                    MODE_PROMPT=""
                    local size=$(wc -w < "$selected_file" 2>/dev/null || echo 0)
                    success "Instructions loaded from file ($size words)"
                fi
            fi
        else
            err "Failed to clone repository"
        fi
    else
        # Download direct file
        msg "Downloading file from $url..."
        local filename=$(basename "$url" | cut -d'?' -f1)
        [[ -z "$filename" ]] && filename="downloaded_file"
        local target_file="$download_dir/$filename"

        if curl -fsSL "$url" -o "$target_file" 2>/dev/null; then
            success "File downloaded to: $target_file"
            if [[ "$mode" == "upload" ]]; then
                MODE_UPLOADS+=("$target_file")
                success "Added file as context"
            else
                MODE_INSTRUCT_FILE="$target_file"
                MODE_PROMPT=""
                local size=$(wc -w < "$target_file" 2>/dev/null || echo 0)
                success "Instructions loaded from file ($size words)"
            fi
        else
            err "Failed to download file from URL"
        fi
    fi
}

# Instruct menu (file-based instruction)
menu_instruct() {
    while true; do
        local choice
        local current_file="${MODE_INSTRUCT_FILE:-None}"
        local current_display="Current: $current_file"

        choice=$(ui_choose "Instruction File ($current_display)" \
            "Browse files" \
            "Browse outputs" \
            "Type path manually" \
            "From URL" \
            "View current file" \
            "Clear" \
            "Back")

        case "$choice" in
            "Browse files")
                # Storage location selection
                local storage_choice
                storage_choice=$(ui_choose "Select Storage Location" \
                    "Internal Storage ($HOME)" \
                    "External Storage (SD Card)" \
                    "Current Directory (.)" \
                    "Back")

                case "$storage_choice" in
                    "Internal Storage"*)
                        local selected_file
                        selected_file=$(menu_file_browser "$HOME")
                        if [[ -f "$selected_file" ]]; then
                            MODE_INSTRUCT_FILE="$selected_file"
                            MODE_PROMPT=""  # Clear text if file is set
                            local size=$(wc -w < "$selected_file" 2>/dev/null || echo 0)
                            success "Instructions loaded from file ($size words)"
                        fi
                        ;;
                    "External Storage"*)
                        local ext_path=""
                        if [[ -d "$HOME/storage/shared" ]]; then
                            ext_path="$HOME/storage/shared"
                        elif [[ -d "/storage/emulated/0" ]]; then
                            ext_path="/storage/emulated/0"
                        elif [[ -d "/sdcard" ]]; then
                            ext_path="/sdcard"
                        else
                            warn "Auto-detection failed. Common paths not found."
                            local custom_path
                            custom_path=$(ui_input "Enter external storage path (or leave empty to cancel):")
                            if [[ -n "$custom_path" ]] && [[ -d "$custom_path" ]]; then
                                ext_path="$custom_path"
                            fi
                        fi
                        if [[ -n "$ext_path" ]]; then
                            local selected_file
                            selected_file=$(menu_file_browser "$ext_path")
                            if [[ -f "$selected_file" ]]; then
                                MODE_INSTRUCT_FILE="$selected_file"
                                MODE_PROMPT=""
                                local size=$(wc -w < "$selected_file" 2>/dev/null || echo 0)
                                success "Instructions loaded from file ($size words)"
                            fi
                        fi
                        ;;
                    "Current Directory"*)
                        local selected_file
                        selected_file=$(menu_file_browser ".")
                        if [[ -f "$selected_file" ]]; then
                            MODE_INSTRUCT_FILE="$selected_file"
                            MODE_PROMPT=""
                            local size=$(wc -w < "$selected_file" 2>/dev/null || echo 0)
                            success "Instructions loaded from file ($size words)"
                        fi
                        ;;
                esac
                ;;
            "Browse outputs")
                local workspace output_dir
                workspace="$(get_workspace)"
                output_dir="$workspace/outputs"
                local selected_file
                selected_file=$(menu_file_browser "$output_dir")
                if [[ -f "$selected_file" ]]; then
                    MODE_INSTRUCT_FILE="$selected_file"
                    MODE_PROMPT=""
                    local size=$(wc -w < "$selected_file" 2>/dev/null || echo 0)
                    success "Instructions loaded from file ($size words)"
                fi
                ;;
            "Type path manually")
                local file
                file=$(ui_input "Instruction file path:" "$MODE_INSTRUCT_FILE")
                if [[ -n "$file" ]]; then
                    if [[ -f "$file" ]]; then
                        MODE_INSTRUCT_FILE="$file"
                        MODE_PROMPT=""
                        local size=$(wc -w < "$file" 2>/dev/null || echo 0)
                        success "Instructions loaded from file ($size words)"
                    else
                        err "File not found: $file"
                    fi
                fi
                ;;
            "From URL")
                menu_url_input "instruct"
                ;;
            "View current file")
                if [[ -n "$MODE_INSTRUCT_FILE" ]] && [[ -f "$MODE_INSTRUCT_FILE" ]]; then
                    clear 2>/dev/null || true
                    ui_header "Instruction File: $MODE_INSTRUCT_FILE"
                    echo ""
                    cat "$MODE_INSTRUCT_FILE"
                    echo ""
                    ui_confirm "Press enter to continue..."
                else
                    warn "No instruction file set"
                fi
                ;;
            "Clear")
                MODE_INSTRUCT_FILE=""
                success "Instruction file cleared"
                ;;
            "Back"|"")
                return 0
                ;;
        esac
    done
}

# Model menu - nested navigation
menu_model() {
    while true; do
        local choice
        choice=$(ui_choose "Model Selection" \
            "Choose provider" \
            "Use default ($(config_get model_provider) $(config_get model_name))" \
            "Back")

        case "$choice" in
            "Choose provider")
                menu_model_provider && return 0
                ;;
            "Use default"*)
                MODE_MODEL_PROVIDER="$(config_get model_provider)"
                MODE_MODEL_NAME="$(config_get model_name)"
                success "Using default: $MODE_MODEL_PROVIDER $MODE_MODEL_NAME"
                return 0
                ;;
            "Back"|"")
                return 0
                ;;
        esac
    done
}

# Provider selection submenu
menu_model_provider() {
    while true; do
        local provider
        provider=$(ui_choose "Select Provider" \
            "gemini" \
            "claude" \
            "openai" \
            "groq" \
            "xai" \
            "ollama" \
            "Back")

        case "$provider" in
            "Back"|"")
                return 1
                ;;
            *)
                menu_model_specific "$provider" && return 0
                ;;
        esac
    done
}

# Model selection submenu for specific provider
menu_model_specific() {
    local provider="$1"

    while true; do
        local available
        available=$(get_available_models "$provider")

        local model
        model=$(ui_choose "Select Model for $provider" $available "Back")

        case "$model" in
            "Back"|"")
                return 1
                ;;
            *)
                MODE_MODEL_PROVIDER="$provider"
                MODE_MODEL_NAME="$model"
                success "Model set to: $provider $model"
                return 0
                ;;
        esac
    done
}

# Uploads menu
menu_uploads() {
    while true; do
        local choice
        local current_display=$(get_uploads_display)

        choice=$(ui_choose "Context Files ($current_display)" \
            "Browse files" \
            "Browse outputs" \
            "Type path manually" \
            "From URL" \
            "List uploads" \
            "Clear all" \
            "Back")

        case "$choice" in
            "Browse files")
                # Storage location selection
                local storage_choice
                storage_choice=$(ui_choose "Select Storage Location" \
                    "Internal Storage ($HOME)" \
                    "External Storage (SD Card)" \
                    "Current Directory (.)" \
                    "Back")

                case "$storage_choice" in
                    "Internal Storage"*)
                        menu_file_browser "$HOME"
                        ;;
                    "External Storage"*)
                        # Try common Android/Termux external storage paths
                        local ext_path=""
                        if [[ -d "$HOME/storage/shared" ]]; then
                            ext_path="$HOME/storage/shared"
                        elif [[ -d "/storage/emulated/0" ]]; then
                            ext_path="/storage/emulated/0"
                        elif [[ -d "/sdcard" ]]; then
                            ext_path="/sdcard"
                        else
                            warn "Auto-detection failed. Common paths not found."
                            local custom_path
                            custom_path=$(ui_input "Enter external storage path (or leave empty to cancel):")
                            if [[ -n "$custom_path" ]]; then
                                if [[ -d "$custom_path" ]]; then
                                    ext_path="$custom_path"
                                else
                                    err "Directory not found: $custom_path"
                                fi
                            fi
                        fi
                        [[ -n "$ext_path" ]] && menu_file_browser "$ext_path"
                        ;;
                    "Current Directory"*)
                        menu_file_browser "."
                        ;;
                    "Back"|"")
                        # Do nothing, return to menu
                        ;;
                esac
                ;;
            "Browse outputs")
                menu_outputs_browser
                ;;
            "Type path manually")
                local items
                items=$(ui_input "Enter file/directory paths (space-separated):")
                if [[ -n "$items" ]]; then
                    local added=0
                    for item in $items; do
                        if [[ -e "$item" ]]; then
                            MODE_UPLOADS+=("$item")
                            ((added++))
                        else
                            warn "Not found: $item"
                        fi
                    done
                    [[ $added -gt 0 ]] && success "Added $added item(s)"
                fi
                ;;
            "From URL")
                menu_url_input "upload"
                ;;
            "List uploads")
                if [[ ${#MODE_UPLOADS[@]} -gt 0 ]]; then
                    echo ""
                    msg "Uploaded files:"
                    for item in "${MODE_UPLOADS[@]}"; do
                        if [[ -f "$item" ]]; then
                            local size=$(stat -f%z "$item" 2>/dev/null || stat -c%s "$item" 2>/dev/null || echo 0)
                            local size_kb=$((size / 1024))
                            echo "  - $item (${size_kb} KB)"
                        elif [[ -d "$item" ]]; then
                            local count=$(find "$item" -type f 2>/dev/null | wc -l | tr -d ' ')
                            echo "  - $item/ ($count files)"
                        fi
                    done
                    echo ""
                    ui_confirm "Press enter to continue..."
                else
                    info "No files uploaded yet"
                fi
                ;;
            "Clear all")
                if ui_confirm "Clear all uploaded files?" "no"; then
                    MODE_UPLOADS=()
                    success "Cleared all uploads"
                fi
                ;;
            "Back"|"")
                return 0
                ;;
        esac
    done
}

# Check menu - verification configuration
menu_check() {
    while true; do
        local choice
        choice=$(ui_choose "Check/Verification" \
            "Choose check model" \
            "Use auto (different from main)" \
            "Add custom instructions" \
            "Disable check" \
            "Back")

        case "$choice" in
            "Choose check model")
                menu_check_model && return 0
                ;;
            "Use auto"*)
                MODE_CHECK_PROVIDER="auto"
                MODE_CHECK_MODEL="auto"
                success "Auto-check enabled"
                return 0
                ;;
            "Add custom instructions")
                local instruct
                instruct=$(ui_input "Check instructions:" "$MODE_CHECK_INSTRUCT")
                if [[ -n "$instruct" ]]; then
                    MODE_CHECK_INSTRUCT="$instruct"
                    success "Custom instructions set"
                fi
                ;;
            "Disable check")
                MODE_CHECK_PROVIDER=""
                MODE_CHECK_MODEL=""
                MODE_CHECK_INSTRUCT=""
                success "Check/verification disabled"
                return 0
                ;;
            "Back"|"")
                return 0
                ;;
        esac
    done
}

# Check model selection submenu
menu_check_model() {
    while true; do
        local provider
        provider=$(ui_choose "Select Check Provider" \
            "gemini" \
            "claude" \
            "openai" \
            "groq" \
            "xai" \
            "ollama" \
            "Back")

        case "$provider" in
            "Back"|"")
                return 1
                ;;
            *)
                menu_check_model_specific "$provider" && return 0
                ;;
        esac
    done
}

# Check model specific selection
menu_check_model_specific() {
    local provider="$1"

    while true; do
        local available
        available=$(get_available_models "$provider")

        local model
        model=$(ui_choose "Select Check Model for $provider" $available "Back")

        case "$model" in
            "Back"|"")
                return 1
                ;;
            *)
                MODE_CHECK_PROVIDER="$provider"
                MODE_CHECK_MODEL="$model"
                success "Check model set to: $provider $model"
                return 0
                ;;
        esac
    done
}

# Status menu - display current configuration
menu_status() {
    clear 2>/dev/null || true
    ui_header "$MODE_CURRENT Mode Status"

    echo "Instructions:"
    if [[ -n "$MODE_PROMPT" ]]; then
        echo "  Type: Text (${#MODE_PROMPT} chars)"
        echo "  Preview: ${MODE_PROMPT:0:60}..."
    elif [[ -n "$MODE_INSTRUCT_FILE" ]]; then
        echo "  Type: File"
        echo "  File: $MODE_INSTRUCT_FILE"
    else
        echo "  $(ui_style '(not set)' 'yellow')"
    fi
    echo ""

    echo "Model:"
    echo "  Provider: $MODE_MODEL_PROVIDER"
    echo "  Model: $MODE_MODEL_NAME"
    echo ""

    echo "Context Uploads:"
    if [[ ${#MODE_UPLOADS[@]} -gt 0 ]]; then
        for item in "${MODE_UPLOADS[@]}"; do
            echo "  - $item"
        done
    else
        echo "  $(ui_style '(none)' 'dim')"
    fi
    echo ""

    echo "Check/Verify:"
    if [[ -n "$MODE_CHECK_PROVIDER" ]]; then
        if [[ "$MODE_CHECK_PROVIDER" == "auto" ]]; then
            echo "  Mode: Auto (cross-provider)"
        else
            echo "  Provider: $MODE_CHECK_PROVIDER"
            echo "  Model: $MODE_CHECK_MODEL"
        fi
        [[ -n "$MODE_CHECK_INSTRUCT" ]] && echo "  Custom instructions: ${MODE_CHECK_INSTRUCT:0:50}..."
    else
        echo "  $(ui_style '(not configured)' 'dim')"
    fi
    echo ""

    ui_confirm "Press enter to continue..."
}

# File browser for uploads
menu_file_browser() {
    local current_dir="${1:-.}"

    while true; do
        # Get list of files and directories
        local items=()

        # Add parent directory option if not at root
        if [[ "$current_dir" != "/" ]]; then
            items+=(".. (parent directory)")
        fi

        # Add directories first
        while IFS= read -r dir; do
            [[ -z "$dir" ]] && continue
            items+=("📁 $(basename "$dir")/")
        done < <(find "$current_dir" -maxdepth 1 -type d ! -path "$current_dir" 2>/dev/null | sort)

        # Add files
        while IFS= read -r file; do
            [[ -z "$file" ]] && continue
            items+=("📄 $(basename "$file")")
        done < <(find "$current_dir" -maxdepth 1 -type f 2>/dev/null | sort)

        items+=("✓ Select current directory")
        items+=("Back")

        local choice
        choice=$(ui_choose "Browse: $current_dir" "${items[@]}")

        case "$choice" in
            ".. (parent directory)")
                current_dir="$(dirname "$current_dir")"
                ;;
            "📁 "*)
                local dirname="${choice#📁 }"
                dirname="${dirname%/}"
                current_dir="$current_dir/$dirname"
                ;;
            "📄 "*)
                local filename="${choice#📄 }"
                MODE_UPLOADS+=("$current_dir/$filename")
                success "Added: $current_dir/$filename"
                return 0
                ;;
            "✓ Select current directory")
                MODE_UPLOADS+=("$current_dir")
                success "Added directory: $current_dir"
                return 0
                ;;
            "Back"|"")
                return 0
                ;;
        esac
    done
}

# Outputs browser for uploads
menu_outputs_browser() {
    local workspace output_dir
    workspace="$(get_workspace)"
    output_dir="$workspace/outputs"

    if [[ ! -d "$output_dir" ]]; then
        err "No outputs directory found"
        return 1
    fi

    # Get list of output files sorted by modification time (newest first)
    local files=()
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local basename=$(basename "$file")
        local timestamp=$(stat -f%Sm -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat -c%y "$file" 2>/dev/null | cut -d'.' -f1)
        files+=("$basename ($timestamp)")
    done < <(find "$output_dir" -name "*.md" ! -name "*.feedback.md" -type f -printf "%T@ %p\n" 2>/dev/null | sort -rn | cut -d' ' -f2- || find "$output_dir" -name "*.md" ! -name "*.feedback.md" -type f 2>/dev/null | sort -r)

    if [[ ${#files[@]} -eq 0 ]]; then
        info "No output files found"
        return 0
    fi

    files+=("Back")

    while true; do
        local choice
        choice=$(ui_choose "Select Output to Add" "${files[@]}")

        case "$choice" in
            "Back"|"")
                return 0
                ;;
            *)
                # Extract filename from choice (remove timestamp)
                local filename="${choice%% (*}"
                local filepath="$output_dir/$filename"

                if [[ -f "$filepath" ]]; then
                    MODE_UPLOADS+=("$filepath")
                    success "Added output: $filename"
                    return 0
                fi
                ;;
        esac
    done
}

# View output browser
menu_view_outputs() {
    local workspace output_dir
    workspace="$(get_workspace)"
    output_dir="$workspace/outputs"

    if [[ ! -d "$output_dir" ]]; then
        err "No outputs directory found"
        return 1
    fi

    # Get list of output files sorted by modification time (newest first)
    local files=()
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local basename=$(basename "$file")
        local timestamp=$(stat -f%Sm -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat -c%y "$file" 2>/dev/null | cut -d'.' -f1)
        files+=("$basename ($timestamp)")
    done < <(find "$output_dir" -name "*.md" ! -name "*.feedback.md" -type f -printf "%T@ %p\n" 2>/dev/null | sort -rn | cut -d' ' -f2- || find "$output_dir" -name "*.md" ! -name "*.feedback.md" -type f 2>/dev/null | sort -r)

    if [[ ${#files[@]} -eq 0 ]]; then
        info "No output files found"
        return 0
    fi

    files+=("Back")

    while true; do
        local choice
        choice=$(ui_choose "View Outputs" "${files[@]}")

        case "$choice" in
            "Back"|"")
                return 0
                ;;
            *)
                # Extract filename from choice (remove timestamp)
                local filename="${choice%% (*}"
                local filepath="$output_dir/$filename"

                if [[ -f "$filepath" ]]; then
                    clear 2>/dev/null || true
                    ui_header "Output: $filename"
                    echo ""

                    cat "$filepath"

                    echo ""
                    echo "File location: $filepath"

                    # Calculate and display total cost
                    local workspace logs_dir usage_log
                    workspace="$(get_workspace)"
                    logs_dir="$workspace/logs"
                    usage_log="$logs_dir/usage.jsonl"

                    if [[ -f "$usage_log" ]]; then
                        local total_cost=0
                        while IFS= read -r line; do
                            local cost=$(echo "$line" | jq -r '.cost // 0' 2>/dev/null)
                            total_cost=$(awk "BEGIN {printf \"%.6f\", $total_cost + $cost}")
                        done < "$usage_log"
                        echo "Total cost (all operations): \$${total_cost}"
                    fi
                    echo ""

                    # Add clipboard option if available
                    if has_clipboard; then
                        if ui_confirm "Copy to clipboard?" "no"; then
                            if copy_to_clipboard "$(cat "$filepath")"; then
                                success "Output copied to clipboard!"
                            else
                                err "Failed to copy to clipboard"
                            fi
                        fi
                    fi

                    ui_confirm "Press enter to continue..."
                fi
                ;;
        esac
    done
}

# Run mode execution
mode_run() {
    # Validate required fields
    if [[ -z "$MODE_PROMPT" && -z "$MODE_INSTRUCT_FILE" ]]; then
        err "No instructions set. Use 'Prompt' or 'Instruct' first."
        return 1
    fi

    # Build final prompt
    local final_prompt=""

    if [[ -n "$MODE_INSTRUCT_FILE" ]]; then
        final_prompt=$(cat "$MODE_INSTRUCT_FILE")
    else
        final_prompt="$MODE_PROMPT"
    fi

    # Add mode context
    case "$MODE_CURRENT" in
        make)
            final_prompt="Generate code from scratch:

$final_prompt"
            ;;
        tweak)
            final_prompt="Modify/update the following code:

$final_prompt"
            ;;
        debug)
            final_prompt="Find and fix errors in the code:

$final_prompt"
            ;;
    esac

    # Separate images from text files in context
    local context_images=()
    local has_text_context=false

    # Add uploaded files context
    if [[ ${#MODE_UPLOADS[@]} -gt 0 ]]; then
        # First pass: identify images vs text files
        for item in "${MODE_UPLOADS[@]}"; do
            if [[ -f "$item" ]] && is_image_file "$item"; then
                context_images+=("$item")
            elif [[ -f "$item" ]] || [[ -d "$item" ]]; then
                has_text_context=true
            fi
        done

        # Second pass: add text content to prompt
        if [[ "$has_text_context" = true ]]; then
            final_prompt="$final_prompt

=== CONTEXT FILES ===
"
            for item in "${MODE_UPLOADS[@]}"; do
                # Skip images - they'll be sent separately
                if [[ -f "$item" ]] && is_image_file "$item"; then
                    final_prompt="$final_prompt

--- Image: $item ---
[Image will be analyzed by vision model]
"
                    continue
                fi

                if [[ -f "$item" ]]; then
                    final_prompt="$final_prompt

--- File: $item ---
$(cat "$item")
"
                elif [[ -d "$item" ]]; then
                    final_prompt="$final_prompt

--- Directory: $item ---
$(find "$item" -type f -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.md" 2>/dev/null | head -5 | while read f; do
                        echo "File: $f"
                        head -20 "$f"
                        echo "..."
                    done)
"
                fi
            done
        fi

        # If we have images, add a note
        if [[ ${#context_images[@]} -gt 0 ]]; then
            final_prompt="$final_prompt

=== CONTEXT IMAGES (${#context_images[@]}) ===
"
            for img in "${context_images[@]}"; do
                final_prompt="$final_prompt- $img
"
            done
        fi
    fi

    # Estimate cost
    ui_header "Cost Estimation"

    local input_tokens
    input_tokens=$(estimate_tokens "$final_prompt")
    local output_tokens=$((input_tokens * 2))  # Rough estimate

    local gen_cost
    local swarm_cost="0"

    # Check if swarm mode is enabled
    if [[ "$SWARM_ENABLED" = "true" ]]; then
        swarm_display_cost "$final_prompt" "$SWARM_STRATEGY"
        echo ""
        swarm_cost=$(swarm_estimate_cost "$final_prompt" "$SWARM_STRATEGY")

        # If swarm returns 0, it means context is too small, use standard mode
        if [[ "$swarm_cost" = "0" || "$swarm_cost" = "0.0000" ]]; then
            gen_cost=$(calculate_cost "$MODE_MODEL_PROVIDER" "$MODE_MODEL_NAME" "$input_tokens" "$output_tokens")
            echo "Standard Generation (context too small for swarm):"
            echo "  Provider: $MODE_MODEL_PROVIDER ($MODE_MODEL_NAME)"
            echo "  Input tokens: $input_tokens"
            echo "  Output tokens (est): $output_tokens"
            echo "  Estimated cost: \$${gen_cost}"
            echo ""
        else
            gen_cost="$swarm_cost"
        fi
    else
        gen_cost=$(calculate_cost "$MODE_MODEL_PROVIDER" "$MODE_MODEL_NAME" "$input_tokens" "$output_tokens")
        echo "Generation:"
        echo "  Provider: $MODE_MODEL_PROVIDER ($MODE_MODEL_NAME)"
        echo "  Input tokens: $input_tokens"
        echo "  Output tokens (est): $output_tokens"
        echo "  Estimated cost: \$${gen_cost}"
        echo ""
    fi

    local check_cost="0"
    if [[ -n "$MODE_CHECK_PROVIDER" && "$MODE_CHECK_PROVIDER" != "" ]]; then
        local check_provider="$MODE_CHECK_PROVIDER"
        local check_model="$MODE_CHECK_MODEL"

        if [[ "$check_provider" == "auto" ]]; then
            case "$MODE_MODEL_PROVIDER" in
                gemini) check_provider="claude" ;;
                claude) check_provider="gemini" ;;
                *) check_provider="gemini" ;;
            esac
            check_model=$(get_default_model "$check_provider")
        fi

        local check_input=$((output_tokens + input_tokens / 4))
        local check_output=$((output_tokens / 4))
        check_cost=$(calculate_cost "$check_provider" "$check_model" "$check_input" "$check_output")

        echo "Verification:"
        echo "  Provider: $check_provider ($check_model)"
        echo "  Estimated cost: \$${check_cost}"
        echo ""
    fi

    local total_cost=$(awk "BEGIN {printf \"%.4f\", $gen_cost + $check_cost}")
    echo "Total estimated cost: \$${total_cost}"
    echo ""

    if ! ui_confirm "Proceed with execution?" "yes"; then
        msg "Cancelled"
        return 0
    fi

    # Execute generation
    echo ""

    local output
    local gen_exit=0

    # Check if swarm mode should be used
    if [[ "$SWARM_ENABLED" = "true" ]]; then
        echo "DEBUG: SWARM_ENABLED=true, calling swarm_execute..." >&2
        echo "DEBUG: final_prompt length=${#final_prompt}, MODE_CURRENT=$MODE_CURRENT" >&2

        # Check if swarm_execute function exists
        if ! type swarm_execute &>/dev/null; then
            echo "ERROR: swarm_execute function not found!" >&2
            echo "DEBUG: AIWB_LIB_SWARM_LOADED=${AIWB_LIB_SWARM_LOADED:-not set}" >&2
            return 1
        fi
        echo "DEBUG: swarm_execute function found" >&2

        # Try swarm execution
        output=$(swarm_execute "$final_prompt" "$MODE_CURRENT")
        gen_exit=$?

        echo "DEBUG: swarm_execute returned with exit code: $gen_exit" >&2
        echo "DEBUG: output length: ${#output}" >&2

        # If swarm returns non-zero, fall back to standard mode
        if [[ $gen_exit -ne 0 ]]; then
            warn "Swarm execution failed or not applicable, falling back to standard mode"
            msg "Generating with $MODE_MODEL_PROVIDER ($MODE_MODEL_NAME)..."
            ui_blink "Generating response..."

            if [[ ${#context_images[@]} -gt 0 ]]; then
                output=$(call_api_with_images "$final_prompt" "$MODE_MODEL_PROVIDER" "$MODE_MODEL_NAME" "" "${context_images[@]}")
            else
                output=$(call_api "$final_prompt" "$MODE_MODEL_PROVIDER" "$MODE_MODEL_NAME")
            fi
            gen_exit=$?
            ui_clear_line
        fi
    else
        # Standard mode execution
        msg "Generating with $MODE_MODEL_PROVIDER ($MODE_MODEL_NAME)..."
        ui_blink "Generating response..."

        if [[ ${#context_images[@]} -gt 0 ]]; then
            output=$(call_api_with_images "$final_prompt" "$MODE_MODEL_PROVIDER" "$MODE_MODEL_NAME" "" "${context_images[@]}")
        else
            output=$(call_api "$final_prompt" "$MODE_MODEL_PROVIDER" "$MODE_MODEL_NAME")
        fi
        gen_exit=$?
        ui_clear_line
    fi

    echo ""

    # Check if interrupted
    if [[ $gen_exit -eq 130 ]]; then
        echo ""
        return 130
    fi

    if [[ $gen_exit -ne 0 ]]; then
        err "Generation failed"
        return 1
    fi

    # Save output
    local workspace output_dir
    workspace="$(get_workspace)"
    output_dir="$workspace/outputs"
    ensure_dir "$output_dir"

    # Create filename with model information
    local model_slug="${MODE_MODEL_PROVIDER}_${MODE_MODEL_NAME}"
    # Replace spaces and special characters with underscores
    model_slug=$(echo "$model_slug" | tr ' /' '_' | tr -cd '[:alnum:]_-')
    local output_file="$output_dir/${MODE_CURRENT}_${model_slug}_$(date +%Y%m%d_%H%M%S).md"
    echo "$output" > "$output_file"

    success "Output saved to: $output_file"

    # Show preview
    echo ""
    echo "${CYAN}${BOLD}Preview:${RESET}"
    echo "$output" | head -20
    if [[ $(echo "$output" | wc -l) -gt 20 ]]; then
        echo "... (see file for full output)"
    fi
    echo ""

    # Track actual cost
    local actual_input=$(estimate_tokens "$final_prompt")
    local actual_output=$(estimate_tokens "$output")
    local actual_gen_cost=$(calculate_cost "$MODE_MODEL_PROVIDER" "$MODE_MODEL_NAME" "$actual_input" "$actual_output")
    track_usage "$MODE_MODEL_PROVIDER" "$MODE_MODEL_NAME" "$final_prompt" "$output"

    # Run check if configured
    local actual_check_cost="0"
    if [[ -n "$MODE_CHECK_PROVIDER" ]]; then
        echo ""
        msg "Running verification..."

        local check_provider="$MODE_CHECK_PROVIDER"
        local check_model="$MODE_CHECK_MODEL"

        if [[ "$check_provider" == "auto" ]]; then
            case "$MODE_MODEL_PROVIDER" in
                gemini) check_provider="claude" ;;
                claude) check_provider="gemini" ;;
                *) check_provider="gemini" ;;
            esac
            check_model=$(get_default_model "$check_provider")
        fi

        # Build check prompt
        local check_prompt="${MODE_CHECK_INSTRUCT:-Review the following code for quality, security, and best practices:}

=== GENERATED CODE ===
$output

=== INSTRUCTIONS ===
Provide specific, actionable feedback."

        # Show blinking cursor for verification (as requested by user)
        ui_blink "Running verification with $check_provider..."

        local feedback
        feedback=$(call_api "$check_prompt" "$check_provider" "$check_model")
        local verify_exit=$?

        # Clear blinking cursor
        ui_clear_line

        # Check if interrupted
        if [[ $verify_exit -eq 130 ]]; then
            echo ""
            return 130
        fi

        if [[ $verify_exit -eq 0 ]]; then
            # Save feedback
            local feedback_file="${output_file%.md}.feedback.md"
            echo "$feedback" > "$feedback_file"

            echo ""
            ui_info_box "VERIFICATION FEEDBACK" "info"
            echo ""
            echo "$feedback"
            echo ""
            success "Feedback saved to: $feedback_file"

            # Track check cost
            local check_input=$(estimate_tokens "$check_prompt")
            local check_output=$(estimate_tokens "$feedback")
            actual_check_cost=$(calculate_cost "$check_provider" "$check_model" "$check_input" "$check_output")
            track_usage "$check_provider" "$check_model" "$check_prompt" "$feedback"
        fi
    fi

    # Show actual costs
    echo ""
    ui_header "Actual Costs"
    echo "Generation: \$${actual_gen_cost}"
    [[ "$actual_check_cost" != "0" ]] && echo "Verification: \$${actual_check_cost}"
    local actual_total=$(awk "BEGIN {printf \"%.4f\", $actual_gen_cost + $actual_check_cost}")
    echo "Total: \$${actual_total}"
    echo ""

    success "Done!"
    echo ""

    # What's next menu
    while true; do
        local choice
        local menu_options=("View output" "Copy output to clipboard" "View all outputs" "Run again" "Back to mode menu")

        # Remove clipboard option if not available
        if ! has_clipboard; then
            menu_options=("View output" "View all outputs" "Run again" "Back to mode menu")
        fi

        choice=$(ui_choose "What's next?" "${menu_options[@]}")

        case "$choice" in
            "View output")
                clear 2>/dev/null || true
                ui_header "Generated Output"
                echo ""

                cat "$output_file"

                echo ""
                echo "File location: $output_file"
                echo ""
                ui_confirm "Press enter to continue..."
                ;;
            "Copy output to clipboard")
                if copy_to_clipboard "$(cat "$output_file")"; then
                    success "Output copied to clipboard!"
                else
                    err "Failed to copy to clipboard"
                fi
                ;;
            "View all outputs")
                menu_view_outputs
                ;;
            "Run again")
                mode_run
                return $?
                ;;
            "Back to mode menu"|"")
                return 0
                ;;
        esac
    done
}

# ============================================================================
# MODE MENU LOOP
# ============================================================================

# Main mode menu loop
mode_loop() {
    local mode="$1"
    init_mode "$mode"

    local mode_upper=$(echo "$mode" | tr '[:lower:]' '[:upper:]')

    while true; do
        # Build menu with current state
        local instr_display=$(get_instruction_display)
        local model_display=$(get_model_display)
        local uploads_display=$(get_uploads_display)
        local check_display=$(get_check_display)
        local swarm_display=$(get_swarm_display)

        local choice
        choice=$(ui_choose "$mode_upper Mode" \
            "Prompt (text)" \
            "Instruct (file)" \
            "Model: $model_display" \
            "Uploads: $uploads_display" \
            "Check: $check_display" \
            "Swarm: $swarm_display" \
            "Status" \
            "Run" \
            "View outputs" \
            "Back")

        case "$choice" in
            "Prompt (text)")
                menu_prompt
                ;;
            "Instruct (file)")
                menu_instruct
                ;;
            "Model:"*)
                menu_model
                ;;
            "Uploads:"*)
                menu_uploads
                ;;
            "Check:"*)
                menu_check
                ;;
            "Swarm:"*)
                menu_swarm
                ;;
            "Status")
                menu_status
                ;;
            "Run")
                mode_run
                local run_exit=$?
                # If interrupted, exit mode loop
                if [[ $run_exit -eq 130 ]]; then
                    return 130
                fi
                ;;
            "View outputs")
                menu_view_outputs
                ;;
            "Back"|"")
                return 0
                ;;
        esac
    done
}

# Export functions
export -f init_mode reset_mode mode_loop
export -f menu_prompt menu_instruct menu_model menu_uploads menu_check menu_swarm menu_status mode_run
export -f menu_model_provider menu_model_specific
export -f menu_check_model menu_check_model_specific
export -f menu_file_browser menu_outputs_browser menu_view_outputs menu_url_input
export -f get_instruction_display get_model_display get_uploads_display get_check_display get_swarm_display
