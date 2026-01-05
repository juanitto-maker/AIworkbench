#!/usr/bin/env bash
# ui.sh - Beautiful TUI components for AIWB

# Guard: prevent multiple sourcing
[[ -n "${AIWB_LIB_UI_LOADED:-}" ]] && return 0

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ============================================================================
# GUM AVAILABILITY
# ============================================================================

GUM_AVAILABLE=false
have gum && GUM_AVAILABLE=true

# ============================================================================
# INPUT FUNCTIONS
# ============================================================================

# Get user input
ui_input() {
    local prompt="$1"
    local default="${2:-}"
    local placeholder="${3:-$prompt}"

    # Only use gum if stdin is a terminal (not piped)
    if [[ -t 0 ]] && [[ "${AIWB_TEST_MODE:-0}" != "1" ]] && $GUM_AVAILABLE; then
        gum input --placeholder "$placeholder" ${default:+--value "$default"}
    else
        local result
        if [[ -n "$default" ]]; then
            if ! safe_read -p "$prompt [$default]: " result; then
                return 1
            fi
            echo "${result:-$default}"
        else
            if ! safe_read -p "$prompt: " result; then
                return 1
            fi
            echo "$result"
        fi
    fi
}

# Get password input
ui_password() {
    local prompt="$1"

    if $GUM_AVAILABLE; then
        gum input --password --placeholder "$prompt"
    else
        local result
        # Note: read -s doesn't work with safe_read, use direct read
        # This is acceptable since password input is always from tty
        if ! read -rsp "$prompt: " result 2>/dev/null; then
            return 1
        fi
        echo "$result"
        echo >&2  # newline after password
    fi
}

# Multi-line text input
ui_write() {
    local prompt="${1:-Enter text (Ctrl+D when done):}"
    local height="${2:-10}"

    if $GUM_AVAILABLE; then
        gum write --placeholder "$prompt" --height "$height"
    else
        echo "$prompt" >&2
        cat
    fi
}

# ============================================================================
# SELECTION FUNCTIONS
# ============================================================================

# Choose from list
ui_choose() {
    local header="${1:-Choose:}"
    shift
    local options=("$@")

    if $GUM_AVAILABLE; then
        printf '%s\n' "${options[@]}" | gum choose --header "$header" --height 15
    else
        echo "$header" >&2
        local i=1
        for opt in "${options[@]}"; do
            echo "$i) $opt" >&2
            ((i++))
        done
        echo -n "> " >&2
        local choice
        if ! safe_read choice; then
            return 1
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice > 0 && choice <= ${#options[@]})); then
            echo "${options[$((choice-1))]}"
        fi
    fi
}

# Multi-select from list
ui_choose_multi() {
    local header="${1:-Choose (space to select, enter to confirm):}"
    shift
    local options=("$@")

    if $GUM_AVAILABLE; then
        printf '%s\n' "${options[@]}" | gum choose --no-limit --header "$header"
    else
        # Fallback: simple multi-choice
        echo "$header" >&2
        echo "Enter numbers separated by spaces (e.g., 1 3 5):" >&2
        local i=1
        for opt in "${options[@]}"; do
            echo "$i) $opt" >&2
            ((i++))
        done
        echo -n "> " >&2
        local choices
        if ! safe_read choices; then
            return 1
        fi
        for choice in $choices; do
            if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice > 0 && choice <= ${#options[@]})); then
                echo "${options[$((choice-1))]}"
            fi
        done
    fi
}

# Filter/search list
ui_filter() {
    local placeholder="${1:-Filter:}"
    shift
    local options=("$@")

    if $GUM_AVAILABLE; then
        printf '%s\n' "${options[@]}" | gum filter --placeholder "$placeholder" --height 15
    else
        # Fallback to fzf if available
        if have fzf; then
            printf '%s\n' "${options[@]}" | fzf --prompt "$placeholder "
        else
            # Simple grep-based filter
            echo "Type to filter (supports regex):" >&2
            echo -n "> " >&2
            local pattern
            if ! safe_read pattern; then
                return 1
            fi
            printf '%s\n' "${options[@]}" | grep -i "$pattern" | head -1
        fi
    fi
}

# ============================================================================
# CONFIRMATION
# ============================================================================

ui_confirm() {
    local prompt="${1:-Are you sure?}"
    local default="${2:-no}"  # yes or no

    if $GUM_AVAILABLE; then
        if [[ "$default" == "yes" ]]; then
            gum confirm --default=true "$prompt"
        else
            gum confirm --default=false "$prompt"
        fi
    else
        confirm "$prompt" "${default:0:1}"
    fi
}

# ============================================================================
# PROGRESS AND SPINNERS
# ============================================================================

# Show progress bar
ui_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-Processing...}"

    if $GUM_AVAILABLE; then
        # gum doesn't have a built-in progress bar, so we fake it
        local percent=$((current * 100 / total))
        local filled=$((percent / 2))
        local empty=$((50 - filled))
        local bar
        bar="$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))"
        echo -ne "\r${CYAN}${bar}${RESET} ${percent}% - ${message}"
        if ((current >= total)); then
            echo ""
        fi
    else
        local percent=$((current * 100 / total))
        local filled=$((percent / 2))
        local empty=$((50 - filled))
        local bar
        bar="$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))"
        echo -ne "\r${bar} ${percent}% - ${message}"
        if ((current >= total)); then
            echo ""
        fi
    fi
}

