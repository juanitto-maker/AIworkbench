# Phase 1 Testing Guide: Chat-First Smart Routing

## 🎯 What Was Implemented

**Phase 1** adds smart keyword detection to chat messages, automatically routing code change requests to the `/edit` workflow without requiring explicit slash commands.

### Changes Made:
1. ✅ Created `lib/chat_router.sh` - Smart intent detection module
2. ✅ Modified `aiwb:430` - Chat loop now uses `handle_chat_message_routed()`
3. ✅ Keyword detection for: `implement`, `add`, `create`, `fix`, `update`, `modify`, etc.

## 🧪 Testing Scenarios

### Prerequisites

1. **Set up a test repository:**
```bash
# Create a test repo
mkdir -p ~/test-aiwb-phase1
cd ~/test-aiwb-phase1
git init

# Create some sample files
cat > app.js <<'EOF'
function greet(name) {
    console.log("Hello, " + name);
}

module.exports = { greet };
EOF

cat > utils.js <<'EOF'
function add(a, b) {
    return a + b;
}

module.exports = { add };
EOF

cat > README.md <<'EOF'
# Test Project
Simple test project for AIWB Phase 1
EOF

# Commit initial files
git add .
git commit -m "Initial commit"
```

2. **Launch AIWB:**
```bash
cd ~/test-aiwb-phase1
aiwb
```

---

## Test Case 1: Keyword Detection - "Add" ✨

**Test Message:**
```
Add error handling to the greet function
```

**Expected Behavior:**
1. System detects keyword: `Add`
2. Shows: `🤖 Detected code change request. Analyzing repository...`
3. AI determines target file: `app.js`
4. Shows diff preview of changes
5. Prompts: `Apply these changes?`

**Success Criteria:**
- ✅ No need to type `/edit`
- ✅ Automatically routes to editing workflow
- ✅ Shows file being modified
- ✅ Displays diff before applying

**How to Verify:**
```bash
# After applying changes, check git diff
git diff app.js

# Should show error handling added to greet function
```

---

## Test Case 2: Keyword Detection - "Implement" 🔧

**Test Message:**
```
implement a multiply function in utils.js
```

**Expected Behavior:**
1. Detects keyword: `implement`
2. Auto-routes to `/edit` workflow
3. Targets: `utils.js`
4. Shows diff with new `multiply` function
5. Asks for confirmation

**Success Criteria:**
- ✅ Keyword detection works (lowercase)
- ✅ Specific file mentioned is targeted
- ✅ New function is added to existing file

---

## Test Case 3: Keyword Detection - "Fix" 🐛

**Test Message:**
```
Fix the concatenation in app.js to use template literals
```

**Expected Behavior:**
1. Detects keyword: `Fix`
2. Routes to edit workflow
3. Modifies `app.js` to use template literals
4. Shows diff: `"Hello, " + name` → `` `Hello, ${name}` ``

---

## Test Case 4: Question - Should Stay in Chat 💬

**Test Message:**
```
How do I add error handling in JavaScript?
```

**Expected Behavior:**
1. Detects question keyword: `How`
2. **Does NOT route to /edit**
3. Stays in regular chat mode
4. AI provides explanation (no file modification)

**Success Criteria:**
- ✅ No file modification attempt
- ✅ Response is explanatory
- ✅ No diff shown

---

## Test Case 5: Explanation Request - Chat Mode 📚

**Test Message:**
```
explain what this function does
```

**Expected Behavior:**
1. Detects: `explain`
2. Stays in chat mode
3. Provides explanation only

---

## Test Case 6: Multiple Keywords - Prioritization 🎯

**Test Message:**
```
How can I fix the error in app.js?
```

**Expected Behavior:**
1. Contains both `How` (question) and `fix` (edit)
2. Question takes priority (via `is_question()` check)
3. **Stays in chat mode**
4. Explains the error instead of modifying

**Success Criteria:**
- ✅ Questions always stay in chat, even with edit keywords
- ✅ No unwanted file modifications

---

## Test Case 7: No Repository Context ⚠️

**Test Message (run from ~/Downloads or non-git folder):**
```bash
cd ~/Downloads
aiwb
```

Then type:
```
Add a new feature to the app
```

**Expected Behavior:**
1. Detects `Add` keyword
2. Attempts to route to `/edit`
3. **Fallback:** Shows warning:
   ```
   ⚠️  Code editing requires a git repository context

   To enable repository editing:
     1. cd into your git repository
     2. Run: aiwb
     3. Or use: /repo to set repository path

   Falling back to chat mode for now...
   ```
4. Responds in chat mode instead

**Success Criteria:**
- ✅ Graceful degradation when no repo
- ✅ Helpful error message
- ✅ Doesn't crash

---

## Test Case 8: Ambiguous Request - Smart File Detection 🔍

**Test Message:**
```
update the README with better installation instructions
```

**Expected Behavior:**
1. Detects: `update`
2. Routes to `/edit`
3. AI detects target: `README.md`
4. Shows diff with improved instructions
5. Applies changes

