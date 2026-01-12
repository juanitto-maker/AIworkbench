# Context Loading Guide: Understanding Startup Prompts

## What Happens When You Start AIWB

When you start AIWB and there's existing context from a previous session, you'll see this prompt:

```
⚠ Found context from previous session (6 days ago)

This context includes saved files from /scanrepo, /smartscan, or manual adds.

What would you like to do?
  1) Resume - Load previous context files
  2) Clear - Delete old context and start fresh
  3) Skip - Start with empty context (keep old context for later)

Choose [1/2/3] (default: 3):
```

## Understanding Your Options

### Option 1: Resume - Load Previous Context Files

**When to use:**
- You want to continue working with the same files you analyzed before
- The scanned files are still relevant to your current work
- You're resuming work on the same project

**What happens:**
- AIWB shows you a list of all saved context files
- Each file displays its age (e.g., "today", "yesterday", "6d ago", "2w ago")
- You can select which files to load using space bar (toggle) and enter (confirm)
- "Select All" option loads everything at once

**File age indicators help you decide:**
- `(today)` - Very recent, likely still relevant
- `(yesterday)` - Recent, probably still useful
- `(6d ago)` - Almost a week old, might be stale
- `(2w ago)` - Two weeks old, likely outdated

### Option 2: Clear - Delete Old Context and Start Fresh

**When to use:**
- The old context files are outdated or no longer needed
- You're starting work on a different project
- You want to clean up and rebuild context from scratch

**What happens:**
- AIWB deletes the `.context_state` file
- All references to old scan outputs are removed
- You start with a completely clean slate
- You can then run `/scanrepo` or `/smartscan` to build new context

**Best practice:**
- Use this option if context is more than 2 weeks old
- Use this when switching between different projects
- Use this to fix issues with corrupted or incorrect context

### Option 3: Skip - Start with Empty Context (Default)

**When to use:**
- You're not sure if you need the old context yet
- You want to work on something quick without loading large context
- You prefer to manually load context later if needed

**What happens:**
- AIWB starts with empty context
- The old `.context_state` file remains saved on disk
- You can load it later using `/contextload` command
- You can clear it later using `/contextclear` command

**This is the safest option because:**
- No data is deleted
- No context is loaded automatically (saves tokens/cost)
- You have full control over when/what to load

## Understanding Context Files

### What Gets Saved to Context

Context files include:

1. **Scan outputs** from `/scanrepo` command
   - Example: `workspace/outputs/repo_analysis_20260110_143022.md`
   - Contains AI analysis of your entire repository

2. **Smart scan outputs** from `/smartscan` command
   - Example: `workspace/outputs/smart_scan_20260110_143022.md`
   - Contains AI analysis of selected important files

3. **Manually added files** via `/context add <file>` command
   - Any files you explicitly added to context

### File Location

- **Default:** `~/.aiwb/workspace/.context_state`
- **Termux (Android):** `/storage/emulated/0/aiwb/workspace/.context_state`

The `.context_state` file is a JSON file that tracks:
- Session ID and timestamps
- List of context files and their types
- Last scan information
- Conversation history

## Commands for Managing Context

### View Current Context
```bash
/contextshow
```
Shows what's currently saved in persistent context state.

### Load Saved Context
```bash
/contextload
```
Manually load context from `.context_state` file. Same as choosing option 1 at startup.

### Clear All Context
```bash
/contextclear
```
Delete all context (persistent and in-memory). Same as choosing option 2 at startup.

### Save Current Context
```bash
/contextsave
```
Save current in-memory context to persistent `.context_state` file.

### Remove Specific File
```bash
/contextremove
```
Remove a specific file from context without clearing everything.

## Best Practices

### 1. Regular Cleanup
- Clear old context weekly: `/contextclear`
- Rebuild context for active projects: `/scanrepo`

### 2. Context Age Guidelines
- **0-2 days old:** Usually still relevant, safe to load
- **3-7 days old:** Check if files changed, may need refresh
- **1-2 weeks old:** Likely stale, consider clearing
- **2+ weeks old:** Almost certainly outdated, clear it

### 3. Project Switching
When switching between projects:
```bash
# Clear old project context
/contextclear

# Scan new project
cd /path/to/new/project
aiwb
/scanrepo
```

### 4. Cost Optimization
- Don't load context unless you need it
- Use `/contextremove` to remove large/unnecessary files
- Clear context when done with a project

## Troubleshooting

### "I see many old files I don't need"

**Solution:**
Choose option 2 (Clear) at startup, then rebuild fresh context:
```bash
/scanrepo
```

### "I accidentally cleared context I wanted"

**Prevention:**
Always choose option 3 (Skip) if unsure. This preserves the context file.

**Recovery:**
Unfortunately, if you chose option 2, the context is permanently deleted. You'll need to:
1. Run `/scanrepo` to re-analyze the repository
2. Manually re-add any files you had

### "Context loading is slow"

**Causes:**
- Too many files in context
- Very large files in context

**Solution:**
```bash
# Clear and rebuild with smaller scope
/contextclear
/smartscan  # Instead of /scanrepo (more selective)
```

### "File ages not showing correctly"

**Cause:**
The file might not exist on disk anymore, but is still referenced in `.context_state`.

**Solution:**
```bash
/contextclear
/scanrepo  # Rebuild fresh
```

## Changes in Recent Update

### What's New (2026-01-12)

1. **File Age Display**
   - Context files now show their age when selecting
   - Helps you decide which files are still relevant
   - Format: `📄 filename (6d ago)`

2. **Improved Startup Prompt**
   - Three clear options instead of yes/no
   - Better explanation of what each option does
   - Default changed to "Skip" (safer option)

3. **Better Guidance**
   - Tips shown for each option
   - Clearer messaging about what context includes
   - Commands suggested based on your choice

### Why These Changes?

**Problem:** Users were confused when seeing old context files (6+ days old) and didn't know:
- Whether to load them
- How to get rid of them
- What they were

**Solution:** Better UX that:
- Shows file ages clearly
- Offers explicit "Clear" option
- Provides guidance at each step
- Makes safe default (Skip)

## Related Documentation

- [Troubleshooting Context and Swarm](./TROUBLESHOOTING_CONTEXT_AND_SWARM.md)
- [Context Guide](../CONTEXT_GUIDE.md)
- [Usage Guide](../USAGE.md)

---

**Last Updated:** 2026-01-12
**Version:** 3.1.1
**Status:** ✅ ACTIVE
