# Context Management Guide

Understanding how AIWB manages context is key to working efficiently with the AI. This guide explains the two types of context and how to use them effectively.

## Table of Contents

- [What is Context?](#what-is-context)
- [Two Types of Context](#two-types-of-context)
- [How Context Works](#how-context-works)
- [Common Workflows](#common-workflows)
- [Commands Reference](#commands-reference)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## What is Context?

**Context** refers to the files and information that AIWB sends to the AI along with your messages. When you ask the AI a question about your code, it needs to see your code files - that's context.

Think of context as the documents you'd spread out on your desk when working on a project.

---

## Two Types of Context

### 🔄 In-Memory Context (Temporary)

**What it is:**
- Files actively loaded in your current AIWB session
- Stored in the `MODE_UPLOADS[]` array in RAM
- These files are included in every AI conversation during this session

**Lifespan:**
- ✅ Exists: While AIWB is running
- ❌ Lost: When you close AIWB

**Use when:**
- Working on files during this session only
- Trying out different contexts
- Need immediate, temporary access to files

**View with:**
```
/context → List current context (in-memory)
```

---

### 💾 Persistent Context (Saved)

**What it is:**
- Context saved to disk (`~/.aiwb/workspace/.context_state`)
- Survives after closing AIWB
- Can be restored in future sessions

**Lifespan:**
- ✅ Exists: Permanently (until you clear it)
- ✅ Survives: Closing and reopening AIWB

**Use when:**
- Working on a project across multiple sessions
- Want to resume where you left off
- Have a standard set of files you always need

**View with:**
```
/context → Show persistent context (saved state)
```

---

## How Context Works

### Visual Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. START AIWB                                               │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ↓
                ┌───────────────────────────────┐
                │ Found context from previous   │
                │ session (2 days ago)          │
                │                               │
                │ Resume with previous context? │
                │   [Yes]  [No]                 │
                └───────────┬───────────────────┘
                            │
                    ┌───────┴────────┐
                    │                │
                Yes │                │ No
                    ↓                ↓
        ┌─────────────────┐   ┌──────────────┐
        │ Select files    │   │ Start with   │
        │ to load         │   │ empty memory │
        │ ✓ file1.js      │   └──────────────┘
        │ ✓ file2.js      │
        │   file3.js      │
        └────────┬────────┘
                 │
                 ↓
┌────────────────────────────────────────────────────────────┐
│ IN-MEMORY CONTEXT (Active)                                 │
│ • file1.js                                                 │
│ • file2.js                                                 │
│                                                            │
│ These files are included in all AI prompts this session   │
└────────────────────────────────────────────────────────────┘
                 │
                 │ During session, you can:
                 │ • Add more files
                 │ • Remove files
                 │ • View what's loaded
                 │
                 ↓
        ┌────────────────────┐
        │ /context menu      │
        │ • Add files        │
        │ • Remove files     │
        │ • Save to disk     │
        └────────────────────┘
                 │
                 │ Optional: Save to disk
                 ↓
┌────────────────────────────────────────────────────────────┐
│ PERSISTENT CONTEXT (Saved to disk)                        │
│ ~/.aiwb/workspace/.context_state                           │
│                                                            │
│ Saved for next session                                    │
└────────────────────────────────────────────────────────────┘
```

### Step-by-Step Example

**Day 1 - Starting a new project:**

1. You start AIWB: `aiwb chat`
2. No previous context exists
3. You add files: `/context` → "Add files/directories"
4. Select: `src/app.js`, `README.md`
5. **Files are now in memory** - included in AI conversations
6. *(Optional)* Save for tomorrow: `/context` → "Save in-memory context to persistent state"
7. Close AIWB

**Day 2 - Continuing work:**

1. Start AIWB: `aiwb chat`
2. Prompt appears: **"Found context from previous session (1 day ago)"**
3. You choose: **Yes**
4. File selection appears:
   ```
   ✅ Select All
   📄 src/app.js
   📄 README.md
   ```
5. You select both files
6. **Files load into memory** - ready to use
7. Continue working with context active

---

## Common Workflows

### Workflow 1: Quick One-Time Questions

```bash
# Start AIWB
aiwb chat

# Add files for this session only
/context → Add files/directories → Select files

# Ask questions
> How does the authentication work in app.js?

# When done, just exit
# No need to save - it was temporary context
```

**Result:** Files were used this session but not saved for later.

---

### Workflow 2: Ongoing Project Work

```bash
# Day 1: Set up project context
aiwb chat
/context → Add files/directories
# Select your main project files

# Save for future sessions
/context → Save in-memory context to persistent state

# Day 2: Resume where you left off
aiwb chat
# [Yes] to "Resume with previous context?"
# Select files you want active today

# Continue working...
```

**Result:** Your project context is saved and reusable across sessions.

---

### Workflow 3: Selective Context Loading

```bash
# You have 10 files saved in persistent context
# But today you only need 2 of them

aiwb chat
# [Yes] to resume
# In file selection: Check only the 2 files you need today
# Press Enter

# Work with just those 2 files in memory
```

**Result:** Persistent context has 10 files, but only 2 are active in memory today.

---

## Commands Reference

### Via `/context` Menu

| Command | Where it Acts | What it Does |
|---------|---------------|--------------|
| **Add files/directories** | In-Memory | Adds files to current session |
| **List current context (in-memory)** | View | Shows what's active now |
| **Show persistent context (saved state)** | View | Shows what's saved to disk |
| **Load persistent context into memory** | Memory ← Disk | Loads all saved files into session |
| **Save in-memory context to persistent state** | Disk ← Memory | Saves current files to disk |
| **Remove from in-memory context** | In-Memory | Removes from current session |
| **Clear all context** | Both | Clears memory AND disk |

### Standalone Commands

```bash
/contextload     # Load saved context into memory
/contextsave     # Save current memory to disk
/contextshow     # Show persistent state details
/contextclear    # Clear everything (memory + disk)
/contextrefresh  # Re-scan repository
/contextremove   # Remove specific file
```

---

## Best Practices

### ✅ Do

- **Start sessions with Yes** if resuming project work
  - You can always deselect files you don't need

- **Use in-memory for experiments**
  - Try loading different files without cluttering saved state

- **Save context before long breaks**
  - Use "Save in-memory to persistent" before ending work

- **Check what's loaded** with `/context → List current context`
  - Know what the AI can see

- **Use selective loading**
  - Don't load everything - just what you need today

### ❌ Don't

- **Don't assume files are saved**
  - In-memory ≠ persistent
  - Explicitly save if you want to keep context

- **Don't load everything always**
  - Too much context = slower, more expensive
  - Be selective

- **Don't forget to update persistent context**
  - If you add important files, save them for next time

---

## Troubleshooting

### "I loaded files but /context shows nothing"

**Problem:** Looking at wrong context type

**Solution:**
```bash
/context → List current context (in-memory)  # ← Use this one
# NOT "Show persistent context"
```

**Explanation:** When you load files at startup, they go to **in-memory** context. Persistent context shows what's saved to disk, not what's currently active.

---

### "My files from yesterday are gone"

**Problem:** Files were in memory but not saved to persistent state

**Solution:** Next time, before closing AIWB:
```bash
/context → Save in-memory context to persistent state
```

**Explanation:** In-memory context is temporary. You must explicitly save to make it persistent.

---

### "Too many files in my persistent context"

**Problem:** Accumulated files over time

**Solution:**
```bash
# Option 1: Clear and start fresh
/contextclear

# Option 2: Selective loading
# At startup, only select the files you actually need
# Then save that smaller set:
/context → Save in-memory context to persistent state
```

---

### "Which files are included in my AI prompts?"

**Answer:** Only files in **in-memory context**

**Check with:**
```bash
/context → List current context (in-memory)
```

**Remember:**
- Persistent context = saved for later
- In-memory context = active right now

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│  IN-MEMORY CONTEXT           PERSISTENT CONTEXT         │
│  (Temporary)                 (Saved)                    │
├─────────────────────────────────────────────────────────┤
│  📍 Where: RAM               📍 Where: Disk             │
│  ⏱️  Lasts: This session     ⏱️  Lasts: Forever         │
│  🎯 Use: Active work         🎯 Use: Save for later     │
│  👁️  View: List current      👁️  View: Show persistent  │
│  ✨ Effect: In AI prompts    ✨ Effect: Available later │
└─────────────────────────────────────────────────────────┘

Flow:
  Persistent → Load → In-Memory → Use in AI → Save → Persistent
     💾                 🔄          🤖          💾
```

---

## Summary

- **In-Memory** = What's on your desk right now
- **Persistent** = What's in your filing cabinet

- **Load files at startup** → They go to in-memory (active)
- **Add files during session** → They go to in-memory (not saved)
- **Save before closing** → In-memory → Persistent (for next time)

- **Check `/context → List current context`** to see what the AI can see
- **Check `/context → Show persistent context`** to see what's saved

**Golden Rule:** If the AI needs to see it, it must be in **in-memory context**.

---

For more help:
- `/help` - General AIWB commands
- `/context` - Context management menu
- `docs/USAGE.md` - Full usage guide
