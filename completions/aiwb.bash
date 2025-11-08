#!/usr/bin/env bash
# Bash completion for aiwb

_aiwb() {
    local cur prev opts commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Main commands
    commands="chat generate estimate verify refine keys settings status history costs doctor security-audit help"

    # Global options
    opts="--provider --model --debug --version --help"

    # Complete based on context
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "${commands} ${opts}" -- ${cur}) )
        return 0
    fi

    # Complete based on previous word
    case "${prev}" in
        --provider)
            COMPREPLY=( $(compgen -W "gemini claude openai ollama" -- ${cur}) )
            return 0
            ;;
        --model)
            # Could query available models dynamically
            COMPREPLY=( $(compgen -W "flash-1.5 flash-2.0 pro-1.5 sonnet-3.5 haiku-3.5 gpt-4o-mini" -- ${cur}) )
            return 0
            ;;
        generate|estimate|verify|refine)
            # Complete task names from workspace
            if [[ -d "$HOME/.aiwb/workspace/tasks" ]]; then
                local tasks=$(ls "$HOME/.aiwb/workspace/tasks" 2>/dev/null | sed 's/\.prompt\.md$//' | tr '\n' ' ')
                COMPREPLY=( $(compgen -W "${tasks}" -- ${cur}) )
            fi
            return 0
            ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _aiwb aiwb
