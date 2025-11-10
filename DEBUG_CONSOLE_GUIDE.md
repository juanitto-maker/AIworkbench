# AIWB Debug Console Guide

## Quick Start

The debug console is a **non-blocking**, **quick** debugging tool that checks all app functionality and exits cleanly.

```bash
./debug_aiwb.sh
```

**Features:**
- ✅ Runs in 10-30 seconds
- ✅ Exits cleanly to prompt (no hanging!)
- ✅ Shows clear pass/fail for each check
- ✅ Saves detailed log
- ✅ Works without API keys (basic checks)

---

## What It Tests

### 1. Basic Information
- ✅ Version check
- ✅ Platform detection
- ✅ Termux detection

### 2. Workspace Structure
- ✅ All required directories exist
- ✅ Workspace is accessible
- ✅ Tasks, logs, templates present

### 3. Configuration
- ✅ Config file exists
- ✅ Provider configured
- ✅ Model configured (checks for deprecated models!)
- ✅ Workspace path is valid

### 4. API Keys
- ✅ Checks all providers
- ✅ Environment variables
- ✅ .aiwb.env file

### 5. Quick Functionality Test (if API keys present)
- ✅ Basic chat response
- ✅ API connectivity
- ✅ Error detection

---

## Example Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AIWB Debugging Console
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

▶ Basic Information
✓ Version: AIWB v2.0.0
  Platform: Linux
  Termux: Yes

▶ Workspace Structure
✓ Config exists: /data/data/com.termux/files/home/.aiwb/config.json
  Configured workspace: /data/data/com.termux/files/home/.aiwb/workspace
✓ Directory exists: workspace
✓ Directory exists: projects
✓ Directory exists: tasks
✓ Directory exists: logs
✓ Directory exists: templates

▶ Configuration Check
✓ Provider: gemini
⚠ Model '2.0-pro' - consider 2.5-flash (faster, cheaper)
✓ Workspace accessible: /data/data/com.termux/files/home/.aiwb/workspace

▶ API Keys Check
✓ GEMINI: Set in environment
ℹ ANTHROPIC: Not configured
ℹ OPENAI: Not configured

▶ Quick Functionality Test
ℹ Testing basic chat (10 second timeout)...
✓ Chat responds successfully

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Tests Run: 15
Passed:    14
Failed:    0

✓ All checks passed!

ℹ Full debug log saved to:
  aiwb_debug_20251110_112233.log

ℹ Exiting debug console...
```

---

## If Issues Are Found

The console will show specific recommendations:

```
⚠ Some issues need attention

Issues Found:
  • Missing directory: /path/to/workspace/logs
  • Model '1.5-flash' is DEPRECATED - use 2.5-flash or 2.0-flash
  • Workspace NOT accessible: /nonexistent/path

Recommended Actions:
  1. Initialize workspace: ./aiwb chat
  2. Update model: ./aiwb settings
  3. Configure API keys: ./aiwb keys
```

---

## Differences from Full Test Script

| Feature | Debug Console | Full Test (`test_aiwb_functionality.sh`) |
|---------|---------------|------------------------------------------|
| **Duration** | 10-30 seconds | 2-10 minutes |
| **Blocking** | Never blocks | May block on errors |
| **Exit** | Always exits cleanly | Sometimes hangs |
| **Purpose** | Quick health check | Comprehensive API testing |
| **API Testing** | Basic connectivity only | Full workflow testing |
| **Best for** | Quick debugging | Deep issue investigation |

---

## When to Use Each Tool

### Use Debug Console When:
- ✅ Quick check if app is working
- ✅ After git pull / update
- ✅ Testing workspace initialization
- ✅ Checking configuration
- ✅ Need results fast
- ✅ On Termux (won't hang!)

### Use Full Test Script When:
- ⏱️ Deep investigation needed
- ⏱️ Testing all providers/models
- ⏱️ Checking workflow issues
- ⏱️ Debugging API responses
- ⏱️ You have time to wait

---

## Troubleshooting

### "Command not found"
```bash
chmod +x debug_aiwb.sh
./debug_aiwb.sh
```

### Still hangs?
Press `Ctrl+C` - it will exit cleanly.

### Want more details?
Check the log file:
```bash
cat aiwb_debug_*.log
```

### Need deeper testing?
Use the full test script:
```bash
export GEMINI_API_KEY="your-key"
./test_aiwb_functionality.sh
```

---

## Quick Commands

```bash
# Run debug console
./debug_aiwb.sh

# View last log
cat aiwb_debug_*.log | tail -50

# Clean up old logs
rm aiwb_debug_*.log

# Run with specific checks only
# (edit the script to comment out sections you don't need)
```

---

## Exit Guarantee

This script **GUARANTEES** to exit cleanly:

1. ✅ Trap for Ctrl+C
2. ✅ Kills all background jobs
3. ✅ Timeouts on all tests
4. ✅ `exit 0` at the end
5. ✅ No interactive prompts that wait

**You will NEVER need to force-stop Termux with this tool!**

---

## Integration with Development

### After Making Code Changes
```bash
git pull
./debug_aiwb.sh  # Quick sanity check
```

### Before Reporting Bugs
```bash
./debug_aiwb.sh > debug_output.txt 2>&1
# Share debug_output.txt
```

### Regular Health Checks
```bash
# Add to your workflow
./debug_aiwb.sh && echo "All good!" || echo "Need fixes"
```

---

That's it! Fast, clean, no hanging! 🚀