# Show spinner (use as: ui_spinner "message" & pid=$!; ...; kill $pid)
ui_spinner() {
    local message="${1:-Loading...}"

    if $GUM_AVAILABLE; then
        gum spin --spinner dot --title "$message" -- sleep 999999
    else
        local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
        local i=0
        while true; do
            i=$(( (i+1) % ${#spinstr} ))
            printf "\r${CYAN}${spinstr:$i:1}${RESET} %s" "$message"
            sleep 0.1
        done
    fi
}

# Show blinking cursor animation (simpler, inline version)
ui_blink() {
    local message="$1"
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=$((RANDOM % ${#spinstr}))
    i=$(( (i+1) % ${#spinstr} ))
    printf "\r${CYAN}${spinstr:$i:1}${RESET} %s" "$message"
}

# Clear spinner/blink line
ui_clear_line() {
    echo -ne "\r\033[K"
}

# ============================================================================
# FORMATTING AND DISPLAY
# ============================================================================

# Display styled header
ui_header() {
    local text="$1"
    local width="${2:-60}"

    if $GUM_AVAILABLE; then
        gum style --border double --width "$width" --padding "1 2" --bold "$text"
    else
        local line
        line="$(printf '═%.0s' $(seq 1 $width))"
        echo ""
        echo "${BOLD}${CYAN}╔${line}╗${RESET}"
        printf "${BOLD}${CYAN}║${RESET} ${BOLD}%-$((width))s${RESET} ${BOLD}${CYAN}║${RESET}\n" "$text"
        echo "${BOLD}${CYAN}╚${line}╝${RESET}"
        echo ""
    fi
}

# Display info box
ui_info_box() {
    local text="$1"
    local type="${2:-info}"  # info, success, warning, error
    local width="${3:-60}"

    local color border_color
    case "$type" in
        success) color="${GREEN}"; border_color="green" ;;
        warning) color="${YELLOW}"; border_color="yellow" ;;
        error) color="${RED}"; border_color="red" ;;
        *) color="${BLUE}"; border_color="blue" ;;
    esac

    if $GUM_AVAILABLE; then
        echo "$text" | gum style --border rounded --border-foreground "$border_color" \
            --width "$width" --padding "1 2"
    else
        local line
        line="$(printf '─%.0s' $(seq 1 $((width - 2))))"
        echo "${color}┌${line}┐${RESET}"
        echo "$text" | fold -w $((width - 4)) -s | while IFS= read -r line; do
            printf "${color}│${RESET} %-$((width - 4))s ${color}│${RESET}\n" "$line"
        done
        echo "${color}└${line}┘${RESET}"
    fi
}

# Table display
ui_table() {
    local header="$1"
    shift
    local rows=("$@")

    if $GUM_AVAILABLE && have gum; then
        {
            echo "$header"
            printf '%s\n' "${rows[@]}"
        } | gum table
    else
        # Simple column-based table
        echo "$header"
        printf '%s\n' "${rows[@]}" | column -t -s $'\t'
    fi
}

# ============================================================================
# PANELS AND LAYOUTS
# ============================================================================

# Split screen display (requires gum)
ui_join() {
    local orientation="${1:-horizontal}"  # horizontal or vertical
    shift
    local parts=("$@")

    if $GUM_AVAILABLE; then
        gum join --"$orientation" "${parts[@]}" || {
            # Fallback if gum join fails
            printf '%s\n' "${parts[@]}"
        }
    else
        # Fallback: just print sequentially
        printf '%s\n' "${parts[@]}"
    fi
}

# Format text with style
ui_style() {
    local text="$1"
    local color="${2:-}"
    local bold="${3:-false}"

    if $GUM_AVAILABLE; then
        local args=()
        [[ -n "$color" ]] && args+=(--foreground "$color")
        [[ "$bold" == "true" ]] && args+=(--bold)
        echo "$text" | gum style "${args[@]}"
    else
        local style=""
        case "$color" in
            red) style="$RED" ;;
            green) style="$GREEN" ;;
            yellow) style="$YELLOW" ;;
            blue) style="$BLUE" ;;
            magenta) style="$MAGENTA" ;;
            cyan) style="$CYAN" ;;
        esac
        [[ "$bold" == "true" ]] && style="${BOLD}${style}"
        echo "${style}${text}${RESET}"
    fi
}

