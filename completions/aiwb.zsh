#compdef aiwb

_aiwb() {
    local -a commands

    commands=(
        'chat:Start interactive chat interface'
        'generate:Generate code/content for a task'
        'estimate:Estimate cost before generating'
        'verify:Verify/review generated content'
        'refine:Automated Generator-Verifier loop'
        'keys:Manage API keys'
        'settings:Configure AIWB'
        'status:Show current status'
        'history:Show session history'
        'costs:Show cost breakdown'
        'doctor:Check system health'
        'security-audit:Run security audit'
        'help:Show help message'
    )

    local -a providers
    providers=(
        'gemini:Google Gemini'
        'claude:Anthropic Claude'
        'openai:OpenAI GPT'
        'ollama:Local Ollama'
    )

    _arguments -C \
        '1: :->cmds' \
        '*::arg:->args' \
        '--provider[Specify provider]:provider:->providers' \
        '--model[Specify model]:model:' \
        '--debug[Enable debug output]' \
        '--version[Show version]' \
        '--help[Show help]'

    case "$state" in
        cmds)
            _describe -t commands 'aiwb commands' commands
            ;;
        providers)
            _describe -t providers 'providers' providers
            ;;
        args)
            case $line[1] in
                generate|estimate|verify|refine)
                    # Complete task names
                    if [[ -d "$HOME/.aiwb/workspace/tasks" ]]; then
                        local -a tasks
                        tasks=(${(f)"$(ls $HOME/.aiwb/workspace/tasks 2>/dev/null | sed 's/\.prompt\.md$//')"})
                        _describe -t tasks 'tasks' tasks
                    fi
                    ;;
            esac
            ;;
    esac
}

_aiwb "$@"
