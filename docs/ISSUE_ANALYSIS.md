# Issue Analysis: Context Persistence and Swarm Mode

## User-Reported Issues

1. **Context persistence**: Shows "Context: none (saved: 19 files - use /contextload)" but user expects files to be auto-loaded
2. **Swarm mode**: Enabled but not showing agent visual indicators during execution

## Root Cause Analysis

### Issue 1: Context Persistence
**Status**: ✅ Working as designed, but UX could be improved

**How it works:**
- Context persistence has two levels:
  - **Persistent Context**: Saved to `~/.aiwb/workspace/.context_state` (19 files stored here)
  - **In-Memory Context**: Active in current session via `MODE_UPLOADS[]` array (currently empty)
- On startup (lines 300-354 in `aiwb`), user is prompted to resume previous context
- User must explicitly load context with `/contextload` or by accepting the startup prompt
- The status message "saved: 19 files - use /contextload" is correct and informative

**Why user sees this:**
- User either:
  - Declined the startup resume prompt
  - Startup prompt didn't show (possible bug in mobile terminal environment)
  - Started a new session without resuming

**Not actually broken** - just needs user action to run `/contextload`

### Issue 2: Swarm Mode Not Showing Agents
**Status**: ⚠️ Configuration and threshold issue

**Root Causes:**
1. **No config file exists**: `~/.aiwb/config.json` doesn't exist
   - Even if swarm is enabled in session, it won't persist
   - Defaults to SWARM_ENABLED=false on next startup

2. **Swarm activation threshold too high for test prompts**:
   - Current default: `SWARM_MIN_TOKENS=1000`
   - User's prompt "audit the app" is ~15-20 tokens
   - Swarm auto-detect logic:
     ```bash
     if (( tokens < SWARM_MIN_TOKENS )); then
         echo "none"  # Fall back to standard mode
         return
     fi
     ```
   - Result: Swarm returns "none" → falls back to standard mode → no visual indicators

3. **Visual indicators only show during actual swarm execution**:
   - If swarm falls back to standard mode (line 341-344 in swarm.sh)
   - `swarm_execute()` returns exit code 1
   - `modes.sh` (line 1184) catches this and uses standard mode
   - No Phase 1/Phase 2 visual indicators are shown
   - User sees: "⚠ Context too small for swarm, using standard mode"

**Why visual indicators don't show:**
- Worker emojis (🤖) and phase headers are in `swarm_mapreduce()` (lines 420-518)
- This function only executes when `strategy = "mapreduce"`
- When tokens < SWARM_MIN_TOKENS, strategy becomes "none" and function never runs

## Technical Details

### Swarm Activation Flow
```
User prompt → mode_run() → swarm_execute() → swarm_auto_detect()
                                           ↓
                              tokens < SWARM_MIN_TOKENS?
                                   ↓ YES        ↓ NO
                              return "none"   return "mapreduce"
                                   ↓               ↓
                              Fall back to    swarm_mapreduce()
                              standard mode   (shows visual indicators)
```

### Token Estimation
```bash
# From user's screenshot: "audit the app"
estimate_tokens "audit the app" → ~15 tokens
15 < 1000 → swarm disabled → no visual indicators
```

### Recent Commits Related to This
- `2e4cbda`: "Lower swarm activation threshold for easy testing"
- `91ddb83`: "Add easy swarm testing guide"
- `f542fa6`: "Add visual indicators and integrate swarm mode into chat"

These commits suggest the team already identified this testing difficulty!

## Proposed Fixes

### Fix 1: Context Auto-Load on Startup (Optional Enhancement)
**File**: `aiwb` lines 300-354

**Option A**: Make auto-resume the default behavior
```bash
if ui_confirm "Resume with previous context?" "yes"; then
    # Load all files by default
    context_state_load_into_mode
else
    # Show file selection
    # ... existing code ...
fi
```

**Option B**: Add config option for auto-resume
```json
{
  "context": {
    "auto_resume": true
  }
}
```

### Fix 2: Lower Swarm Threshold for Testing (Recommended)
**File**: `lib/swarm.sh` line 21

**Current**:
```bash
SWARM_MIN_TOKENS=1000  # Minimum tokens to activate swarm (lowered for easy testing)
```

**Proposed**:
```bash
SWARM_MIN_TOKENS=100  # Minimum tokens to activate swarm (very low for easy testing)
```

**Why**: Allows testing with small prompts like "audit the app"

### Fix 3: Better Fallback Messaging
**File**: `lib/swarm.sh` lines 341-344

