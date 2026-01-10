# Critical Fixes - January 10, 2026

## 🐛 Bug #1: Context Persistence Broken (FIXED)

### Symptoms
- Run `/scanrepo` → shows "Context saved for future use"
- Run `/context` → shows "0 saved"
- Run `/contextload` → "No files to load"
- **No files were actually saved!**

### Root Cause
The `/scanrepo` and `/smartscan` commands were:
1. ✅ Scanning source files correctly
2. ✅ Creating AI analysis
3. ✅ Saving analysis file path to context_state
4. ❌ **NOT saving the scanned source files to context_state**

When you ran `/contextload`, it tried to load files from `context_files` array, but that array only contained the analysis.md file, not the actual source files!

### Fix Applied
Modified `build_repo_context()` in `aiwb` script:
- Added `SCANNED_FILES` global array to track files as they're scanned
- Each time a file is added to context, its path is saved to `SCANNED_FILES`
- After scan completes, all files in `SCANNED_FILES` are saved to `context_state`

Modified `cmd_scanrepo()` and `cmd_smartscan()`:
- After calling `context_state_save_scan()`, now also loops through `SCANNED_FILES`
- Calls `context_state_add_file()` for each scanned source file
- New message: "Context saved: X source files + analysis"

Modified `cmd_context()`:
- Changed count logic from only `type == "manual"` to count ALL files
- Now `scan`-type files are included in the count

### How to Test
```bash
# 1. Run a scan
cd /your/project
aiwb
> /scanrepo
# Should now show: "Context saved: 15 source files + analysis"

# 2. Check context
> /context
# Should show: "0 in-memory, 15 saved"

# 3. Exit and restart
> /exit
> yes

# 4. Start aiwb again
aiwb
> /contextload
# Should now load all 15 files!

# 5. Verify
> /context
> List current context (in-memory)
# Should show all 15 files loaded
```

### Files Changed
- `aiwb` (lines 1465, 1501, 1529, 1546, 1564, 1687-1692, 1798-1803, 2198-2199)
- `lib/context_state.sh` (previous fix for undefined variable)

---

## 🐝 Issue #2: Swarm Mode Not Activating (User Confusion)

### Symptoms
- User enables swarm via `/swarm`
- User types: "use swarm mode to analyse the app"
- AI responds about **Docker Swarm** (wrong!)
- **No AIWB swarm workers shown**

### Root Cause
This is NOT a bug - it's a **UX/documentation issue**:

1. **Swarm only activates in MODES, not in chat:**
   - ✅ Works in: `/make`, `/tweak`, `/debug`
   - ❌ Doesn't work in: regular chat messages

2. **User typed a chat message:**
   ```
   User: "use swarm mode to analyse the app"
   ```
   This went to regular chat → sent to Gemini → Gemini thought they meant Docker Swarm!

3. **Swarm mode requires both:**
   - Swarm is enabled (✅ user did this)
   - Using a mode workflow (❌ user was in chat)
   - Prompt exceeds token threshold

### How Swarm ACTUALLY Works

#### To Use Swarm for Analysis:

**Method 1: Use /make mode**
```bash
# 1. Enable swarm
> /swarm
→ Select "Enable swarm"
→ Back

# 2. Add context (makes prompt large)
> /scanrepo

# 3. Use /make mode with analysis request
> /make
> prompt: "Analyze this codebase for improvements"
> run

# NOW you'll see swarm workers:
🐝 Swarm Mode Execution
━━━ Phase 1: Parallel Processing ━━━
Processing 5 chunks with 5 parallel workers
  🤖 Worker 1: Processing...
  🤖 Worker 2: Processing...
  ...
```

**Method 2: Enable force mode for testing**
```bash
# Force swarm even for small prompts
> /swarm
→ "Min tokens: 100"
→ Enable force mode
→ "Enable swarm"

# Now even small prompts trigger swarm
> /make
> prompt: "test"
> run
# Will show swarm workers even for tiny prompt
```

#### What Swarm Does

**Swarm Activates When:**
1. ✅ Swarm is enabled (`/swarm` menu)
2. ✅ You're in a mode (`/make`, `/tweak`, `/debug`)
3. ✅ Prompt exceeds token threshold (100 tokens default)

