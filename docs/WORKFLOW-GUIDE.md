# AIWB Workflow Guide - From Beginner to Power User

## 🎯 Purpose
This guide shows you different workflows for using AIWB, from simple one-liners to advanced multi-model refinement loops. Learn by example!

---

## 📚 Table of Contents
1. [Quick Start - Your First Generation](#quick-start)
2. [The Old Way vs The New Way](#old-vs-new)
3. [Example Workflows](#example-workflows)
4. [Understanding the Models](#understanding-models)
5. [Cost Management](#cost-management)
6. [Advanced Techniques](#advanced-techniques)
7. [Free APIs Worth Using](#free-apis)

---

## 🚀 Quick Start - Your First Generation

### The Absolute Easiest Way (Recommended!)

```bash
# One command, that's it!
./aiwb quick "Create a password generator script"
```

**What happens automatically:**
1. ✅ Creates your script
2. ✅ Verifies it with a different AI model (catches errors!)
3. ✅ Shows you both the code and the review
4. ✅ Saves everything to outputs
5. ✅ Cleans up temporary files

**Total typing: One command. Done!**

### Alternative: Interactive Wizard

```bash
./aiwb wizard

# Then just answer a few questions:
# - What do you want to build? → Simple script/tool
# - Brief description → Password generator
# - Technology? → Bash/Shell
# - Special requirements? → Exclude confusing characters
# - Proceed? → Yes
# - Workflow? → Quick (generate + verify)
```

**Great for:** When you want a bit more structure and guidance.

---

## 🔄 Old Way vs New Way

### ❌ THE OLD TEDIOUS WAY (Before our improvements)

```bash
# Step 1: Create a project (do I really need this?)
./aiwb project create password-tool

# Step 2: Switch to project (ugh)
./aiwb project switch password-tool

# Step 3: Create a task (more setup...)
./aiwb task create build-password-gen
# Opens editor, write prompt, save, exit

# Step 4: Estimate cost (okay this is useful)
./aiwb cpre build-password-gen

# Step 5: Generate (finally!)
./aiwb cgo build-password-gen

# Step 6: Manually verify (even more typing)
./aiwb task create verify-password-gen
# Opens editor AGAIN, write review prompt, save
./aiwb ggo verify-password-gen

# Step 7: Check outputs (where is everything?)
./aiwb outputs list

# Step 8: View the file
cat ~/.aiwb/workspace/projects/password-tool/genpass.sh
```

**Total steps: 8+ commands, multiple manual edits**
**Time: 5-10 minutes**
**Cognitive load: HIGH - need to remember task names, file paths, etc.**

### ✅ THE NEW STREAMLINED WAY

```bash
# One command
./aiwb quick "Create a password generator script"

# Optional: Improve it
./aiwb improve "Exclude ambiguous characters like 0,O,l,1"

# Optional: Improve again
./aiwb improve "Add a password strength meter"
```

**Total steps: 1 command (+ optional improvements)**
**Time: 30 seconds**
**Cognitive load: MINIMAL - just describe what you want**

---

## 💡 Example Workflows

### Example 1: Building a Simple Tool

**Goal:** Create a JSON formatter script

#### Quick Method (30 seconds)
```bash
./aiwb quick "Create a bash script that formats JSON from stdin or file, with color syntax highlighting"
```

**Output:**
- `~/.aiwb/workspace/outputs/quick_1234567890.md` - Generated script
- `~/.aiwb/workspace/outputs/quick_1234567890.feedback.md` - AI review

#### With Improvements (2 minutes)
```bash
# Initial version
./aiwb quick "JSON formatter with color highlighting"

# Add features iteratively
./aiwb improve "Add option to minify JSON instead of prettify"
./aiwb improve "Add validation with helpful error messages"
./aiwb improve "Support reading from URLs via curl"

# Check what we spent
./aiwb costs
```

---

### Example 2: Learning a New Technology

**Goal:** Understand how to use the GitHub API

#### Interactive Approach
```bash
./aiwb

# In the chat session:
aiwb> Explain how to authenticate with GitHub API and show a simple example in bash
aiwb> Now show me how to list all my repositories
aiwb> How do I create a new issue programmatically?
aiwb> /make "Complete GitHub API client in bash with auth, list repos, create issues"
aiwb> /improve "Add error handling and rate limit checks"
aiwb> /costs
```

**Learning flow:**
1. Ask questions to understand concepts
2. Generate working code when ready
3. Improve iteratively
4. Track costs

---

### Example 3: Rapid Prototyping

**Goal:** Try 3 different approaches to the same problem

```bash
# Approach 1: Pure bash
./aiwb quick "Create a file backup script in pure bash"

# Approach 2: Python
./aiwb quick "Create a file backup script in Python with argparse"

# Approach 3: Using rsync
./aiwb quick "Create a file backup script wrapping rsync with smart defaults"

# Now compare the outputs
ls -lh ~/.aiwb/workspace/outputs/

# Pick the best and improve it
./aiwb improve "Add incremental backup support and logging"
```

---

### Example 4: Using Templates for Best Practices

```bash
# Browse available templates
./aiwb templates

# Select "bash-script" template
# It pre-fills best practices:
# - POSIX compliance
# - Error handling
# - Input validation
# - Help messages
# - Colorful output

# Just add your specific requirements
# Template asks: "Describe what the script should do"
# You answer: "Monitor system resources and alert if threshold exceeded"

# Result: Professional-grade script with all best practices baked in
```

---

## 🤖 Understanding the Models

### Which AI Should I Use?

AIworkbench supports multiple providers. Here's the quick guide:

#### For Quick Scripts & Tools
- **Gemini 2.5 Flash** (Default) - Fast, cheap, great for code
- **Groq Llama 3.3 70B** - FREE, blazing fast, good quality

#### For Complex Logic
- **Claude 3.5 Sonnet** - Best reasoning, excellent code quality
- **GPT-4o** - Strong all-rounder

#### For Verification (Cross-Check)
AIWB automatically uses a **different model** to verify. Example:
- You generate with Gemini → Verifies with Claude
- You generate with Claude → Verifies with Gemini

**Why?** Different AIs catch different mistakes!

### Switching Providers

```bash
# Interactive mode
./aiwb
aiwb> /models
# Choose Provider → groq
# Choose Model → llama-3.3-70b-versatile

# Or direct
./aiwb --provider groq --model llama-3.3-70b-versatile quick "Create a script"
```

---

## 💰 Cost Management

### See What You're Spending

```bash
# Quick cost check
./aiwb costs

# Output shows:
# Total spent: $0.05 USD
#
# By Provider:
# gemini    $0.03
# claude    $0.02
#
# Recent activity:
# 2025-11-09    gemini    $0.01
# 2025-11-09    claude    $0.02
```

### Smart Cost Estimation

Before running expensive operations:

```bash
# Estimate a task
./aiwb estimate my-big-task

# Shows:
# Tier      Output Tokens    Cost (USD)
# ───────────────────────────────────────
# Basic     1300             $0.02
# Medium    2000             $0.03
# Best      3200             $0.05
```

### Auto-Estimate Settings

```bash
./aiwb
aiwb> /models
# → Preferences
# → Auto-estimate: true (estimates before generating)
# → Confirm before generate: true (asks if cost > threshold)
# → Show costs: true (shows cost after each operation)
```

### Using Free APIs to Save Money

Switch to Groq (100% free!) for development:

```bash
./aiwb settings
# Provider → groq
# Model → llama-3.3-70b-versatile

# Or keep Gemini (also has generous free tier)
```

---

## 🎓 Advanced Techniques

### Multi-Iteration Refinement

For complex projects, use the refinement loop:

```bash
./aiwb
aiwb> /refine

# This automatically:
# 1. Generates code
# 2. Verifies with different AI
# 3. Incorporates feedback
# 4. Generates improved version
# 5. Verifies again
# 6. Repeat 3 times (or custom iterations)
```

### Conversation History

```bash
# View past sessions
./aiwb history

# Use fzf to search and view any session
# Or see last 10:
ls -lht ~/.aiwb/workspace/logs/chat_*.log | head -10
```

### Template Customization

Create your own templates:

```bash
# 1. Create template file
cat > ~/.aiwb/workspace/templates/my-api-template.md <<'EOF'
Create a REST API with:
- Express.js framework
- JWT authentication
- MongoDB database
- Input validation with Joi
- Error handling middleware
- API documentation with Swagger

Describe the API endpoints:
EOF

# 2. Use it
./aiwb templates
# Select: my-api-template
```

### Combining Direct and Interactive

```bash
# Generate something quickly
./aiwb quick "Create a log analyzer script"

# Then enter interactive mode to refine
./aiwb
aiwb> /improve "Add support for multiple log formats"
aiwb> /improve "Add statistics and charts using gnuplot"
aiwb> How do I deploy this to a server?
aiwb> /make "Create a systemd service file for the log analyzer"
```

---

## 🌟 Free APIs Worth Using

### Already Supported & Free

1. **Groq** ⚡
   - Status: 100% FREE
   - Tokens/min: 6,000 TPM
   - Requests/day: 14,400
   - Speed: Blazing fast (LPU architecture)
   - Models: Llama 3.3 70B, Mixtral 8x7B, Gemma 2 9B
   - **Already in AIWB!**

2. **Google Gemini** (Free Tier)
   - Status: Generous free tier
   - Models: 2.5 Flash, 2.0 Flash Lite (very fast & cheap)
   - Great for: Code generation, quick tasks
   - **Already in AIWB! (Default)**

3. **Anthropic Claude** (Free Trial)
   - Status: $5 free credits for new accounts
   - Models: Claude 3.5 Sonnet, 3.5 Haiku
   - Best for: Complex reasoning, code quality
   - **Already in AIWB!**

### Recommended to Add

4. **Hugging Face Inference API** ⭐⭐⭐⭐⭐
   - Status: FREE with limits
   - Models: 100,000+ open-source models
   - Why add: Massive variety, true OSS
   - Use case: Experimentation, specialized models

5. **Mistral AI**
   - Status: FREE tier available
   - Models: Mistral 7B, Mixtral 8x7B
   - Why add: European option, great performance
   - Use case: Alternative to big US providers

6. **Cohere**
   - Status: FREE for prototyping
   - Models: Command R, Command R+
   - Why add: Best-in-class for RAG
   - Use case: Retrieval-augmented tasks

### Cost Comparison (Paid Tiers)

For when you outgrow free tiers:

| Provider | Model | Input ($/1M tokens) | Output ($/1M tokens) |
|----------|-------|---------------------|----------------------|
| Groq | Llama 3.3 70B | $0.59 | $0.79 |
| Gemini | 2.5 Flash | $0.075 | $0.30 |
| Claude | 3.5 Sonnet | $3.00 | $15.00 |
| OpenAI | GPT-4o | $2.50 | $10.00 |

**Tip:** Use Groq/Gemini for iterations, Claude for final polish!

---

## 🎯 Recommended Workflow Progression

### Week 1: Learn the Basics
```bash
# Day 1: Setup
./aiwb keys  # Add your API keys
./aiwb doctor  # Check everything works

# Day 2-3: Try quick commands
./aiwb quick "Create a hello world script"
./aiwb quick "Create a file renamer tool"
./aiwb quick "Create a API request script"

# Day 4-5: Use improvements
./aiwb quick "Create a backup script"
./aiwb improve "Add logging"
./aiwb improve "Add email notifications"

# Day 6-7: Explore templates
./aiwb templates
```

### Week 2: Get Comfortable
```bash
# Use wizard for structured projects
./aiwb wizard

# Try different providers
./aiwb settings  # Switch to Claude
./aiwb quick "Complex algorithm implementation"

./aiwb settings  # Switch to Groq
./aiwb quick "Quick utility script"

# Practice cost awareness
./aiwb costs  # Check spending
```

### Week 3: Advanced Usage
```bash
# Multi-iteration refinement
./aiwb refine

# Custom templates
# Create templates for your common patterns

# Integrate into your workflow
# Use AIWB for all scripting needs
```

### Month 2+: Power User
```bash
# Combine everything:
# - Use templates for structure
# - Quick for rapid prototyping
# - Improve for iterations
# - Different models for different tasks
# - Cost-optimize with free APIs

# Example daily usage:
./aiwb quick "Today's automation task"
./aiwb improve "Based on testing feedback"
./aiwb costs  # Stay on budget
```

---

## 📖 Quick Reference Card

```
# ONE-LINERS (Use These Daily!)
./aiwb quick "description"     # Generate + verify
./aiwb improve "suggestion"    # Improve last output
./aiwb costs                   # Check spending

# INTERACTIVE
./aiwb                         # Start chat session
  /quick description           # Quick generate
  /wizard                      # Guided workflow
  /improve suggestion          # Improve last
  /templates                   # Browse templates
  /models                      # Change provider/model
  /costs                       # Cost check
  /help                        # Show all commands

# CONFIGURATION
./aiwb keys                    # Manage API keys
./aiwb settings                # Configure everything
./aiwb status                  # Current setup

# ADVANCED
./aiwb refine                  # Multi-iteration loop
./aiwb wizard                  # Step-by-step guide
./aiwb templates               # Use/create templates
```

---

## 🤝 Getting Help

- **Help command:** `./aiwb --help` or `/help` in chat
- **Check health:** `./aiwb doctor`
- **Current status:** `./aiwb status`
- **GitHub:** https://github.com/juanitto-maker/AIworkbench

---

## 🎓 Learning Resources

### Understand the Philosophy

AIWB is built on the **Generator-Verifier Loop** concept:
1. One AI generates code
2. A different AI verifies it
3. Feedback improves the next iteration
4. Repeat until satisfied

This catches more bugs than single-model generation!

### Best Practices

1. **Start small:** Use `/quick` for everything at first
2. **Iterate freely:** Use `/improve` without fear - it's cheap with free APIs
3. **Cross-check:** Let auto-verify catch mistakes
4. **Track costs:** Run `/costs` weekly to stay aware
5. **Use templates:** They encode best practices
6. **Switch models:** Different AIs for different tasks

### Common Patterns

```bash
# Pattern 1: Rapid prototype
./aiwb quick "idea" → test → improve → improve → done

# Pattern 2: Exploration
./aiwb → chat to understand → /quick when ready → iterate

# Pattern 3: Production-quality
./aiwb wizard → choose "Full refinement" → review outputs → done

# Pattern 4: Learning
./aiwb → ask questions → generate examples → improve understanding
```

---

**Remember:** The goal is LESS typing, MORE automation, BETTER results.

Start with `/quick` and add complexity only when you need it! 🚀