**Current**:
```bash
none)
    echo "⚠ Context too small for swarm, using standard mode" >&2
    echo "DEBUG: Returning 1 to fall back to standard execution" >&2
    return 1
    ;;
```

**Proposed**:
```bash
none)
    echo "⚠ Prompt too small for swarm mode (${tokens} tokens < ${SWARM_MIN_TOKENS} threshold)" >&2
    echo "💡 Tip: Use '/swarm' menu to enable Force mode or lower the threshold" >&2
    echo "DEBUG: Returning 1 to fall back to standard execution" >&2
    return 1
    ;;
```

### Fix 4: Ensure Config File Creation
**File**: `aiwb` or `lib/config.sh`

Add initialization to create `~/.aiwb/config.json` with defaults if it doesn't exist:
```bash
init_config_file() {
    local config_file="$HOME/.aiwb/config.json"
    if [[ ! -f "$config_file" ]]; then
        mkdir -p "$(dirname "$config_file")"
        cat > "$config_file" <<'EOF'
{
  "swarm": {
    "enabled": "false",
    "strategy": "auto",
    "worker_provider": "gemini",
    "worker_model": "2.5-flash",
    "aggregator_provider": "claude",
    "aggregator_model": "sonnet-4-5-20250929",
    "workers": "5",
    "min_tokens": "100",
    "force": "false"
  },
  "context": {
    "auto_resume": "false"
  }
}
EOF
        chmod 600 "$config_file"
    fi
}
```

## Testing Steps for User

### Test Context Persistence
```bash
# 1. Check what's saved
aiwb
> /contextshow

# 2. Load the saved context
> /contextload

# 3. Verify it's loaded
> /context
# Select option 2: "List current in-memory context"

# 4. Now context should show in status line as:
# "Context: 19 files"
```

### Test Swarm Mode
```bash
# 1. Enable swarm mode
aiwb
> /swarm
# Select: Enable swarm mode

# 2. Set very low threshold for testing
> /swarm
# Select: "Set minimum token threshold"
# Select: "100 tokens - Always activate (for testing)"
# OR
# Select: "Force swarm mode (ignore token count)"

# 3. Test with a simple prompt
> /make
> create a hello world function

# 4. You should now see:
# 🐝 Swarm Mode Execution
# ━━━ Phase 1: Parallel Processing ━━━
# 🤖 Worker 1: Processing...
# ✓ Worker 1: Complete
# ━━━ Phase 2: Aggregation ━━━
# 🧠 Aggregating with claude...
# ✓ Phase 2 complete
```

### Test with Larger Prompt (Natural Trigger)
```bash
# Load a large codebase into context
> /contextload  # Load those 19 files
> /scanrepo     # Or scan the repo

# Now ask a question that requires analyzing all files
> /make
> analyze the entire codebase and suggest architectural improvements

# This should naturally trigger swarm mode (large prompt > 1000 tokens)
```

## Recommendations

### Immediate Actions (High Priority)
1. ✅ **Run `/contextload`** to load the 19 saved files into active session
2. ✅ **Enable swarm mode** with force flag or 100 token threshold via `/swarm` menu
3. ✅ **Test with the loaded context** to generate larger prompts that naturally trigger swarm

### Code Fixes (For Development Team)
1. 🔧 **Lower default SWARM_MIN_TOKENS** from 1000 to 100 (easy testing)
2. 🔧 **Initialize config.json** on first run with sensible defaults
3. 🔧 **Improve swarm fallback messaging** to explain why swarm didn't activate
4. 💡 **Optional**: Add context auto-resume config option

### Documentation Updates
1. 📖 Add troubleshooting section: "Why isn't swarm mode showing workers?"
2. 📖 Add context persistence guide: "Understanding in-memory vs persistent context"
3. 📖 Update swarm testing guide with token count examples

## Summary

| Issue | Root Cause | Status | Fix |
|-------|-----------|--------|-----|
| Context not loaded | Working as designed; user needs to run `/contextload` | ✅ Not broken | User action: run `/contextload` |
| Swarm not showing agents | Prompt too small (< 1000 tokens) | ⚠️ Threshold too high | Code fix: Lower SWARM_MIN_TOKENS to 100 |
| Config not persisting | No config file created | ⚠️ Missing init | Code fix: Auto-create config.json |

**Quick Fix for User Right Now:**
```bash
aiwb
> /contextload           # Load the 19 files
> /swarm                 # Open swarm menu
> Enable swarm mode      # Toggle ON
> Set minimum token threshold → Force swarm mode (ignore token count)
> /make                  # Now test with any prompt
> hello world            # Even this small prompt will trigger swarm
```
