#!/usr/bin/env bash
# ui.sh - Beautiful TUI components for AIWB

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

    if $GUM_AVAILABLE; then
        gum input --placeholder "$placeholder" ${default:+--value "$default"}
    else
        local result
        if [[ -n "$default" ]]; then
            read -rp "$prompt [$default]: " result || return 1
            echo "${result:-$default}"
        else
            read -rp "$prompt: " result || return 1
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
        read -rsp "$prompt: " result || return 1
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
        read -r choice || return 1
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
        read -r choices || return 1
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
            read -r pattern || return 1
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

    if $GUM_AVAILABLE; then
        local left right
        left=$(cat <<EOF
$(ui_style "AIWB Status" cyan true)

Platform:   $platform
Workspace:  ${workspace/#$HOME/\~}
Provider:   $provider
Model:      $model
EOF
)
        right=$(cat <<EOF


Project:    ${project:-none}
Task:       ${task:-inbox}

EOF
)
        gum join --horizontal "$left" "  " "$right" || {
            # Fallback if gum join fails
            echo "$left"
            echo "$right"
        }
    else
        echo "${CYAN}${BOLD}═══ AIWB Status ═══${RESET}"
        echo "Platform:  $platform"
        echo "Workspace: ${workspace/#$HOME/\~}"
        echo "Provider:  $provider"
        echo "Model:     $model"
        echo "Project:   ${project:-none}"
        echo "Task:      ${task:-inbox}"
        echo ""
    fi
}

# ============================================================================
# EXPORTS
# ============================================================================

export AIWB_LIB_UI_LOADED=1