# ============================================================================
# CONTEXT FILE SELECTION
# ============================================================================

# Select context files to load (multi-select)
ui_select_context_files() {
    local -a file_paths=("$@")

    if [[ ${#file_paths[@]} -eq 0 ]]; then
        echo "No context files available" >&2
        return 1
    fi

    # Format file paths for display (show relative paths if possible)
    local -a display_options=()
    local -a full_paths=()
    local workspace
    workspace="$(config_get workspace 2>/dev/null || pwd)"

    for file in "${file_paths[@]}"; do
        # Try to make path relative to workspace for cleaner display
        if [[ "$file" == "$workspace"* ]]; then
            local rel_path="${file#$workspace/}"
            display_options+=("📄 $rel_path")
        else
            display_options+=("📄 $file")
        fi
        full_paths+=("$file")
    done

    # Add option to select all
    display_options=("✅ Select All" "${display_options[@]}")

    local header
    header="Select context files to load (space to toggle, enter to confirm):"

    local -a selected_display
    if $GUM_AVAILABLE; then
        mapfile -t selected_display < <(printf '%s\n' "${display_options[@]}" | gum choose --no-limit --header "$header" --height 20)
    else
        # Fallback: simple multi-choice
        echo "$header" >&2
        echo "Enter numbers separated by spaces (e.g., 1 3 5), or 1 for all:" >&2
        local i=1
        for opt in "${display_options[@]}"; do
            echo "$i) $opt" >&2
            ((i++))
        done
        echo -n "> " >&2
        local choices
        if ! safe_read choices; then
            return 1
        fi
        for choice in $choices; do
            if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice > 0 && choice <= ${#display_options[@]})); then
                selected_display+=("${display_options[$((choice-1))]}")
            fi
        done
    fi

    # Check if user selected "Select All"
    local select_all=false
    for item in "${selected_display[@]}"; do
        if [[ "$item" == "✅ Select All" ]]; then
            select_all=true
            break
        fi
    done

    # Return selected file paths
    if [[ "$select_all" == "true" ]]; then
        printf '%s\n' "${full_paths[@]}"
    else
        # Map display selections back to full paths
        for item in "${selected_display[@]}"; do
            local i=0
            for opt in "${display_options[@]}"; do
                if [[ "$opt" == "$item" && "$opt" != "✅ Select All" ]]; then
                    # Subtract 1 because "Select All" is at index 0
                    echo "${full_paths[$((i-1))]}"
                    break
                fi
                ((i++))
            done
        done
    fi
}

# ============================================================================
# STATUS DISPLAY
# ============================================================================

# Show current session status
ui_show_status() {
    local workspace provider model task project

    workspace="$(config_get workspace)"
    provider="$(config_get model_provider)"
    model="$(config_get model_name)"
    task="$(config_get current_task)"
    project="$(config_get current_project)"

    local platform
    platform="$(get_platform)"

    # Get repo status if available
    local repo_status="none"
    if [[ "${AIWB_REPO_ENABLED:-false}" == "true" ]]; then
        repo_status="${AIWB_REPO_NAME:-unknown}"
        [[ -n "${AIWB_REPO_BRANCH:-}" ]] && repo_status="$repo_status (${AIWB_REPO_BRANCH})"
        # Check for uncommitted changes
        if have git && git rev-parse --git-dir >/dev/null 2>&1; then
            if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
                repo_status="$repo_status *"
            fi
        fi
    fi

    if $GUM_AVAILABLE; then
        local left right
        left=$(cat <<EOF
$(ui_style "AIWB Status" cyan true)

Platform:   $platform
Provider:   $provider
Model:      $model
Repository: $repo_status
EOF
)
        right=$(cat <<EOF



Project:    ${project:-none}
Task:       ${task:-inbox}
EOF
)
        # Ensure TTY is forced for Termux stability
gum join --horizontal "$left" "  " "$right" 2>/dev/null || {
    echo -e "$left"
    echo -e "$right"
}

    else
        echo "${CYAN}${BOLD}═══ AIWB Status ═══${RESET}"
        echo "Platform:   $platform"
        echo "Provider:   $provider"
        echo "Model:      $model"
        echo "Repository: $repo_status"
        echo "Project:    ${project:-none}"
        echo "Task:       ${task:-inbox}"
        echo ""
    fi
}

# ============================================================================
# EXPORTS
# ============================================================================

export AIWB_LIB_UI_LOADED=1
