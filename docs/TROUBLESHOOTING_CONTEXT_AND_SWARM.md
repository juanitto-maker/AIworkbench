# Troubleshooting Guide: Context Persistence and Swarm Mode

## Quick Diagnostics

### Check Context Status
```bash
# Start AIWB
aiwb

# Check what's saved in persistent context
> /contextshow

# Check what's loaded in current session
> /context
# Select: "List current in-memory context"
```

### Check Swarm Mode Status
```bash
# Open swarm menu
> /swarm

# You should see:
# - Current status (ENABLED or DISABLED)
# - Strategy (auto/mapreduce/hierarchical)
# - Worker configuration
# - Minimum token threshold
```

## Common Issues and Solutions

### Issue 1: "Context: none (saved: 19 files)"

**What it means:**
- ✅ Good news: 19 files ARE saved in persistent context
- ⚠️ Issue: They're not loaded into current session yet

**Why this happens:**
- You declined the startup resume prompt
- Startup prompt didn't appear (rare)
- You started a new session

**Solution:**
```bash
> /contextload
```

This loads all saved files into your current session. Now you'll see:
```
Context: 19 files loaded
```

**To prevent this in the future:**
- When AIWB starts, accept the "Resume with previous context?" prompt
- Or use `/contextload` manually when needed

### Issue 2: Swarm Mode Enabled But Not Showing Agents

**What it means:**
- ✅ Swarm mode is enabled in settings
- ⚠️ But your prompt is too small to trigger parallel processing

**Why this happens:**
Swarm mode only activates when your prompt is large enough (default: 100 tokens minimum).

Small prompt example:
```
User: audit the app
Estimated: ~15 tokens → TOO SMALL → Falls back to standard mode
```

Large prompt example:
```
User: analyze all 19 files in context and provide architectural recommendations
Estimated: ~2500 tokens → LARGE ENOUGH → Swarm mode activates!
```

**Solution Option 1: Use Larger Prompts**
Load context first to naturally create larger prompts:
```bash
# Load your saved files
> /contextload

# Now ask questions that need to analyze all files
> /make
> analyze the entire codebase architecture and suggest improvements

# This creates a large prompt (19 files + your question) → triggers swarm
```

**Solution Option 2: Force Swarm Mode (For Testing)**
```bash
> /swarm
# Select: "Set minimum token threshold"
# Select: "Force swarm mode (ignore token count)"

# OR set very low threshold:
# Select: "100 tokens - Very low threshold ⭐ RECOMMENDED FOR TESTING"

# Now even small prompts trigger swarm:
> /make
> hello world

# You'll see:
# 🐝 Swarm Mode Execution
# ━━━ Phase 1: Parallel Processing ━━━
# 🤖 Worker 1: Processing...
# ✓ Worker 1: Complete
# ...
```

**Solution Option 3: Check Your Config**
```bash
# Check if swarm is actually enabled
> /swarm

# If it says "DISABLED", enable it:
# Select: "Toggle swarm mode ON/OFF"
```

### Issue 3: Swarm Shows "⚠ Prompt too small for swarm mode"

**What it means:**
- ✅ Swarm is enabled and working
- ⚠️ Your specific prompt didn't meet the minimum token threshold

**Example output:**
```
⚠ Prompt too small for swarm mode (estimated 15 tokens < 100 threshold)
💡 Tip: Use '/swarm' menu to enable Force mode or lower the threshold
```

**Solution:**
Follow the tip in the message:
```bash
> /swarm
# Select: "Set minimum token threshold"
# Select: "Force swarm mode (ignore token count)"
```

Or load more context to make your prompts naturally larger:
```bash
> /contextload  # Load the saved files
```

### Issue 4: Config Not Persisting Across Sessions

**What it means:**
- You enable swarm mode
- Exit AIWB
- Restart AIWB
- Swarm is disabled again

**Why this happens:**
- Config file doesn't exist: `~/.aiwb/config.json`
- Or config file is corrupted

**Solution:**
```bash
# Check if config exists
ls -la ~/.aiwb/config.json

# If it doesn't exist, create it manually:
mkdir -p ~/.aiwb
cat > ~/.aiwb/config.json <<'EOF'
{
  "swarm": {
    "enabled": "true",
    "strategy": "auto",
    "worker_provider": "gemini",
    "worker_model": "2.5-flash",
    "aggregator_provider": "claude",
    "aggregator_model": "sonnet-4-5-20250929",
    "workers": "5",
    "min_tokens": "100",
    "force": "false"
  }
}
EOF
chmod 600 ~/.aiwb/config.json

# Now restart AIWB and swarm will be enabled
```

## Understanding Context Levels

AIWB has **two levels** of context:

### 1. Persistent Context (Saved to Disk)
- **Location:** `~/.aiwb/workspace/.context_state`
- **Lifetime:** Survives session exit, persists forever
- **Commands:** `/contextsave`, `/contextshow`, `/contextclear`
- **View:** Run `/contextshow` to see what's saved

