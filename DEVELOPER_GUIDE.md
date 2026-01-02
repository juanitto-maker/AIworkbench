# AIWB Developer Guide

**Complete guide for contributing to AIWB - from setup to deployment**

---

## Table of Contents

1. [Development Environment Setup](#development-environment-setup)
2. [Development Workflows by Platform](#development-workflows-by-platform)
3. [Testing & Debugging](#testing--debugging)
4. [Adding a New AI Provider (Example: Qwen)](#adding-a-new-ai-provider)
5. [GitHub Workflow for Contributors](#github-workflow-for-contributors)
6. [Code Architecture Deep Dive](#code-architecture-deep-dive)
7. [Best Practices](#best-practices)
8. [Troubleshooting Development Issues](#troubleshooting-development-issues)

---

## Development Environment Setup

### Prerequisites

**Required Tools:**
```bash
# Core dependencies
bash (v4+)
jq
curl
git

# Development tools
shellcheck  # Bash linting
age         # For testing encryption
gum         # For testing UI
```

**Install Development Tools:**

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install bash curl jq git shellcheck

# macOS
brew install bash curl jq git shellcheck gum age

# Termux (Android)
pkg install bash curl jq git shellcheck gum age
```

### Fork and Clone

```bash
# 1. Fork the repository on GitHub
# Go to: https://github.com/juanitto-maker/AIworkbench
# Click "Fork" button

# 2. Clone your fork
git clone https://github.com/YOUR-USERNAME/AIworkbench.git
cd AIworkbench

# 3. Add upstream remote
git remote add upstream https://github.com/juanitto-maker/AIworkbench.git

# 4. Verify remotes
git remote -v
# Should show:
# origin    https://github.com/YOUR-USERNAME/AIworkbench.git (fetch)
# origin    https://github.com/YOUR-USERNAME/AIworkbench.git (push)
# upstream  https://github.com/juanitto-maker/AIworkbench.git (fetch)
# upstream  https://github.com/juanitto-maker/AIworkbench.git (push)
```

### Development Workspace Setup

```bash
# Run AIWB directly from repo (no installation needed)
./aiwb

# Or install to ~/.local/bin for system-wide testing
./install.sh

# Create test workspace (separate from your main workspace)
export AIWB_WORKSPACE="$HOME/.aiwb-dev"
./aiwb
```

---

## Development Workflows by Platform

### 1. Claude Code (Anthropic's CLI) - Recommended! 🎯

Claude Code provides AI-powered assistance directly in your terminal.

**Setup:**
```bash
# Already using Claude Code if you're reading this!

# Best practices for AIWB development with Claude Code:
# 1. Work in feature branches
# 2. Use Claude to understand code architecture
# 3. Ask Claude to generate tests
# 4. Request code reviews before committing
```

**Typical Workflow:**

```bash
# Start development
git checkout -b feature/add-qwen-provider

# Ask Claude for help
> "Explain the structure of lib/api.sh and how providers are implemented"
> "Help me add a new provider for Qwen AI. Walk me through the steps."
> "Review my changes for security issues"

# Test your changes
./test_aiwb_comprehensive.sh

# Commit with Claude's help
> "Generate a good commit message for my changes"
```

**Claude Code Tips:**
- ✅ Use natural language to explore codebase
- ✅ Ask for explanations of complex bash patterns
- ✅ Request security reviews
- ✅ Generate test cases
- ✅ Get help with git operations

### 2. VS Code with Extensions

**Recommended Extensions:**
- Bash IDE
- ShellCheck
- GitLens
- GitHub Copilot (optional)
- Better Comments

**Setup:**

```json
// .vscode/settings.json
{
  "shellcheck.enable": true,
  "shellcheck.run": "onType",
  "files.associations": {
    "*.sh": "shellscript",
    "aiwb": "shellscript"
  },
  "editor.formatOnSave": false,
  "editor.tabSize": 4,
  "editor.insertSpaces": true
}
```

**Recommended Tasks:**

```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Run AIWB",
      "type": "shell",
      "command": "./aiwb",
      "problemMatcher": []
    },
    {
      "label": "Run Tests",
      "type": "shell",
      "command": "./test_aiwb_comprehensive.sh",
      "problemMatcher": []
    },
    {
      "label": "ShellCheck All",
      "type": "shell",
      "command": "shellcheck aiwb lib/*.sh",
      "problemMatcher": []
    }
  ]
}
```

**Workflow:**

1. Open folder in VS Code
2. Install recommended extensions
3. Use integrated terminal for testing
4. Use ShellCheck for linting
5. Use GitLens for git operations

### 3. Cursor (AI-First IDE)

Cursor is like VS Code with built-in AI assistance.

**Best Practices:**

```bash
# Ask Cursor AI to:
# - Explain functions
# - Generate documentation
# - Write tests
# - Find bugs
# - Suggest improvements

# Example prompts:
"Explain how the api_call_gemini function works"
"Generate unit tests for the config.sh module"
"Review this code for shell injection vulnerabilities"
```

**Shortcuts:**
- `Cmd/Ctrl + K` - Ask AI about code
- `Cmd/Ctrl + L` - Chat with AI
- `Cmd/Ctrl + I` - Inline code generation

### 4. Pure CLI Development

For terminal purists:

```bash
# 1. Use vim/nano/emacs for editing
vim lib/api.sh

# 2. Run shellcheck manually
shellcheck lib/api.sh

# 3. Test immediately
./aiwb --debug

# 4. Use watch for continuous testing
watch -n 2 './aiwb doctor'

# 5. Git operations
git status
git add -p  # Interactive staging
git commit -m "feat: add new feature"
```

**Recommended CLI Tools:**
- `fzf` - Fuzzy file finder
- `ripgrep` (rg) - Fast search
- `tmux` - Terminal multiplexer
- `watch` - Monitor command output

---

## Testing & Debugging

### Available Test Commands

#### 1. Health Check
```bash
# Quick system diagnostic
./debug_aiwb.sh

# What it checks:
# - Dependencies installed
# - Workspace integrity
# - Config validity
# - API keys present
```

#### 2. Basic Functionality Tests
```bash
# Fast smoke test (30 seconds)
./test_aiwb_functionality.sh

# Tests:
# - Workspace creation
# - Config management
# - Basic API connectivity
# - Simple chat interaction
```

#### 3. Comprehensive Tests
```bash
# Full test suite (5-10 minutes)
./test_aiwb_comprehensive.sh

# Tests all:
# - Chat mode
# - Quick mode
# - Make mode
# - Plan mode
# - Settings menu
# - Error handling
# - Output quality (AI-powered validation)
```

### Debug Mode

Enable detailed logging:

```bash
# Method 1: Environment variable
export AIWB_DEBUG=1
./aiwb

# Method 2: Command flag
./aiwb --debug

# Method 3: In code (temporary)
# Add to top of script:
set -x  # Enable bash debug mode
```

**Debug Output Shows:**
- Function calls
- Variable values
- API requests/responses
- File operations
- Error stack traces

### Testing Your Changes

**Before Every Commit:**

```bash
# 1. Lint your code
shellcheck aiwb lib/*.sh

# 2. Run basic tests
./test_aiwb_functionality.sh

# 3. Test specific feature manually
./aiwb --debug
# Try your new feature

# 4. For major changes, run full suite
./test_aiwb_comprehensive.sh
```

**Test Checklist:**

- [ ] ShellCheck passes (warnings OK if documented)
- [ ] Manual testing in interactive mode
- [ ] Test on your target platform (Linux/macOS/Termux)
- [ ] Test with and without `gum` installed
- [ ] Test with API keys for affected providers
- [ ] No hardcoded paths
- [ ] Error messages are clear

### Manual Testing Workflow

```bash
# 1. Start in debug mode
./aiwb --debug

# 2. Test your feature
> /make
make> prompt Test my new feature
make> run

# 3. Check logs
tail -f ~/.aiwb/workspace/logs/chat_*.log

# 4. Verify cost tracking
cat ~/.aiwb/workspace/logs/usage.jsonl | jq .

# 5. Check for errors
grep -i error ~/.aiwb/workspace/logs/*.log
```

---

## Adding a New AI Provider

### Complete Example: Adding Qwen AI Support

Let's walk through adding Alibaba's Qwen AI as a new provider.

#### Step 1: Research the API

```bash
# Gather information:
# 1. API endpoint URL
# 2. Authentication method (API key, token, etc.)
# 3. Request format (JSON structure)
# 4. Response format
# 5. Pricing/rate limits
# 6. Available models

# Example for Qwen:
# Endpoint: https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation
# Auth: API key in X-DashScope-API-Key header
# Models: qwen-turbo, qwen-plus, qwen-max
```

#### Step 2: Add API Key Support

**File:** `lib/security.sh`

```bash
# Find the section with API key environment variables
# Add Qwen after existing providers:

# Around line 30-50, add:
export QWEN_API_KEY="${QWEN_API_KEY:-}"

# In the function that lists keys, add:
list_api_keys() {
    # ... existing code ...

    # Add Qwen
    if [[ -n "$QWEN_API_KEY" ]]; then
        echo "✓ Qwen API key configured"
    else
        echo "✗ Qwen API key not set"
    fi
}
```

#### Step 3: Implement API Call Function

**File:** `lib/api.sh`

```bash
# Add after other provider functions (around line 800+)

# Qwen AI API integration
api_call_qwen() {
    local model="$1"
    local prompt="$2"
    local max_tokens="${3:-2000}"

    # Check API key
    if [[ -z "$QWEN_API_KEY" ]]; then
        err "QWEN_API_KEY not set"
        return "$E_CONFIG"
    fi

    # Build request
    local request_json
    request_json=$(jq -n \
        --arg model "$model" \
        --arg prompt "$prompt" \
        --argjson max_tokens "$max_tokens" \
        '{
            model: $model,
            input: {
                messages: [
                    {
                        role: "user",
                        content: $prompt
                    }
                ]
            },
            parameters: {
                max_tokens: $max_tokens,
                temperature: 0.7
            }
        }')

    # Make API call
    local response
    response=$(curl -s \
        --max-time 300 \
        --connect-timeout 10 \
        -X POST \
        "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation" \
        -H "Content-Type: application/json" \
        -H "X-DashScope-API-Key: $QWEN_API_KEY" \
        -d "$request_json")

    # Check for errors
    if echo "$response" | jq -e '.code != null' >/dev/null 2>&1; then
        local error_msg
        error_msg=$(echo "$response" | jq -r '.message // "Unknown error"')
        err "Qwen API error: $error_msg"
        return "$E_API"
    fi

    # Extract response text
    local output
    output=$(echo "$response" | jq -r '.output.text // .output.choices[0].message.content // empty')

    if [[ -z "$output" ]]; then
        err "Empty response from Qwen API"
        return "$E_API"
    fi

    echo "$output"
    return 0
}

# Add cost calculation function
calculate_cost_qwen() {
    local model="$1"
    local input_tokens="$2"
    local output_tokens="$3"

    # Qwen pricing (example - check actual pricing)
    case "$model" in
        qwen-turbo)
            # $0.002 per 1K tokens (input + output)
            local cost=$(awk "BEGIN {print (($input_tokens + $output_tokens) / 1000) * 0.002}")
            ;;
        qwen-plus)
            # $0.008 per 1K tokens
            local cost=$(awk "BEGIN {print (($input_tokens + $output_tokens) / 1000) * 0.008}")
            ;;
        qwen-max)
            # $0.02 per 1K tokens
            local cost=$(awk "BEGIN {print (($input_tokens + $output_tokens) / 1000) * 0.02}")
            ;;
        *)
            local cost="0.00"
            ;;
    esac

    echo "$cost"
}
```

#### Step 4: Add to Configuration

**File:** `lib/config.sh`

```bash
# Find init_config() function (around line 50)
# Add default Qwen model:

init_config() {
    # ... existing code ...

    # Add Qwen default model
    config_set "qwen_model" "qwen-turbo"

    # ... rest of function ...
}

# In provider selection menu, add Qwen option:
select_provider() {
    local providers=("gemini" "claude" "openai" "groq" "xai" "qwen" "ollama")

    # ... rest of function ...
}
```

#### Step 5: Add Model Selection

**File:** `lib/ui.sh` or `lib/modes.sh`

```bash
# In model selection function, add Qwen models:

select_model_for_provider() {
    local provider="$1"

    case "$provider" in
        # ... existing providers ...

        qwen)
            local models=(
                "qwen-turbo:Fast and economical"
                "qwen-plus:Balanced performance"
                "qwen-max:Best quality"
            )
            ui_select "Choose Qwen model:" "${models[@]}"
            ;;

        # ... rest of function ...
    esac
}
```

#### Step 6: Update Main Dispatcher

**File:** `aiwb` or `lib/api.sh`

```bash
# Find the main API dispatch function
# Add Qwen case:

call_ai() {
    local provider="$1"
    local model="$2"
    local prompt="$3"

    case "$provider" in
        gemini)   api_call_gemini "$model" "$prompt" ;;
        claude)   api_call_claude "$model" "$prompt" ;;
        openai)   api_call_openai "$model" "$prompt" ;;
        groq)     api_call_groq "$model" "$prompt" ;;
        xai)      api_call_xai "$model" "$prompt" ;;
        qwen)     api_call_qwen "$model" "$prompt" ;;  # ADD THIS
        ollama)   api_call_ollama "$model" "$prompt" ;;
        *)
            err "Unknown provider: $provider"
            return "$E_CONFIG"
            ;;
    esac
}
```

#### Step 7: Add Documentation

Update these files:

**README.md:**
```markdown
| **Qwen** | qwen-turbo, qwen-plus, qwen-max | ✅ Yes | Fast Chinese & multilingual |
```

**QUICKSTART.md:**
```markdown
- **Qwen**: https://dashscope.console.aliyun.com/ (Free tier available!)
```

**docs/USAGE.md:**
Add Qwen to provider table and examples.

#### Step 8: Test Your Implementation

```bash
# 1. Set API key
export QWEN_API_KEY="your-test-key"

# 2. Test basic call
./aiwb --provider qwen --model qwen-turbo chat

# 3. Try in interactive mode
./aiwb
> /models
# Select Qwen as provider
> Hello, can you hear me?

# 4. Test all modes
> /make
make> prompt Create a hello world script
make> model  # Select Qwen
make> run

# 5. Test cost tracking
./aiwb costs

# 6. Run test suite
./test_aiwb_comprehensive.sh
```

#### Step 9: Create Pull Request

```bash
# 1. Commit your changes
git add lib/api.sh lib/config.sh lib/security.sh lib/ui.sh
git add README.md QUICKSTART.md docs/USAGE.md
git commit -m "feat: add Qwen AI provider support

- Implement api_call_qwen() function
- Add qwen-turbo, qwen-plus, qwen-max models
- Add cost calculation for Qwen
- Update documentation
- Add to provider selection menus

Tested on Linux with Qwen API key."

# 2. Push to your fork
git push origin feature/add-qwen-provider

# 3. Create PR on GitHub (see next section)
```

---

## GitHub Workflow for Contributors

### Understanding GitHub Basics

#### What is GitHub?

GitHub is a platform for:
- **Version Control**: Track changes to code over time
- **Collaboration**: Multiple developers work together
- **Code Review**: Review changes before merging
- **Issue Tracking**: Report bugs and request features

#### Key Concepts

**Repository (Repo):**
- A project folder containing all code and history
- Like a shared folder everyone can access

**Fork:**
- Your personal copy of someone else's repo
- You can make changes without affecting the original

**Branch:**
- A parallel version of the code
- Like a separate workspace for your changes

**Pull Request (PR):**
- A request to merge your changes into the main project
- Allows review and discussion

**Commit:**
- A saved set of changes with a description
- Like a checkpoint in your work

### Complete GitHub Workflow

#### 1. Fork the Repository

```
1. Go to: https://github.com/juanitto-maker/AIworkbench
2. Click "Fork" button (top right)
3. Select your account
4. Wait for fork to complete
5. You now have: https://github.com/YOUR-USERNAME/AIworkbench
```

#### 2. Clone Your Fork

```bash
# Clone to your computer
git clone https://github.com/YOUR-USERNAME/AIworkbench.git
cd AIworkbench

# Add upstream (original repo) as remote
git remote add upstream https://github.com/juanitto-maker/AIworkbench.git
```

#### 3. Keep Your Fork Updated

```bash
# Fetch latest changes from original repo
git fetch upstream

# Switch to your main branch
git checkout main

# Merge upstream changes
git merge upstream/main

# Push to your fork
git push origin main
```

#### 4. Create a Feature Branch

```bash
# Always create a new branch for changes
git checkout -b feature/my-new-feature

# Branch naming conventions:
# - feature/add-qwen-provider
# - fix/api-timeout-bug
# - docs/update-readme
# - refactor/improve-error-handling
```

#### 5. Make Your Changes

```bash
# Edit files
vim lib/api.sh

# Check what changed
git status
git diff

# Stage changes
git add lib/api.sh

# Or stage all changes
git add -A

# Check staged changes
git diff --cached
```

#### 6. Commit Your Changes

```bash
# Commit with good message
git commit -m "feat: add Qwen AI provider

- Implement api_call_qwen() function
- Add qwen-turbo, qwen-plus, qwen-max models
- Add cost calculation
- Update documentation

Closes #123"

# Commit message format:
# <type>: <short description>
#
# <detailed description>
#
# <footer>

# Types:
# - feat: New feature
# - fix: Bug fix
# - docs: Documentation only
# - style: Formatting changes
# - refactor: Code restructuring
# - test: Adding tests
# - chore: Maintenance
```

#### 7. Push to Your Fork

```bash
# Push your branch
git push origin feature/my-new-feature

# If branch doesn't exist on remote yet:
git push -u origin feature/my-new-feature
```

#### 8. Create a Pull Request

**On GitHub:**

1. Go to your fork: `https://github.com/YOUR-USERNAME/AIworkbench`
2. Click "Pull requests" tab
3. Click "New pull request"
4. Click "compare across forks"
5. Set base repository: `juanitto-maker/AIworkbench` base: `main`
6. Set head repository: `YOUR-USERNAME/AIworkbench` compare: `feature/my-new-feature`
7. Click "Create pull request"
8. Fill in the template:

```markdown
## Description
Add support for Qwen AI provider from Alibaba Cloud.

## Type of Change
- [x] New feature
- [ ] Bug fix
- [ ] Documentation update

## Changes Made
- Implemented `api_call_qwen()` in lib/api.sh
- Added qwen-turbo, qwen-plus, qwen-max models
- Added cost calculation for Qwen
- Updated README.md, QUICKSTART.md, and docs/USAGE.md
- Added Qwen to provider selection menus

## Testing
- [x] Tested on Linux with Qwen API key
- [x] All modes work (chat, make, quick)
- [x] Cost tracking works
- [x] ShellCheck passes
- [ ] Tested on macOS (don't have access)
- [ ] Tested on Termux (don't have access)

## Screenshots
(Add if relevant)

## Additional Notes
Pricing information taken from Qwen documentation as of Nov 2025.
May need update if pricing changes.
```

9. Click "Create pull request"

#### 9. Respond to Review Comments

Maintainers will review your code and may request changes:

```bash
# Make requested changes
vim lib/api.sh

# Commit changes
git add lib/api.sh
git commit -m "fix: address review comments

- Add better error handling
- Fix shellcheck warning
- Update pricing calculation"

# Push to same branch
git push origin feature/my-new-feature

# PR will automatically update!
```

#### 10. After PR is Merged

```bash
# Switch back to main
git checkout main

# Update from upstream
git fetch upstream
git merge upstream/main

# Delete feature branch
git branch -d feature/my-new-feature
git push origin --delete feature/my-new-feature

# Celebrate! 🎉
```

### Useful GitHub Features

#### Issues

**Creating an Issue:**

1. Go to: https://github.com/juanitto-maker/AIworkbench/issues
2. Click "New issue"
3. Choose template (Bug Report, Feature Request)
4. Fill in details
5. Submit

**Example Bug Report:**
```markdown
**Describe the bug**
API call fails when using Qwen provider

**To Reproduce**
1. Set QWEN_API_KEY
2. Run `./aiwb --provider qwen chat`
3. Send message
4. See error

**Expected behavior**
Should get response from Qwen AI

**Environment**
- OS: Ubuntu 22.04
- Shell: bash 5.1.16
- AIWB version: v2.0.1

**Additional context**
Error message: "jq: parse error"
```

#### Discussions

For questions and general chat:
https://github.com/juanitto-maker/AIworkbench/discussions

#### Projects

Track progress on features:
https://github.com/juanitto-maker/AIworkbench/projects

#### Actions

View CI/CD pipeline status:
https://github.com/juanitto-maker/AIworkbench/actions

#### Wiki

Documentation wiki:
https://github.com/juanitto-maker/AIworkbench/wiki

---

## Code Architecture Deep Dive

### File Structure

```
AIworkbench/
├── aiwb                      # Main entry point
│   ├── Interrupt handling    # Lines 10-44
│   ├── Bootstrap            # Lines 46-64
│   ├── Initialization       # Lines 66-143
│   ├── Commands             # Lines 145-1800
│   └── Main dispatch        # Lines 1802-1886
│
├── lib/
│   ├── common.sh            # Platform & utilities
│   │   ├── Platform detection (is_termux, is_macos)
│   │   ├── Safe input reading
│   │   ├── Clipboard operations
│   │   └── Logging utilities
│   │
│   ├── config.sh            # Configuration management
│   │   ├── Workspace init
│   │   ├── Config get/set
│   │   ├── Session management
│   │   └── Model defaults
│   │
│   ├── ui.sh                # User interface
│   │   ├── gum wrappers (with fallbacks)
│   │   ├── Input functions
│   │   ├── Selection menus
│   │   ├── Status displays
│   │   └── Formatting
│   │
│   ├── api.sh               # AI provider integrations
│   │   ├── api_call_gemini()
│   │   ├── api_call_claude()
│   │   ├── api_call_openai()
│   │   ├── api_call_groq()
│   │   ├── api_call_xai()
│   │   ├── api_call_ollama()
│   │   └── Cost calculations
│   │
│   ├── modes.sh             # Mode-based workflows
│   │   ├── mode_loop()
│   │   ├── /make mode
│   │   ├── /tweak mode
│   │   ├── /debug mode
│   │   └── Mode commands
│   │
│   ├── error.sh             # Error handling
│   │   ├── Error codes
│   │   ├── Error messages
│   │   └── Stack traces
│   │
│   └── security.sh          # Key encryption
│       ├── Key loading
│       ├── Age encryption
│       └── Key management
│
├── templates/               # Prompt templates
├── completions/            # Shell completions
├── docs/                   # Documentation
├── examples/               # Usage examples
└── tests/                  # Test scripts
```

### Key Design Patterns

#### 1. Error Handling Pattern

```bash
# All functions return exit codes
function do_something() {
    local input="$1"

    # Validate input
    [[ -z "$input" ]] && {
        err "Input required"
        return "$E_PARAM"
    }

    # Do work
    local result
    result=$(some_command "$input") || {
        err "Command failed"
        return "$E_EXEC"
    }

    # Return success
    echo "$result"
    return 0
}

# Caller checks return code
if do_something "value"; then
    info "Success"
else
    err "Failed with code: $?"
fi
```

#### 2. Platform Detection Pattern

```bash
# Check platform once, use everywhere
if is_termux; then
    # Termux-specific code
    STORAGE_PATH="/storage/emulated/0"
elif is_macos; then
    # macOS-specific code
    CLIPBOARD_CMD="pbcopy"
else
    # Linux code
    CLIPBOARD_CMD="xclip"
fi
```

#### 3. Fallback UI Pattern

```bash
# Try gum first, fallback to basic
if $GUM_AVAILABLE; then
    input=$(gum input --placeholder "Enter value")
else
    printf "Enter value: "
    read -r input
fi
```

#### 4. Configuration Pattern

```bash
# Always use config get/set
model=$(config_get "model_name")
config_set "model_name" "new-model"

# Never directly manipulate config.json
```

---

## Best Practices

### Code Style

```bash
# Use functions for everything
function my_function() {
    local param="$1"
    echo "Result"
}

# Always declare variables as local
function example() {
    local var1="value"
    local var2
    var2=$(command)
}

# Quote all variables
echo "$var"
command "$file"
[[ -f "$path" ]]

# Use [[ ]] over [ ]
[[ -f "$file" ]]  # Good
[ -f "$file" ]    # Old style

# Use $() over backticks
result=$(command)  # Good
result=`command`   # Old style

# Check exit codes
if command; then
    echo "Success"
fi

# Or explicitly
command
if [[ $? -eq 0 ]]; then
    echo "Success"
fi
```

### Security

```bash
# Never execute user input directly
eval "$user_input"  # DANGEROUS!

# Sanitize all inputs
function sanitize() {
    local input="$1"
    # Remove dangerous characters
    input="${input//[^a-zA-Z0-9_-]/}"
    echo "$input"
}

# Use temporary files securely
tmpfile=$(mktemp) || exit 1
trap 'rm -f "$tmpfile"' EXIT

# Set secure permissions
chmod 600 "$sensitive_file"
```

### Performance

```bash
# Avoid subshells when possible
while IFS= read -r line; do
    # Process line
done < file

# Instead of:
cat file | while read line; do
    # Subshell! Variables don't persist
done

# Use built-ins over external commands
# Good:
[[ -f "$file" ]]

# Slower:
test -f "$file"
```

---

## Troubleshooting Development Issues

### Common Problems

#### 1. "Permission denied" when running script

```bash
# Solution: Make executable
chmod +x aiwb
chmod +x lib/*.sh
```

#### 2. "Command not found: gum"

```bash
# This is OK! AIWB has fallbacks
# To install gum:
# Ubuntu/Debian - see QUICKSTART.md
# macOS: brew install gum
# Termux: pkg install gum
```

#### 3. ShellCheck warnings

```bash
# Some warnings are OK and can be disabled:

# SC2155: Declare and assign separately
# shellcheck disable=SC2155
local result=$(command)

# SC2086: Quote to prevent word splitting
# Sometimes we want word splitting
# shellcheck disable=SC2086
command $unquoted_var
```

#### 4. "jq: parse error"

```bash
# Usually bad JSON from API
# Debug with:
echo "$json" | jq .

# Or save to file:
echo "$json" > /tmp/debug.json
jq . /tmp/debug.json
```

#### 5. Changes not taking effect

```bash
# If you installed AIWB, reinstall:
./install.sh

# Or run from repo directly:
./aiwb

# Check which aiwb is running:
which aiwb
type aiwb
```

### Getting Help

**Resources:**
- GitHub Issues: https://github.com/juanitto-maker/AIworkbench/issues
- Discussions: https://github.com/juanitto-maker/AIworkbench/discussions
- Documentation: [docs/](docs/)
- This guide!

**Before asking for help:**
1. Search existing issues
2. Check documentation
3. Run `./debug_aiwb.sh`
4. Enable debug mode: `./aiwb --debug`
5. Check logs: `~/.aiwb/workspace/logs/`

**When asking for help, include:**
- OS and shell version
- AIWB version
- Steps to reproduce
- Error messages
- Relevant logs
- What you've tried

---

## Conclusion

You now have everything you need to contribute to AIWB!

**Quick Start Checklist:**
- [ ] Fork and clone repository
- [ ] Set up development environment
- [ ] Run tests to verify setup
- [ ] Choose an issue to work on (or create one)
- [ ] Create feature branch
- [ ] Make changes
- [ ] Test thoroughly
- [ ] Create pull request
- [ ] Respond to review
- [ ] Celebrate when merged! 🎉

**Remember:**
- Start small (fix typos, improve docs)
- Ask questions (use Discussions)
- Be patient with reviews
- Follow the code style
- Write tests
- Have fun!

Welcome to the AIWB community! 🚀
