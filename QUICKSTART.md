# AIWB Quick Start Guide

Get up and running with AIWB in 5 minutes!

## What is AIWB?

AIWB (AI Workbench) is a powerful command-line AI orchestration platform that uses a **Generator-Verifier loop** - where one AI model generates code and another verifies it, creating higher-quality outputs through AI collaboration.

## Installation

### Prerequisites

**Required:**
- `bash` (v4+)
- `curl`
- `jq`

**Optional (recommended):**
- `gum` (beautiful TUI - fallback available if not installed)
- `git`
- `fzf`

### Install Dependencies

**Termux (Android):**
```bash
pkg update && pkg install bash curl jq git gum
termux-setup-storage  # Grant storage access
```

**Ubuntu/Debian:**
```bash
sudo apt update && sudo apt install bash curl jq git
# Optional: Install gum
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo tee /etc/apt/keyrings/charm.gpg >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum
```

**macOS:**
```bash
brew install bash curl jq git gum
```

### Install AIWB

**One-Line Install (Recommended):**
```bash
curl -fsSL https://raw.githubusercontent.com/juanitto-maker/AIworkbench/main/install.sh | bash
```

**Manual Install:**
```bash
git clone https://github.com/juanitto-maker/AIworkbench.git
cd AIworkbench
./install.sh
```

**Add to PATH:**
```bash
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## First Run

### 1. Start AIWB

```bash
aiwb
```

On first run, AIWB will initialize the workspace at `~/.aiwb/`.

### 2. Set Up API Keys

Configure your API keys using the interactive menu:

```bash
# From within aiwb interactive mode
> /keys

# Or from command line
aiwb keys
```

**Get Your API Keys:**
- **Gemini**: https://aistudio.google.com/app/apikey (Free tier available!)
- **Claude**: https://console.anthropic.com/ (Requires payment)
- **OpenAI**: https://platform.openai.com/api-keys (Requires payment)
- **Groq**: https://console.groq.com/ (Free tier available!)
- **xAI/Grok**: https://console.x.ai/ (Beta access)

**Security Note:** Keys are stored in `~/.aiwb/.aiwb.env` (plaintext) or can be encrypted with `age` for enhanced security.

### 3. Choose Your AI Provider

```bash
# From within aiwb
> /settings

# Select your preferred provider and model
```

**Available Providers:**
- **Gemini**: Google's models (gemini-2.5-flash, gemini-2.0-flash-lite)
- **Claude**: Anthropic's models (claude-3.5-sonnet, claude-3.5-haiku)
- **OpenAI**: GPT models (gpt-4o, gpt-3.5-turbo)
- **Groq**: Fast inference (llama-3.3-70b, mixtral-8x7b)
- **xAI**: Grok models (grok-beta, grok-2)
- **Ollama**: Local models (any model installed locally)

### 4. Start Using AIWB!

Just type naturally or use commands:

```
> Write a Python function to calculate fibonacci numbers
> /help
> /wizard
```

## Essential Commands

### Starting AIWB
```bash
aiwb              # Start interactive mode (default)
aiwb chat         # Start chat mode explicitly
aiwb wizard       # Guided beginner-friendly workflow
aiwb doctor       # Check system health and configuration
```

### Mode-Based Workflows (Powerful!)
```bash
# Inside aiwb interactive mode, enter a mode:
> /make           # Generate code from scratch
> /tweak          # Modify existing code
> /debug          # Find and fix bugs

# Inside a mode, use these commands:
prompt <text>           # Set instructions as text
instruct <file.md>      # Load instructions from file
model                   # Choose AI model interactively
uploads <files/dirs>    # Add context (files/directories)
check [instructions]    # Configure verification AI
status                  # Show current mode status
run                     # Execute (shows cost estimate first)
exit                    # Leave mode
```

### Quick Commands
```bash
aiwb quick "Create a password generator in Python"
aiwb wizard                      # Interactive guided workflow
```

### Configuration
```bash
aiwb keys         # Manage API keys (add/list/encrypt)
aiwb settings     # Configure provider and model preferences
aiwb status       # Show current configuration and context
```

### Slash Commands (in interactive chat)
```
/help             # Show all available commands
/make             # Enter make mode
/tweak            # Enter tweak mode
/debug            # Enter debug mode
/quick <desc>     # One-shot generation with auto-verify
/wizard           # Start wizard workflow
/improve <note>   # Improve the last output
/keys             # Manage API keys
/settings         # Change provider/model settings
/status           # Show status overview
/context          # Manage context files
/costs            # Show spending breakdown
/history          # View session history
/templates        # Browse available templates
/clear            # Clear screen
/exit             # Quit (with confirmation)
```

## Your First Real Task

Let's create a REST API using AIWB's powerful mode-based workflow:

### Example 1: Using /make Mode

```bash
# Start AIWB
aiwb

# Enter make mode
> /make

# Set your instructions
make> prompt Create a REST API for user management with Express.js. Include GET /api/users and POST /api/users with validation and error handling.

# Choose your AI model
make> model
# (Select Claude 3.5 Sonnet or Gemini 2.5 Flash from the menu)

# Add context files if you have existing code
make> uploads ./package.json ./src/models/

# Configure verification (optional but recommended!)
make> check Focus on security, error handling, and code quality

# Check what we've configured
make> status

