# Chat Orchestration - Natural Language Commands

## 🎯 Overview

The chat now intelligently detects your intent and automatically invokes the right functionality - **no slash commands required**!

## ✨ What's New

Previously, you HAD to use slash commands:
```
❌ Old Way (required):
> /scanrepo
> /contextload
> /swarm
> /make
```

Now, just talk naturally:
```
✅ New Way (natural):
> scan this repository
> load context
> enable swarm mode
> analyze this app
```

## 🧠 Intent Detection

The chat router detects 8 types of intents:

### 1. Scan Intent
**Triggers:** "scan repo", "scan codebase", "scan this", "scan project"

**Example:**
```
You: scan this repository
App: 🔍 Scanning repository...
     [Runs /scanrepo automatically]
```

### 2. Analyze Intent
**Triggers:** "analyze app", "analyze code", "code analysis", "review code"

**Example:**
```
You: analyze this app
App: 🔍 Analyzing codebase with AI...
     [Scans if needed, then runs AI analysis]
```

### 3. Context Intent
**Triggers:** "load context", "save context", "show context", "list context"

**Example:**
```
You: load context
App: 📂 Loading saved context...
     [Runs /contextload automatically]

You: show context
App: 📋 Showing context...
     [Displays context state]
```

### 4. Swarm Intent
**Triggers:** "use swarm", "enable swarm", "swarm mode", "activate swarm"

**Example:**
```
You: enable swarm mode
App: 🐝 Swarm Mode Configuration
     Current Status: OFF

     To use swarm mode for analysis:
       1. Swarm is now enabled
       2. Add context: run scan or add files
       3. Use /make with your prompt
       4. Swarm will activate for large contexts

     ✓ Swarm mode enabled!
```

### 5. Status Intent
**Triggers:** "show status", "check status", "current status"

**Example:**
```
You: show status
App: 📊 Current Status

     Platform:   termux
     Provider:   gemini
     Model:      2.5-flash
     Repository: AIworkbench
     Swarm:      🐝 ON (auto, 5 workers)
```

### 6. Edit Intent
**Triggers:** "implement", "add", "fix", "update", "modify", "change", "edit"

**Example:**
```
You: add a dark mode toggle
App: 🤖 Detected code change request. Analyzing repository...
     [Routes to smart_edit automatically]
```

### 7. Generate Intent
**Triggers:** "generate", "scaffold", "boilerplate", "build from scratch"

**Example:**
```
You: generate a login page
App: 🤖 Starting code generation workflow...
     [Enters /make mode automatically]
```

### 8. Chat Intent (Questions)
**Triggers:** "how", "what", "why", "explain", questions with "?"

**Example:**
```
You: how does swarm mode work?
App: [Provides explanation via AI chat]
```

## 🚀 Powerful Workflows

### Workflow 1: Quick Analysis
```
You: scan this repo

App: [Scans all files]
     Context saved: 45 source files + analysis

You: analyze this codebase for improvements

App: [Uses swarm if enabled]
     🐝 Swarm Mode Execution
     Processing 5 chunks with 5 parallel workers
     [Complete analysis provided]
```

### Workflow 2: Enable Swarm & Analyze
```
You: enable swarm mode

App: ✓ Swarm mode enabled!

You: use swarm to analyze the app

App: 🔍 Analyzing codebase with AI...
     [Scans if needed]
     🐝 Swarm Mode Execution
     [Multi-agent analysis]
```

### Workflow 3: Context Management
```
You: scan this project

App: [Scans files]
     Context saved: 30 files

You: show context

App: Context: 0 in-memory, 30 saved + scan

You: load context

App: ✅ Loaded 30 files into memory

You: analyze the architecture

App: [Analyzes with loaded context]
```

## 🎯 Best Practices

### 1. Natural Language Works
```
✅ "scan this repo"
✅ "enable swarm"
✅ "analyze the codebase"
✅ "load my context"
✅ "show current status"
```

### 2. Still Use Slash Commands When Specific
```
✅ /make     (when you want the make menu)
✅ /tweak    (when you want tweak mode specifically)
✅ /context  (when you want the context menu)
```

### 3. Questions Stay in Chat
```
✅ "How does swarm work?"      → AI explanation
✅ "What is context?"          → AI explanation
✅ "Why use swarm mode?"       → AI explanation
```

### 4. Commands Are Detected
```
✅ "scan this"                 → Runs /scanrepo
✅ "analyze app"               → Runs analysis workflow
✅ "enable swarm"              → Enables swarm mode
```

