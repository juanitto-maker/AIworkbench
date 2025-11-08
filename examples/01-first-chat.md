# Example 1: Your First Chat with AIWB

This example shows how to get started with AIWB in interactive chat mode.

## Prerequisites

1. AIWB installed
2. API key configured (Gemini, Claude, or OpenAI)

## Step 1: Start AIWB

```bash
aiwb
```

Or explicitly start chat mode:

```bash
aiwb chat
```

## Step 2: First Interaction

You'll see the status display showing your configuration:

```
╔══════════════════════════════════════════════════════════╗
║ AIWB Interactive Chat                                     ║
╚══════════════════════════════════════════════════════════╝

AIWB Status

Platform:   linux
Workspace:  ~/.aiwb/workspace
Provider:   gemini
Model:      flash-1.5

Project:    none
Task:       inbox

Chat started. Type /help for commands or /exit to quit.

>
```

## Step 3: Ask Something

Try asking a simple question:

```
> Explain how async/await works in JavaScript
```

The AI will respond with a detailed explanation.

## Step 4: Use Slash Commands

Try some built-in commands:

```
> /status
```

Shows your current configuration.

```
> /help
```

Shows available commands.

```
> /settings
```

Opens the settings menu to change provider/model.

## Step 5: Exit

When done:

```
> /exit
```

## What Just Happened?

- AIWB initialized your workspace at `~/.aiwb/workspace`
- Created default task file (`inbox.prompt.md`)
- Connected to your chosen AI provider
- Logged your conversation to `~/.aiwb/workspace/logs/`
- Tracked API usage and costs

## Next Steps

- Try [Example 2: Generating Code](02-code-generation.md)
- Learn about [tasks and projects](03-tasks-and-projects.md)
- Explore [cost estimation](04-cost-estimation.md)
