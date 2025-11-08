# AIWB Quick Start Guide

Get up and running with AIWB in 5 minutes!

## Installation

### One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/juanitto-maker/AIworkbench/main/install.sh | bash
```

### Manual Install

```bash
git clone https://github.com/juanitto-maker/AIworkbench.git
cd AIworkbench
./install.sh
```

## First Run

### 1. Start AIWB

```bash
aiwb
```

### 2. Set Up API Keys

On first run, you'll be prompted to configure API keys:

```
╔══════════════════════════════════════════════════════════╗
║ API Key Setup                                             ║
╚══════════════════════════════════════════════════════════╝

AIWB supports multiple AI providers. Set up the ones you want to use.

Which API key would you like to configure?
  > Gemini ○ Not set
    Claude ○ Not set
    OpenAI ○ Not set
    Done
```

**Get Your API Keys:**
- **Gemini**: https://makersuite.google.com/app/apikey (Free tier available)
- **Claude**: https://console.anthropic.com/ (Requires payment)
- **OpenAI**: https://platform.openai.com/api-keys (Requires payment)

Or configure manually:

```bash
aiwb keys
```

### 3. Start Chatting!

Just type normally:

```
> Write a Python function to calculate fibonacci numbers
```

The AI will respond with code and explanations.

## Essential Commands

### Interactive Chat
```bash
aiwb              # Start interactive mode
aiwb chat         # Explicit chat mode
```

### Task Management
```bash
aiwb task new my-project        # Create a new task
aiwb generate my-project        # Generate code for task
aiwb estimate my-project        # Estimate cost first
aiwb verify my-project          # Review generated code
aiwb refine my-project          # Auto-improve with loop
```

### Configuration
```bash
aiwb keys         # Manage API keys
aiwb settings     # Change provider/model
aiwb status       # Show current config
```

### Slash Commands (in chat)
```
/help             # Show commands
/settings         # Change settings
/estimate         # Estimate cost
/generate         # Generate content
/costs            # Show spending
/exit             # Quit
```

## First Real Task

Let's create a REST API endpoint:

### 1. Create Task
```bash
aiwb task new api-endpoint
```

### 2. Edit Task (opens in $EDITOR)
```bash
$EDITOR ~/.aiwb/workspace/tasks/api-endpoint.prompt.md
```

Add:
```markdown
# Create a REST API for user management

Requirements:
- GET /api/users - List all users
- POST /api/users - Create user
- Use Express.js
- Add input validation
- Include error handling
```

### 3. Estimate Cost
```bash
aiwb estimate api-endpoint
```

### 4. Generate
```bash
aiwb generate api-endpoint
```

Output saved to: `~/.aiwb/workspace/outputs/api-endpoint_[timestamp].md`

### 5. Verify Quality
```bash
aiwb verify api-endpoint
```

Gets feedback from a different AI model!

### 6. Auto-Refine (Optional)
```bash
aiwb refine api-endpoint --iterations=3
```

Automatically improves the code based on AI feedback!

## File Structure

After setup, your workspace looks like:

```
~/.aiwb/
├── config.json              # Configuration
├── .aiwb.env                # API keys (encrypted optional)
└── workspace/
    ├── tasks/               # Your task prompts
    │   ├── inbox.prompt.md
    │   └── api-endpoint.prompt.md
    ├── outputs/             # Generated content
    │   └── api-endpoint_20251108_120000.md
    ├── logs/                # Chat history and usage
    │   ├── chat_20251108_120000.log
    │   └── usage.jsonl
    ├── templates/           # Reusable templates
    └── history/             # Session history
```

## Pro Tips

### 1. Use Templates
```bash
aiwb template list
aiwb template use rest-api
```

### 2. Track Costs
```bash
aiwb costs              # See spending breakdown
```

### 3. Try Different Models
```bash
aiwb --provider claude --model sonnet-3.5 chat
```

### 4. Enable Shell Completion
```bash
# Bash
echo 'source ~/.aiwb/aiworkbench/completions/aiwb.bash' >> ~/.bashrc

# Zsh
echo 'source ~/.aiwb/aiworkbench/completions/aiwb.zsh' >> ~/.zshrc
```

### 5. Check System Health
```bash
aiwb doctor
```

## Common Issues

### "No API key found"
```bash
aiwb keys    # Set up your API keys
```

### "Command not found: aiwb"
Ensure `~/.local/bin` is in your PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### "Permission denied"
```bash
chmod +x ~/.local/bin/aiwb
```

## Next Steps

- Read the [Full Documentation](docs/USAGE.md)
- Try [Example Workflows](examples/)
- Join the [Community](https://github.com/juanitto-maker/AIworkbench/discussions)
- Report [Issues](https://github.com/juanitto-maker/AIworkbench/issues)

## Support

- **Documentation**: https://github.com/juanitto-maker/AIworkbench
- **Issues**: https://github.com/juanitto-maker/AIworkbench/issues
- **Discussions**: https://github.com/juanitto-maker/AIworkbench/discussions

---

**Welcome to AIWB!** Happy coding with AI assistance! 🚀