---

## Test Case 9: Complex Multi-File Change 📁

**Test Message:**
```
Add type checking to both app.js and utils.js
```

**Expected Behavior:**
1. Detects: `Add`
2. Routes to smart_edit
3. AI determines: 2 files to modify
4. Shows changes for `app.js` and `utils.js`
5. Asks for confirmation once
6. Applies to both files

---

## Test Case 10: Slash Commands Still Work 🔧

**Test Message:**
```
/edit app.js "add JSDoc comments"
```

**Expected Behavior:**
1. Slash command takes precedence
2. Works exactly as before
3. No interference from smart routing

**Success Criteria:**
- ✅ Backward compatibility maintained
- ✅ Explicit commands override detection

---

## 🔍 Debugging & Verification

### Check Intent Detection Manually

```bash
# Test the detect_message_intent function
source lib/chat_router.sh

# Test various messages
detect_message_intent "Add error handling"          # Should return: edit
detect_message_intent "How do I add error handling" # Should return: chat
detect_message_intent "explain the code"            # Should return: chat
detect_message_intent "fix the bug"                 # Should return: edit
detect_message_intent "generate a new API"          # Should return: generate
```

### Check if Router is Loaded

```bash
# After starting aiwb, check if functions exist
type detect_message_intent
type handle_chat_message_routed

# Should show function definitions
```

### View Keyword Matching

You can add debug output to `lib/chat_router.sh` temporarily:

```bash
# In detect_message_intent(), add before each return:
echo "DEBUG: Detected intent = edit" >&2
```

---

## 📊 Success Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Keyword Detection Accuracy | >90% | 9/10 test cases route correctly |
| False Positives (questions edited) | 0% | Questions never trigger `/edit` |
| Fallback Behavior | Graceful | No crashes when no repo |
| Performance | <1s overhead | Routing adds minimal delay |
| Backward Compatibility | 100% | Slash commands still work |

---

## 🚨 Known Limitations (Phase 1)

These will be addressed in Phase 2:

1. **No repo integration for `/make`, `/tweak`, `/debug`** - They still output to files
2. **No code block parsing** - Relies on smart_edit file detection
3. **No multi-step workflows** - Single edit per message
4. **No code generation routing** - "generate" keyword doesn't fully work yet

---

## 🎉 What to Expect

After Phase 1 testing, you should be able to:

✅ Type natural requests like "add dark mode" and see file edits
✅ Ask questions like "how do I add dark mode" and get explanations
✅ Use `/edit` explicitly when you want fine control
✅ Work in any git repository
✅ Get helpful error messages when things aren't configured

---

## 🐛 Troubleshooting

### Problem: "Function not found" error

**Solution:**
```bash
# Check if chat_router.sh is loaded
ls -la lib/chat_router.sh

# Restart aiwb to reload libraries
exit
aiwb
```

### Problem: All messages go to chat, no routing

**Check:**
```bash
# Verify function exists
type handle_chat_message_routed

# Check if aiwb is using the routed version
grep "handle_chat_message_routed" aiwb
```

### Problem: Routes to /edit but says "no repo"

**Solution:**
```bash
# Ensure you're in a git repository
git status

# If not, initialize
git init

# Or use /repo command in aiwb
> /repo
```

---

## 📝 Test Results Template

Copy this to track your testing:

```
PHASE 1 TEST RESULTS
====================

Test Case 1 (Add keyword):        [ ] PASS  [ ] FAIL  Notes: __________
Test Case 2 (Implement keyword):  [ ] PASS  [ ] FAIL  Notes: __________
Test Case 3 (Fix keyword):        [ ] PASS  [ ] FAIL  Notes: __________
Test Case 4 (Question -> chat):   [ ] PASS  [ ] FAIL  Notes: __________
Test Case 5 (Explain -> chat):    [ ] PASS  [ ] FAIL  Notes: __________
Test Case 6 (Priority check):     [ ] PASS  [ ] FAIL  Notes: __________
Test Case 7 (No repo fallback):   [ ] PASS  [ ] FAIL  Notes: __________
Test Case 8 (File detection):     [ ] PASS  [ ] FAIL  Notes: __________
Test Case 9 (Multi-file):         [ ] PASS  [ ] FAIL  Notes: __________
Test Case 10 (Slash commands):    [ ] PASS  [ ] FAIL  Notes: __________

Overall Success Rate: ___/10
Ready for Phase 2: [ ] YES  [ ] NO (fix issues first)
```

---

## ✅ Ready for Phase 2 Criteria

Before moving to Phase 2, ensure:

- [ ] At least 8/10 test cases pass
- [ ] No false positives (questions don't trigger edits)
- [ ] Graceful fallback when no repository
- [ ] Slash commands still work
- [ ] No crashes or errors in normal usage

Once Phase 1 is stable, we can proceed to **Phase 2**: Adding repo integration to `/make`, `/tweak`, and `/debug` modes!