## 🔍 How It Works

### Detection Order (Priority)

1. **Scan keywords** → Repository scan
2. **Context keywords** → Context operations
3. **Swarm keywords** → Swarm configuration
4. **Status keywords** → Status display
5. **Edit keywords** → Code editing
6. **Generate keywords** → Code generation
7. **Analyze keywords** → AI analysis
8. **Question keywords** → AI chat
9. **Default** → AI chat

### Intent Detection Examples

```bash
"scan this repo"
→ Matches: "scan.*repo"
→ Intent: scan
→ Action: auto_scan_repo()
→ Result: Repository scanned

"load context"
→ Matches: "load.*context"
→ Intent: context
→ Action: auto_handle_context() → cmd_contextload()
→ Result: Context loaded

"enable swarm mode"
→ Matches: "enable swarm"
→ Intent: swarm
→ Action: auto_handle_swarm() → Enables swarm
→ Result: Swarm enabled

"analyze this app"
→ Matches: "analyze.*app"
→ Intent: analyze
→ Action: auto_analyze_code() → Scans + analyzes
→ Result: AI analysis provided
```

## 📋 Complete Command Reference

### Natural Language → Action Mapping

| What You Say | What Happens | Equivalent Slash Command |
|--------------|--------------|--------------------------|
| "scan this repo" | Scans repository | `/scanrepo` |
| "scan repository" | Scans repository | `/scanrepo` |
| "scan codebase" | Scans repository | `/scanrepo` |
| "analyze app" | Scans + AI analysis | `/scanrepo` → `/make` |
| "analyze code" | Scans + AI analysis | `/scanrepo` → `/make` |
| "load context" | Loads saved context | `/contextload` |
| "save context" | Saves context | `/contextsave` |
| "show context" | Shows context state | `/contextshow` |
| "clear context" | Clears context | `/contextclear` |
| "enable swarm" | Enables swarm mode | `/swarm` → Enable |
| "use swarm" | Enables swarm mode | `/swarm` → Enable |
| "swarm mode" | Shows swarm menu | `/swarm` |
| "show status" | Shows current status | `/status` |
| "check status" | Shows current status | `/status` |
| "implement X" | Code editing | (smart_edit) |
| "add X" | Code editing | (smart_edit) |
| "fix X" | Code editing | (smart_edit) |
| "generate X" | Code generation | `/make` |
| "create X" | Code editing/generation | (context-dependent) |

## 🎓 Pro Tips

### 1. Combine Operations
```
You: enable swarm, then scan and analyze this repo

App: [Enables swarm]
     [Scans repository]
     [Runs AI analysis with swarm]
```

### 2. Context-Aware Operations
```
You: scan this

App: [Scans current directory]

You: now analyze it

App: [Uses just-scanned context for analysis]
```

### 3. Chained Workflows
```
You: load context

App: [Loads 30 files]

You: analyze for security issues

App: [Analyzes loaded files for security]
```

## 🐛 Troubleshooting

### Intent Not Detected?
If the chat doesn't detect your intent, try:
1. Use more specific keywords from the triggers list
2. Use the slash command directly
3. Rephrase your request

**Examples:**
```
❌ "I want to see the repo"
✅ "scan this repo"

❌ "turn on that swarm thing"
✅ "enable swarm mode"

❌ "check what's going on"
✅ "show status"
```

### Still Goes to AI Chat?
If your command went to AI chat instead of routing:
1. Check if you used a question word (how, what, why)
2. Try removing question marks
3. Use imperative form (commands)

**Examples:**
```
❌ "Can you scan the repo?"        → Goes to chat
✅ "scan the repo"                 → Runs scan

❌ "How do I enable swarm?"        → Goes to chat
✅ "enable swarm"                  → Enables swarm
```

## 🎉 Summary

**You asked:** "Why not possible for chat to use all functionality?!"

**Answer:** It IS now! Just talk naturally:
- "scan this" → Scans
- "analyze app" → Analyzes
- "enable swarm" → Enables swarm
- "load context" → Loads context
- "show status" → Shows status

No slash commands needed! The chat is now truly intelligent. 🚀

---

*For more information, see:*
- `docs/SWARM_MODE_GUIDE.md` - Swarm mode details
- `docs/CRITICAL_FIXES.md` - Recent bug fixes
- `QUICKSTART.md` - Getting started guide