### 2. In-Memory Context (Active in Session)
- **Location:** `MODE_UPLOADS[]` array in memory
- **Lifetime:** Only while AIWB is running
- **Commands:** `/context`, `/contextload`
- **View:** Run `/context` → "List current in-memory context"

### Context Flow Diagram
```
┌─────────────────────────────────────────────────┐
│         Persistent Context (Disk)               │
│   ~/.aiwb/workspace/.context_state              │
│   ✓ 19 files saved here                         │
└───────────────────┬─────────────────────────────┘
                    │
                    │ /contextload
                    ↓
┌─────────────────────────────────────────────────┐
│      In-Memory Context (RAM)                    │
│   MODE_UPLOADS[] array                          │
│   ✗ Empty on startup (needs manual load)       │
│   ✓ After /contextload: 19 files               │
└───────────────────┬─────────────────────────────┘
                    │
                    │ Included in every AI call
                    ↓
┌─────────────────────────────────────────────────┐
│         API Request to AI Model                 │
│   Prompt + 19 files → Large context             │
│   → Swarm mode activates!                       │
└─────────────────────────────────────────────────┘
```

## Understanding Swarm Mode Activation

### Token Estimation
AIWB estimates tokens using this rough formula:
```
tokens ≈ characters / 4
```

Examples:
- "hello" → ~1 token
- "audit the app" → ~3 tokens (12 chars / 4)
- 100-line file → ~500 tokens
- 19 files × 500 tokens each → ~9500 tokens

### Activation Logic
```
IF swarm.enabled = true:
    IF swarm.force = true:
        ✓ Activate swarm (always)
    ELSE IF estimated_tokens < swarm.min_tokens:
        ✗ Fall back to standard mode
        Show: "⚠ Prompt too small"
    ELSE:
        ✓ Activate swarm
ELSE:
    ✗ Use standard mode (swarm disabled)
```

### Visual Indicators (When Swarm Activates)
```
🐝 Swarm Mode Execution

━━━ Phase 1: Parallel Processing ━━━
Processing 5 chunks with 5 parallel workers

  → Launched worker 1/5
  → Launched worker 2/5
  🤖 Worker 1: Processing...
  🤖 Worker 2: Processing...
  ✓ Worker 1: Complete
  ✓ Worker 2: Complete
  ...

⏳ Waiting for all workers to complete...
✓ All workers finished!

✓ Phase 1 complete: 5 chunks processed

━━━ Phase 2: Aggregation ━━━
Synthesizing results with claude/sonnet-4-5-20250929

  → Collected chunk 1/5
  → Collected chunk 2/5
  ...

🧠 Aggregating with claude...

✓ Phase 2 complete: Results aggregated

[Final aggregated response appears here]
```

## Step-by-Step Testing Guide

### Test 1: Verify Context Persistence Works
```bash
# Step 1: Check saved context
aiwb
> /contextshow

# Expected output:
# ╔══════════════════════════════════════╗
# ║     PERSISTENT CONTEXT STATE         ║
# ╚══════════════════════════════════════╝
#
# Session ID: ...
# Created: ...
# Files: 19
# [List of 19 files]

# Step 2: Load into memory
> /contextload

# Expected output:
# ✓ Loaded 19 files into context
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   Context loaded: ~9500 tokens
#   Estimated cost per use: ~$0.05 USD
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Step 3: Verify in status line
# Status should now show:
# Context: 19 files | Cost: $0.00 | Model: ...

✓ Test PASSED if you see 19 files loaded
```

### Test 2: Verify Swarm Mode Activates
```bash
# Step 1: Enable swarm with force mode
> /swarm
# Select: "Toggle swarm mode ON/OFF" (if disabled)
# Select: "Set minimum token threshold"
# Select: "Force swarm mode (ignore token count)"

# Step 2: Test with simple prompt
> /make
> create a hello world function

# Expected output:
# 🐝 Swarm Mode Execution
# [... visual indicators as shown above ...]

✓ Test PASSED if you see Phase 1 and Phase 2 with worker emojis
```

### Test 3: Verify Natural Swarm Activation (Recommended)
```bash
# Step 1: Enable swarm with 100 token threshold
> /swarm
# Select: "Set minimum token threshold"
# Select: "100 tokens - Very low threshold ⭐ RECOMMENDED FOR TESTING"

# Step 2: Load context (creates large prompt)
> /contextload

# Step 3: Ask complex question
> /make
> analyze all loaded files and describe the overall architecture

# Expected output:
# 🐝 Swarm Mode Execution
# DEBUG: Estimated tokens: 9523
# Strategy: mapreduce
# [... Phase 1 and Phase 2 ...]

✓ Test PASSED if swarm activates naturally due to large prompt
```

## When to Use Context vs Swarm