# Execute (will show cost estimate and ask for confirmation)
make> run
```

The AI will generate your code, then a second AI will verify it, providing feedback!

### Example 2: Using Quick Command

For simpler tasks, use the quick command:

```bash
aiwb quick "Create a Python password generator with strength checker"
```

This automatically generates and verifies in one shot!

### Example 3: Using Wizard (Beginner-Friendly)

```bash
aiwb wizard
```

The wizard will guide you through:
1. Choosing what to create
2. Selecting AI provider
3. Providing instructions
4. Adding context files
5. Configuring verification
6. Executing with cost preview

## Workspace Structure

After first run, AIWB creates this structure:

```
~/.aiwb/
├── config.json              # Main configuration (JSON)
├── .aiwb.env                # API keys (plaintext or encrypted with age)
├── .keys.age                # Encrypted keys backup (if using encryption)
├── .session                 # Current session state
└── workspace/
    ├── projects/            # Project workspaces
    ├── tasks/               # Task prompt files
    │   └── inbox.prompt.md
    ├── snapshots/           # Workspace snapshots
    ├── logs/                # Chat logs and usage tracking
    │   ├── chat_YYYYMMDD_HHMMSS.log
    │   └── usage.jsonl      # Cost tracking (JSONL format)
    ├── templates/           # User templates
    ├── history/             # Session history
    └── outputs/             # Generated content
        └── task_YYYYMMDD_HHMMSS.md
```

**Key Files:**
- `config.json` - Stores provider preferences, model selection, and settings
- `.aiwb.env` - API keys (use `aiwb keys` to encrypt with age)
- `usage.jsonl` - Cost tracking per provider (view with `aiwb costs`)
- `workspace/logs/` - Conversation logs (rotated automatically)

## Pro Tips

### 1. Use Templates
Browse and use pre-built templates:
```bash
# From within aiwb
> /templates

# Or browse the templates/ directory
ls ~/.aiwb/aiworkbench/templates/
```

Available templates:
- `rest-api.prompt.md` - REST API generation
- `debug-helper.prompt.md` - Debugging assistance
- `code-review.prompt.md` - Code review template

### 2. Track Your Costs
Monitor spending per provider:
```bash
aiwb costs          # Detailed breakdown by provider
> /costs            # From within interactive mode
```

Cost data is stored in `~/.aiwb/workspace/logs/usage.jsonl`

### 3. Use Context Effectively
Add files to provide context to the AI:
```bash
# From within a mode
make> uploads ./src/ ./docs/README.md

# Or use /context command
> /context add ./config.json
> /context list
> /context clear
```

### 4. Try Different Models
Compare results from different models:
```bash
# Use settings to change default
aiwb settings

# Or specify on command line
aiwb --provider claude --model claude-3.5-sonnet chat
aiwb --provider gemini --model gemini-2.5-flash quick "task description"
```

### 5. Enable Shell Completion (Optional)
```bash
# For Bash
source ~/.aiwb/aiworkbench/completions/aiwb.bash
echo 'source ~/.aiwb/aiworkbench/completions/aiwb.bash' >> ~/.bashrc

# For Zsh
source ~/.aiwb/aiworkbench/completions/aiwb.zsh
echo 'source ~/.aiwb/aiworkbench/completions/aiwb.zsh' >> ~/.zshrc
```

### 6. Check System Health
```bash
aiwb doctor         # Diagnostic check
```

### 7. Secure Your API Keys (Recommended)
Encrypt your API keys with age:
```bash
# Install age first (if not installed)
# Then from within aiwb:
> /keys
# Select "Encrypt keys with age"
```

## Common Issues

### "No API key found for [provider]"
**Solution:** Configure your API keys
```bash
aiwb keys           # Interactive key management
> /keys             # From within aiwb
```

### "Command not found: aiwb"
**Solution:** Ensure `~/.local/bin` is in your PATH
```bash
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### "Permission denied" when running aiwb
**Solution:** Make the script executable
```bash
chmod +x ~/.local/bin/aiwb
```

### "jq: command not found" or "curl: command not found"
**Solution:** Install required dependencies
```bash
# Termux
pkg install jq curl

# Ubuntu/Debian
sudo apt install jq curl

# macOS
brew install jq curl
```

### "gum: command not found" (Warning only)
**Note:** This is optional. AIWB works without gum but with a simpler interface.
```bash
# Termux
pkg install gum

# Ubuntu/Debian - see installation section for full instructions
# macOS
brew install gum
```

### API request hangs or times out
**Solution:** Check your internet connection. AIWB has built-in timeouts (10s connection, 300s max).

### Termux-specific: Scripts not working after install
**Solution:** Fix CRLF line endings
```bash
dos2unix ~/.local/bin/*.sh 2>/dev/null || sed -i 's/\r$//' ~/.local/bin/*.sh
```

## Next Steps

### Learn More
- **Full Documentation**: [docs/USAGE.md](docs/USAGE.md)
- **Workflow Guide**: [docs/WORKFLOW-GUIDE.md](docs/WORKFLOW-GUIDE.md)
- **Architecture Overview**: [docs/OVERVIEW.md](docs/OVERVIEW.md)
- **Roadmap**: [docs/ROADMAP.md](docs/ROADMAP.md)

### Try Examples
- [First Chat](examples/01-first-chat.md)
- [Code Generation](examples/02-code-generation.md)

### Get Help
- **Documentation**: https://github.com/juanitto-maker/AIworkbench
- **Issues**: https://github.com/juanitto-maker/AIworkbench/issues
- **Discussions**: https://github.com/juanitto-maker/AIworkbench/discussions

### Contribute
See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to AIWB.

---

**Welcome to AIWB!** Happy coding with AI assistance! 🚀

**Pro tip:** Start with `aiwb wizard` if you're new, or jump straight to `aiwb` + `/make` if you're ready to dive in!