**Swarm Does NOT Activate:**
- ❌ In regular chat messages
- ❌ For small prompts (< 100 tokens)
- ❌ When swarm is disabled

**When Swarm Runs, You See:**
```
🐝 Swarm Mode Execution

━━━ Phase 1: Parallel Processing ━━━
Processing 3 chunks with 5 parallel workers

  → Launched worker 1/3
  🤖 Worker 1: Processing...
  ✓ Worker 1: Complete

━━━ Phase 2: Aggregation ━━━
Synthesizing results with claude/sonnet-4-5-20250929

[Final aggregated answer]
```

### Why the Confusion Happened

1. **User enabled swarm** → ✅ Correct
2. **User typed in chat:** "use swarm mode to analyse the app"
   - This went to regular chat handler
   - Not to `/make` mode where swarm activates
3. **Gemini responded about Docker Swarm**
   - Because it saw "swarm mode" and "app"
   - Assumed Docker container orchestration
4. **No AIWB swarm workers shown**
   - Because swarm never activated (not in a mode!)

### The Fix: Better Documentation

**Updated docs:**
- `docs/SWARM_MODE_GUIDE.md` - comprehensive guide
- `docs/CRITICAL_FIXES.md` - this file
- `COMPREHENSIVE_TEST_REPORT.md` - test results

**Key takeaways for users:**
- 🔴 **Swarm ≠ chat** - it only works in modes
- 🟢 **To use swarm:** Enable it, add context, use `/make` or `/tweak`
- 🟡 **Chat messages go to AI** - they don't trigger swarm
- 🔵 **Check `/status`** - verify swarm shows "🐝 ON"

---

## 📋 Summary of All Fixes

### This Commit Fixes:
1. ✅ **Context persistence** - scanned files now save properly
2. ✅ **Context count** - shows scan files in count
3. ✅ **Clear messages** - "X source files + analysis" feedback
4. ✅ **Documentation** - explains when swarm activates

### Previous Commits Fixed:
1. ✅ **context_state_load_into_mode()** - undefined variable bug
2. ✅ **context_state_save_from_mode()** - undefined variable bug

### Remaining (Not Bugs):
1. ℹ️ **Swarm in chat** - working as designed, documented
2. ℹ️ **Docker vs AIWB swarm** - AI confusion, can't fix

---

## 🧪 Testing Checklist

### Test Context Persistence
- [ ] Run `/scanrepo` in a project directory
- [ ] Verify message shows "X source files + analysis"
- [ ] Run `/context` → should show "0 in-memory, X saved"
- [ ] Run `/contextload` → should load all X files
- [ ] Verify `/context` → "List current context" shows all files

### Test Swarm Mode
- [ ] Run `/swarm` → Enable swarm
- [ ] Run `/status` → verify shows "🐝 ON"
- [ ] Run `/scanrepo` to add large context
- [ ] Run `/make` → prompt: "analyze this"
- [ ] Run `run` → should see swarm workers processing
- [ ] Verify output shows "Phase 1" and "Phase 2"

### Test Swarm Force Mode (Optional)
- [ ] Run `/swarm` → Min tokens → Enable force mode
- [ ] Run `/make` → prompt: "test" (tiny prompt)
- [ ] Run `run` → should see swarm even for small prompt

---

## 🚀 How to Get These Fixes

### If Using Install Script
```bash
# After this PR is merged to main:
curl -fsSL https://raw.githubusercontent.com/juanitto-maker/AIworkbench/main/install-termux.sh | bash
```

### If Using Git Clone
```bash
cd ~/AIworkbench  # or wherever you cloned it
git pull origin claude/comprehensive-app-testing-0HHWH
```

### Manual Update
```bash
# Copy just the aiwb script:
curl -o ~/.local/bin/aiwb https://raw.githubusercontent.com/juanitto-maker/AIworkbench/claude/comprehensive-app-testing-0HHWH/aiwb
chmod +x ~/.local/bin/aiwb
```

---

## ⚠️ Breaking Changes
**None** - these fixes are backwards compatible.

## 📞 Need Help?
See:
- `docs/SWARM_MODE_GUIDE.md` - Complete swarm guide
- `COMPREHENSIVE_TEST_REPORT.md` - Full test results
- GitHub Issues: https://github.com/juanitto-maker/AIworkbench/issues