### Use Context Persistence When:
- ✅ Working on a project over multiple sessions
- ✅ You want AI to remember your codebase structure
- ✅ You need consistent context across different modes (/make, /debug, /tweak)
- ✅ You want to save token costs by reusing scanned files

### Use Swarm Mode When:
- ✅ Your prompts are very large (> 1000 tokens naturally, or > 100 for testing)
- ✅ You want parallel processing for faster responses
- ✅ You're analyzing large codebases (many files loaded in context)
- ✅ You want to test distributed AI agent workflows

### Use Both Together (Recommended):
```bash
# 1. Load persistent context
> /contextload      # Loads 19 files → ~9500 tokens

# 2. Enable swarm mode
> /swarm
# Enable swarm, set threshold to 100 tokens

# 3. Ask complex question
> /make
> suggest architectural improvements across all files

# Result:
# - Large context (19 files) → Creates large prompt
# - Large prompt → Triggers swarm automatically
# - Swarm splits work across 5 workers
# - Each worker analyzes ~4 files in parallel
# - Aggregator synthesizes final recommendation
# - ⚡ Much faster than sequential processing!
```

## Still Having Issues?

### Enable Debug Mode
Look for DEBUG output when swarm is enabled:
```
DEBUG: SWARM_ENABLED=true, calling swarm_execute...
DEBUG: final_prompt length=9523, MODE_CURRENT=make
DEBUG: swarm_execute function found
DEBUG: Estimated tokens: 9523
DEBUG: Current SWARM_STRATEGY=auto
Auto-detected strategy: mapreduce
```

If you don't see this debug output, swarm mode isn't enabled.

### Check Your Environment
```bash
# 1. Check swarm library is loaded
echo $AIWB_LIB_SWARM_LOADED
# Should output: "true"

# 2. Check swarm function exists
type swarm_execute
# Should output: "swarm_execute is a function"

# 3. Check config file
cat ~/.aiwb/config.json | grep -A 10 swarm
# Should show swarm configuration
```

### Common Mistakes

❌ **Mistake:** Enabling swarm but using small prompts without force mode
```bash
> /swarm → Enable swarm
> /make → hello world
Result: Falls back to standard (15 tokens < 100 threshold)
```

✅ **Fix:** Either use force mode OR load context
```bash
> /contextload  # Load files first
> /make → hello world  # Now prompt is large (files + question)
Result: Swarm activates (9500+ tokens)
```

❌ **Mistake:** Loading context but not enabling swarm
```bash
> /contextload  # 19 files loaded
> /make → analyze all files
Result: Standard mode (slow, sequential processing)
```

✅ **Fix:** Enable swarm first
```bash
> /swarm → Enable swarm
> /contextload
> /make → analyze all files
Result: Swarm mode (fast, parallel processing)
```

❌ **Mistake:** Expecting auto-resume to work every time
```bash
# Session 1:
> /contextsave  # Save 19 files

# Session 2 (new terminal):
> ... prompt ...
Result: Context not loaded (declined resume prompt)
```

✅ **Fix:** Accept resume prompt or manually load
```bash
# When starting AIWB:
Resume with previous context? [Y/n] Y  ← Press Y or Enter

# Or manually load:
> /contextload
```

## Quick Reference Card

| Task | Command | Expected Result |
|------|---------|----------------|
| Check saved context | `/contextshow` | Shows 19 files in persistent state |
| Load saved context | `/contextload` | Loads 19 files into session |
| List active context | `/context` → option 2 | Shows files in MODE_UPLOADS |
| Enable swarm | `/swarm` → Toggle ON | Shows "✓ ENABLED" |
| Force swarm always | `/swarm` → Set threshold → Force mode | Swarm activates on all prompts |
| Test swarm visually | Force mode + `/make` + any prompt | Shows 🤖 worker indicators |
| Natural swarm trigger | Load context + complex question | Swarm auto-activates (large prompt) |
| Save current context | `/contextsave` | Saves MODE_UPLOADS to disk |
| Clear all context | `/contextclear` | Removes both persistent and in-memory |

## Summary

**For Context Persistence:**
- ✅ System is working correctly
- ✅ Just need to run `/contextload` to load saved files
- ✅ Or accept the resume prompt on startup

**For Swarm Mode:**
- ✅ Fixed: Default threshold lowered from 1000 → 100 tokens
- ✅ Fixed: Better error messages explain why swarm didn't activate
- ✅ Fixed: Menu now recommends 100 token threshold for testing
- ✅ Use force mode for testing with any prompt size
- ✅ Use context + swarm together for best results

**Recommended Workflow:**
```bash
# Start AIWB
aiwb

# Accept resume prompt (or run /contextload)
Resume with previous context? [Y/n] Y

# Enable swarm with low threshold
> /swarm
→ Enable swarm
→ Set threshold to 100 tokens (or force mode)

# Now use normally - swarm will activate automatically on larger prompts
> /make
> [your question about the codebase]

# You'll see the swarm workers in action! 🐝
```
