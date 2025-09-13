#!/usr/bin/env bash
# AIWB (AI Workbench) - The Conversational AI Development Environment
#
# This is the main entry point for the AIWB application.
# - Running 'aiwb' with no arguments launches the interactive TUI.
# - Running 'aiwb <command> [args...]' will bypass the TUI for scripting (power users).

set -euo pipefail

# ---- Core Configuration & Helpers ----

# Source the common paths and environment variables
# Note: We need a reliable way to find 'paths.sh'. We'll refine this.
if [ -f "$HOME/bin/paths.sh" ]; then
    source "$HOME/bin/paths.sh"
else
    echo "Error: paths.sh not found. Please ensure it's in your PATH." >&2
    exit 1
fi

# Check for Gum, our TUI helper
if ! command -v gum >/dev/null 2>&1; then
    echo "Warning: 'gum' is not installed. The TUI will have a basic fallback." >&2
    echo "For the best experience, please install it: pkg install gum" >&2
fi

# ---- TUI Orchestrator (The "Brain") ----

function orchestrator_main_loop() {
    # Clear the screen and show the welcome message
    clear
    gum style --border normal --margin "1" --padding "1 2" \
        "Welcome to AIWB! 🤖" \
        "Your AI development partner. Start by describing your goal."

    # This is the main conversational loop
    while true; do
        # Get user input using Gum's input prompt
        USER_INPUT=$(gum input --placeholder "What would you like to do?")

        # Exit condition
        if [[ "$USER_INPUT" == "exit" || "$USER_INPUT" == "quit" ]]; then
            break
        fi

        # --- Intent Recognition & Tool Selection (Placeholder Logic) ---
        # This is where the "brain" will go. For now, we'll just echo the input.
        
        # TODO: Implement intent recognition (e.g., is it a new project, a debug request, etc.?)
        # TODO: Implement tool selection (e.g., call gpre.sh, a runner, etc.)
        
        # Simulate an AI response
        gum style --foreground 212 "Processing your request: '$USER_INPUT'..."
        sleep 1 # Simulate work
        echo "AIWB Response: Feature for '$USER_INPUT' is not yet implemented."

    done

    gum style --bold "Session ended. Goodbye!"
}

# ---- CLI Handler (For Power Users) ----

function cli_handler() {
    COMMAND="$1"
    shift # The rest of the arguments are for the command
    
    echo "Power User Mode: CLI handler"
    echo "Command: $COMMAND"
    echo "Arguments: $@"
    
    # TODO: Implement a case statement to route to the correct backend script
    # e.g., case "$COMMAND" in
    #          "context") aiwb-context.sh "$@" ;;
    #          "run") aiwb-run.sh "$@" ;;
    #          *) echo "Unknown command: $COMMAND" ;;
    #      esac
}

# ---- Main Entry Point Logic ----

# If the user provides any arguments (e.g., 'aiwb context set .'),
# we call the CLI handler. Otherwise, we launch the TUI.
if [ "$#" -gt 0 ]; then
    cli_handler "$@"
else
    orchestrator_main_loop
fi
