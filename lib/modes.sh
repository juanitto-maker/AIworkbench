#!/usr/bin/env bash
# modes.sh - Mode-based workflow system (/make, /tweak, /debug)

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[[ -z "${AIWB_LIB_UI_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"
[[ -z "${AIWB_LIB_CONFIG_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

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

    # Clear other state
    MODE_PROMPT=""
    MODE_INSTRUCT_FILE=""
    MODE_UPLOADS=()
    MODE_CHECK_PROVIDER=""
    MODE_CHECK_MODEL=""
    MODE_CHECK_INSTRUCT=""
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

# ============================================================================
# MODE SUB-COMMANDS
# ============================================================================

# Set text prompt
mode_prompt() {
    local text="$*"

    if [[ -z "$text" ]]; then
        text=$(ui_input "Enter instructions:")
        [[ -z "$text" ]] && return 0
    fi

    MODE_PROMPT="$text"
    MODE_INSTRUCT_FILE=""  # Clear file if text is set
    success "Prompt set (${#text} characters)"
}

# Set instruction file
mode_instruct() {
    local file="$1"

    if [[ -z "$file" ]]; then
        warn "Usage: instruct <file.md>"
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        err "File not found: $file"
        return 1
    fi

    MODE_INSTRUCT_FILE="$file"
    MODE_PROMPT=""  # Clear text if file is set
    local size=$(wc -w < "$file")
    success "Instructions loaded from file ($size words)"
}

# Interactive model selection
mode_model() {
    while true; do
        local choice
        choice=$(ui_choose "Model Selection" \
            "Choose model" \
            "Use default ($(config_get model_provider) $(config_get model_name))" \
            "Back")

        case "$choice" in
            "Choose model")
                # Select provider
                local provider
                provider=$(ui_choose "Select Provider" \
                    "gemini" \
                    "claude" \
                    "openai" \
                    "groq" \
                    "xai" \
                    "ollama" \
                    "Back")

                [[ "$provider" == "Back" || -z "$provider" ]] && continue

                # Select model
                local models available
                available=$(get_available_models "$provider")
                local model
                model=$(ui_choose "Select Model for $provider" $available "Back")

                [[ "$model" == "Back" || -z "$model" ]] && continue

                MODE_MODEL_PROVIDER="$provider"
                MODE_MODEL_NAME="$model"
                success "Model set to: $provider $model"
                return 0
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

# Upload context files
mode_uploads() {
    local items=("$@")

    if [[ ${#items[@]} -eq 0 ]]; then
        warn "Usage: uploads <file|dir> [<file|dir> ...]"
        return 1
    fi

    local total_size=0
    local count=0

    for item in "${items[@]}"; do
        if [[ ! -e "$item" ]]; then
            warn "Not found: $item (skipping)"
            continue
        fi

        MODE_UPLOADS+=("$item")

        if [[ -f "$item" ]]; then
            local size=$(stat -f%z "$item" 2>/dev/null || stat -c%s "$item" 2>/dev/null || echo 0)
            total_size=$((total_size + size))
            ((count++))
        elif [[ -d "$item" ]]; then
            local file_count=$(find "$item" -type f 2>/dev/null | wc -l | tr -d ' ')
            count=$((count + file_count))
        fi
    done

    local size_kb=$((total_size / 1024))
    success "Uploaded ${#items[@]} items ($count files, ${size_kb} KB)"
}

# Interactive check model selection
mode_check() {
    local instruct_text="$*"

    while true; do
        local choice
        choice=$(ui_choose "Check Model Selection" \
            "Choose check model" \
            "Use auto (different from main model)" \
            "Back")

        case "$choice" in
            "Choose check model")
                # Select provider
                local provider
                provider=$(ui_choose "Select Check Provider" \
                    "gemini" \
                    "claude" \
                    "openai" \
                    "groq" \
                    "xai" \
                    "ollama" \
                    "Back")

                [[ "$provider" == "Back" || -z "$provider" ]] && continue

                # Select model
                local models available
                available=$(get_available_models "$provider")
                local model
                model=$(ui_choose "Select Check Model for $provider" $available "Back")

                [[ "$model" == "Back" || -z "$model" ]] && continue

                MODE_CHECK_PROVIDER="$provider"
                MODE_CHECK_MODEL="$model"

                # Optional check instructions
                if [[ -n "$instruct_text" ]]; then
                    MODE_CHECK_INSTRUCT="$instruct_text"
                elif ui_confirm "Add custom check instructions?" "no"; then
                    MODE_CHECK_INSTRUCT=$(ui_input "Check instructions:")
                fi

                success "Check model set to: $provider $model"
                [[ -n "$MODE_CHECK_INSTRUCT" ]] && msg "With custom instructions: ${MODE_CHECK_INSTRUCT:0:50}..."
                return 0
                ;;
            "Use auto"*)
                MODE_CHECK_PROVIDER="auto"
                MODE_CHECK_MODEL="auto"
                MODE_CHECK_INSTRUCT="$instruct_text"
                success "Auto-check enabled (will use different provider)"
                return 0
                ;;
            "Back"|"")
                return 0
                ;;
        esac
    done
}

# Show mode status
mode_status() {
    ui_header "$MODE_CURRENT Mode Status"

    echo "Instructions:"
    if [[ -n "$MODE_PROMPT" ]]; then
        echo "  Type: Text (${#MODE_PROMPT} chars)"
        echo "  Preview: ${MODE_PROMPT:0:60}..."
    elif [[ -n "$MODE_INSTRUCT_FILE" ]]; then
        echo "  Type: File"
        echo "  File: $MODE_INSTRUCT_FILE"
    else
        echo "  (not set)"
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
        echo "  (none)"
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
        echo "  (not configured)"
    fi
    echo ""
}

# Run mode execution
mode_run() {
    # Validate required fields
    if [[ -z "$MODE_PROMPT" && -z "$MODE_INSTRUCT_FILE" ]]; then
        err "No instructions set. Use 'prompt' or 'instruct' first."
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

    # Add uploaded files context
    if [[ ${#MODE_UPLOADS[@]} -gt 0 ]]; then
        final_prompt="$final_prompt

=== CONTEXT FILES ===
"
        for item in "${MODE_UPLOADS[@]}"; do
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

    # Estimate cost
    ui_header "Cost Estimation"

    local input_tokens
    input_tokens=$(estimate_tokens "$final_prompt")
    local output_tokens=$((input_tokens * 2))  # Rough estimate

    local gen_cost
    gen_cost=$(calculate_cost "$MODE_MODEL_PROVIDER" "$MODE_MODEL_NAME" "$input_tokens" "$output_tokens")

    echo "Generation:"
    echo "  Provider: $MODE_MODEL_PROVIDER ($MODE_MODEL_NAME)"
    echo "  Input tokens: $input_tokens"
    echo "  Output tokens (est): $output_tokens"
    echo "  Estimated cost: \$${gen_cost}"
    echo ""

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
    msg "Generating with $MODE_MODEL_PROVIDER ($MODE_MODEL_NAME)..."
    echo ""

    local output
    output=$(call_api "$final_prompt" "$MODE_MODEL_PROVIDER" "$MODE_MODEL_NAME")
    local gen_exit=$?

    if [[ $gen_exit -ne 0 ]]; then
        err "Generation failed"
        return 1
    fi

    # Save output
    local workspace output_dir
    workspace="$(get_workspace)"
    output_dir="$workspace/outputs"
    ensure_dir "$output_dir"

    local output_file="$output_dir/${MODE_CURRENT}_$(date +%Y%m%d_%H%M%S).md"
    echo "$output" > "$output_file"

    success "Output saved to: $output_file"

    # Show preview
    echo ""
    if $GUM_AVAILABLE; then
        echo "$output" | head -20 | gum style --border rounded
        if [[ $(echo "$output" | wc -l) -gt 20 ]]; then
            echo "... (see file for full output)"
        fi
    else
        echo "Preview:"
        echo "$output" | head -20
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

        local feedback
        feedback=$(call_api "$check_prompt" "$check_provider" "$check_model")

        if [[ $? -eq 0 ]]; then
            # Save feedback
            local feedback_file="${output_file%.md}.feedback.md"
            echo "$feedback" > "$feedback_file"

            echo ""
            ui_info_box "VERIFICATION FEEDBACK" "info"
            echo ""
            if $GUM_AVAILABLE; then
                echo "$feedback" | gum style --border rounded --padding "1 2"
            else
                echo "$feedback"
            fi
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
}

# ============================================================================
# MODE LOOP
# ============================================================================

# Enter mode loop
mode_loop() {
    local mode="$1"
    init_mode "$mode"

    local mode_upper=$(echo "$mode" | tr '[:lower:]' '[:upper:]')
    ui_header "$mode_upper Mode"
    msg "Type 'help' for available commands, 'exit' to leave mode"
    echo ""

    while true; do
        local input

        # Get input
        if $GUM_AVAILABLE; then
            input=$(gum input --placeholder "${mode}> " --width 80) || break
        else
            printf "${CYAN}${mode}>${RESET} "
            safe_read input || break
        fi

        [[ -z "$input" ]] && continue

        # Parse command
        local cmd="${input%% *}"
        local args="${input#* }"
        [[ "$args" == "$cmd" ]] && args=""

        case "$cmd" in
            prompt)
                mode_prompt $args
                ;;
            instruct)
                mode_instruct $args
                ;;
            model)
                mode_model
                ;;
            uploads)
                mode_uploads $args
                ;;
            check)
                mode_check $args
                ;;
            status)
                mode_status
                ;;
            run)
                mode_run
                ;;
            help)
                show_mode_help "$mode"
                ;;
            exit|quit|back)
                msg "Exiting $mode mode"
                reset_mode
                return 0
                ;;
            *)
                warn "Unknown command: $cmd"
                echo "Type 'help' for available commands"
                ;;
        esac

        echo ""
    done

    reset_mode
}

# Show mode help
show_mode_help() {
    local mode="$1"

    cat <<EOF
$mode MODE COMMANDS:
  prompt <text>           Set text instructions
  instruct <file.md>      Load instructions from file
  model                   Choose model (interactive menu)
  uploads <files/dirs>    Upload context files
  check [instructions]    Configure verification
  status                  Show current configuration
  run                     Execute with cost estimation

  help                    Show this help
  exit                    Exit $mode mode

EXAMPLE:
  $mode> prompt "Create a REST API for users"
  $mode> model
  $mode> uploads ./docs/ ./src/models/
  $mode> check "Focus on security"
  $mode> status
  $mode> run
EOF
}

# Export functions
export -f init_mode reset_mode mode_loop
export -f mode_prompt mode_instruct mode_model mode_uploads mode_check mode_status mode_run
