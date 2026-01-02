# AIWB: Detailed Usage Guide

This document provides in-depth instructions for using all AIWB commands, workflows, and features.

---

## Table of Contents

* [Core Concepts](#core-concepts)
* [Getting Started](#getting-started)
* [Mode-Based Workflows](#mode-based-workflows)
* [Command Reference](#command-reference)
* [Configuration](#configuration)
* [Advanced Features](#advanced-features)
* [Cost Management](#cost-management)

---

## Core Concepts

### The Generator-Verifier Loop

AIWB's core innovation is the **Generator-Verifier loop**:

1. **Generator AI** creates initial content based on your prompt
2. **Verifier AI** (different model) critiques and provides feedback
3. You can iterate based on feedback for continuous improvement

This approach:
- Reduces hallucinations
- Improves code quality
- Provides multiple perspectives
- Creates self-correcting workflows

### Providers and Models

AIWB supports multiple AI providers:

| Provider | Models | Free Tier | Notes |
|----------|--------|-----------|-------|
| **Gemini** | gemini-2.5-flash, gemini-2.0-flash-lite | ✅ Yes | Fast, good for general use |
| **Claude** | claude-3.5-sonnet, claude-3.5-haiku | ❌ No | Excellent for code |
| **OpenAI** | gpt-4o, gpt-3.5-turbo | ❌ No | Widely compatible |
| **Groq** | llama-3.3-70b, mixtral-8x7b | ✅ Yes | Very fast inference |
| **xAI/Grok** | grok-beta, grok-2 | ❌ Beta | New, powerful models |
| **Ollama** | Any local model | ✅ Local | Privacy-focused, free |

### Workspace Structure

```
~/.aiwb/
├── config.json              # Configuration
├── .aiwb.env                # API keys
├── .keys.age                # Encrypted keys (optional)
├── .session                 # Session state
└── workspace/
    ├── projects/            # Project workspaces
    ├── tasks/               # Task definitions
    ├── outputs/             # Generated content
    ├── logs/                # Chat logs and usage
    │   ├── chat_*.log
    │   └── usage.jsonl      # Cost tracking
    ├── templates/           # User templates
    ├── history/             # Session history
    └── snapshots/           # Workspace backups
```

---

## Getting Started

### Installation

See [QUICKSTART.md](../QUICKSTART.md) for detailed installation instructions.

### First Run

```bash
# Start AIWB
aiwb

# Configure API keys
> /keys

# Configure settings
> /models

# Get help
> /help
```

---

## Mode-Based Workflows

Modes are AIWB's most powerful feature - structured, multi-step workflows for complex tasks.

### Available Modes

#### `/make` Mode - Generate from Scratch

Create new code, content, or solutions.

**Usage:**
```bash
aiwb
> /make
make> prompt Create a REST API for todo management
make> model              # Select AI model
make> uploads ./docs/    # Add context
make> check              # Configure verifier
make> status             # Review configuration
make> run                # Execute
```

**Commands in /make mode:**
- `prompt <text>` - Set instructions as text
- `instruct <file.md>` - Load instructions from file
- `model` - Choose AI model interactively
- `uploads <files/dirs>` - Add context files
- `check [instructions]` - Configure verification AI
- `status` - Show current configuration
- `run` - Execute (with cost preview)
- `exit` - Leave mode

#### `/tweak` Mode - Modify Existing Code

Modify, update, or enhance existing code.

**Usage:**
```bash
> /tweak
tweak> prompt Add authentication to the API
tweak> uploads ./src/api.js
tweak> run
```

#### `/debug` Mode - Find and Fix Bugs

Troubleshoot issues and find bugs.

**Usage:**
```bash
> /debug
debug> prompt The API returns 500 errors on POST requests
debug> uploads ./src/api.js ./logs/error.log
debug> run
```

---

## Command Reference

### Interactive Commands (Slash Commands)

These commands work in interactive chat mode (`aiwb`):

#### Mode Commands

- `/make` - Enter make mode (generate from scratch)
- `/tweak` - Enter tweak mode (modify existing)
- `/debug` - Enter debug mode (troubleshoot)

#### Quick Commands

- `/quick <description>` - One-shot generation with auto-verify
  ```bash
  > /quick Create a Python password generator
  ```

- `/wizard` - Interactive guided workflow (beginner-friendly)
  ```bash
  > /wizard
  ```

- `/improve <suggestion>` - Improve last output
  ```bash
  > /improve Add error handling
  ```

#### Management Commands

- `/status` - Show overall status (config, context, costs)
- `/context` - Manage context files
  - `/context add <files>` - Add files to context
  - `/context list` - List current context
  - `/context clear` - Clear all context
- `/history` - View session history
- `/costs` - Show cost breakdown by provider

#### Configuration Commands

- `/keys` - Manage API keys (add, list, encrypt)
- `/models` - Configure provider and model preferences
- `/templates` - Browse and use templates

#### Utility Commands

- `/clear` - Clear screen
- `/help` - Show help
- `/exit` - Quit (with confirmation)

### Direct Commands

These commands work from the shell:

```bash
# Start modes
aiwb                     # Interactive chat (default)
aiwb chat                # Explicit chat mode
aiwb wizard              # Guided workflow

# Quick actions
aiwb quick "description" # One-shot generation

# Configuration
aiwb keys                # Manage API keys
aiwb settings            # Configure settings
aiwb status              # Show status
aiwb doctor              # System health check

# Cost management
aiwb costs               # View spending

# With options
aiwb --provider gemini --model gemini-2.5-flash chat
aiwb --debug chat        # Enable debug output
```

---

## Configuration

### API Keys

**Interactive setup:**
```bash
aiwb keys
```

**Manual setup:**
```bash
# Edit ~/.aiwb/.aiwb.env
export GEMINI_API_KEY="your-key"
export ANTHROPIC_API_KEY="your-key"
export OPENAI_API_KEY="your-key"
export GROQ_API_KEY="your-key"
export XAI_API_KEY="your-key"
```

**Encryption (recommended):**
```bash
# Install age first
# Then in aiwb:
> /keys
# Select "Encrypt with age"
```

### Provider Settings

Configure default provider and model:

```bash
aiwb models
# Or:
> /models
```

**config.json structure:**
```json
{
  "model_provider": "gemini",
  "model_name": "gemini-2.5-flash",
  "gemini_model": "gemini-2.5-flash",
  "claude_model": "claude-3.5-sonnet",
  "openai_model": "gpt-4o",
  "groq_model": "llama-3.3-70b-versatile",
  "xai_model": "grok-beta"
}
```

---

## Advanced Features

### Context Management

Add files/directories to provide context:

**In modes:**
```bash
make> uploads ./src/ ./README.md ./docs/
```

**Using /context:**
```bash
> /context add ./config.json
> /context add ./src/**/*.js
> /context list
> /context clear
```

### Templates

Use pre-built templates:

```bash
> /templates
```

**Available templates:**
- `rest-api.prompt.md` - REST API generation
- `debug-helper.prompt.md` - Debugging assistance
- `code-review.prompt.md` - Code review template

**Create your own:**
```bash
# Add templates to ~/.aiwb/workspace/templates/
# Use markdown format with clear instructions
```

### Verification Configuration

Configure how the verifier AI reviews output:

```bash
make> check Focus on security vulnerabilities and error handling
make> check Review code quality, performance, and best practices
```

---

## Cost Management

### Pre-execution Estimates

AIWB shows cost estimates before executing:

```bash
make> run
# Shows: Estimated cost: $0.0023 (Gemini)
# Asks for confirmation
```

### Cost Tracking

View spending breakdown:

```bash
aiwb costs
> /costs
```

**Output:**
```
Cost Breakdown by Provider:
- Gemini: $0.45 (45 requests)
- Claude: $1.23 (12 requests)
- OpenAI: $0.89 (8 requests)
Total: $2.57
```

**Data stored in:**
`~/.aiwb/workspace/logs/usage.jsonl`

### Cost Optimization Tips

1. **Use free tiers**: Gemini and Groq offer generous free tiers
2. **Choose appropriate models**: Use smaller models for simple tasks
3. **Minimize context**: Only upload necessary files
4. **Review estimates**: Always check cost before running
5. **Track usage**: Regularly check `aiwb costs`

---

## Examples

### Example 1: Create a REST API

```bash
aiwb
> /make
make> prompt Create a REST API with Express.js for user management. Include GET /users, POST /users, PUT /users/:id, DELETE /users/:id. Add input validation and error handling.
make> model
# Select Claude 3.5 Sonnet
make> check Focus on security, validation, and error handling
make> run
```

### Example 2: Debug an Issue

```bash
aiwb
> /debug
debug> prompt The API returns 500 errors when creating users
debug> uploads ./src/api.js ./logs/error.log
debug> model
# Select Gemini 2.5 Flash
debug> run
```

### Example 3: Quick Generation

```bash
aiwb quick "Create a Python function to validate email addresses with regex"
```

### Example 4: Improve Output

```bash
# After generating something
> /improve Add comprehensive error handling and logging
```

---

## Troubleshooting

### Common Issues

See [QUICKSTART.md - Common Issues](../QUICKSTART.md#common-issues) for detailed troubleshooting.

### Debug Mode

Enable debug output:

```bash
aiwb --debug chat
```

### System Health Check

```bash
aiwb doctor
```

Checks:
- Dependencies installed
- API keys configured
- Workspace integrity
- Configuration validity

---

## Tips and Best Practices

1. **Start with /wizard**: If you're new, use `/wizard` for guided workflows
2. **Use modes for complex tasks**: Modes provide structure and verification
3. **Provide context**: Upload relevant files for better results
4. **Review estimates**: Always check costs before execution
5. **Use verification**: Configure `check` for quality assurance
6. **Try different models**: Compare results across providers
7. **Track costs**: Regularly monitor spending with `/costs`
8. **Secure your keys**: Use `age` encryption for API keys
9. **Use templates**: Start with templates for common tasks
10. **Iterate**: Use `/improve` to refine outputs

---

For more information:
- [OVERVIEW.md](OVERVIEW.md) - Design philosophy
- [WORKFLOW-GUIDE.md](WORKFLOW-GUIDE.md) - Workflow patterns
- [ROADMAP.md](ROADMAP.md) - Future plans
- [GitHub Issues](https://github.com/juanitto-maker/AIworkbench/issues) - Report bugs
