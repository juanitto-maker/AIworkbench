# Chat-First Workflow Implementation Plan

## 🎯 Goal
Transform AIWB into a chat-first tool where users can naturally request code changes in conversation, and the AI automatically integrates them into the repository. Slash commands become optional for power users or fine-tuning.

## 📋 Current State Analysis

### What Works Now
- **Regular chat**: AI responds but doesn't edit files
- **`/edit <task>`**: Directly edits files in repo (with confirmation)
- **`/make`, `/tweak`, `/debug`**: Workflow modes that output to `~/.aiwb/workspace/outputs/` files

### The Problem
- Users must remember to use `/edit` for repo changes
- Workflow modes generate code but don't integrate it into the repo
- Chat feels disconnected from actual development workflow
- App outputs files instead of making changes to the codebase

## 🏗️ Proposed Architecture

### Phase 1: Smart Chat Message Routing

**Location**: `aiwb:919` - `handle_chat_message()`

**Enhancement**: Detect intent keywords and auto-route to appropriate workflow

```bash
# User types in chat:
> "Add dark mode to settings page"

# System detects:
# - Keyword: "Add" (creation intent)
# - Target: "settings page" (likely a file)
# - Action: Route to /edit workflow

# Behind the scenes:
→ Calls: smart_edit "Add dark mode to settings page"
→ Shows: "🤖 Detected code change request. Analyzing files..."
→ AI determines which files to modify
→ Shows diff preview
→ Asks: "Apply these changes?"
→ User confirms: Yes
→ Changes applied to repo
```

**Intent Detection Keywords**:
```bash
# EDIT/IMPLEMENT (route to /edit)
- implement, add, create, build
- update, modify, change, edit, tweak
- fix, debug, resolve, patch
- remove, delete, refactor

# EXPLAIN (keep as chat)
- how, what, why, explain, show
- tell me, help me understand
- documentation, guide

# GENERATE (route to /make mode with repo integration)
- generate, scaffold, boilerplate
- new project, new feature
```

### Phase 2: Post-Generation Repo Integration for Modes

**Location**: `lib/modes.sh:982` - `mode_run()`

**Enhancement**: After code generation, intelligently apply to repository

```bash
# Current flow:
/make → configure → run → save to output file → done ✓

# New flow:
/make → configure → run → save to output file
      → "Apply to repository?"
      → parse code blocks
      → detect target files
      → show diff preview
      → apply changes ✓
```

**Implementation Steps**:
1. After output is saved (line 1188), add repo integration prompt
2. Parse the generated markdown for code blocks
3. Extract filename hints from code blocks or AI analysis
4. Use `edit_file_with_ai()` or `smart_edit()` to apply changes
5. Show unified diff for all changes
6. Confirm and apply

### Phase 3: Intelligent Code Application

**New Module**: `lib/code_applier.sh`

**Functions**:

```bash
# Parse generated code and determine target files
parse_generated_code() {
    local output_content="$1"

    # Extract code blocks with language hints
    # Example: ```python:src/auth.py
    # Example: ```javascript // file: src/app.js

    # Return JSON:
    # [
    #   {"file": "src/auth.py", "content": "...", "action": "create|update"},
    #   {"file": "src/app.js", "content": "...", "action": "update"}
    # ]
}

# Apply parsed code to repository
apply_code_to_repo() {
    local parsed_json="$1"

    # For each file in JSON:
    # 1. Check if file exists
    # 2. If exists: generate diff
    # 3. If new: show "Creating new file"
    # 4. Collect all changes
    # 5. Show unified preview
    # 6. Confirm once
    # 7. Apply all changes atomically
}

# Detect files from natural language task
detect_target_files() {
    local task_description="$1"
    local repo_context="$2"

    # Ask AI: "Which files should be modified for: $task_description"
    # Consider repo structure from $repo_context
    # Return list of file paths
}
```

### Phase 4: Enhanced User Experience

**Chat Loop Enhancements**:

```bash
# Smart confirmation messages
"🤖 I'll add dark mode to src/settings.jsx and src/styles/theme.css"
"📝 Generating changes..."
"✅ Ready to apply. Review diff? [y/n]"

# Inline diff preview in chat
"--- src/settings.jsx
+++ src/settings.jsx
@@ -10,6 +10,8 @@
+  const [darkMode, setDarkMode] = useState(false)
+  const toggleDarkMode = () => setDarkMode(!darkMode)
"

# Confirmation with context
"Apply changes to 2 files? (src/settings.jsx, src/styles/theme.css) [Y/n]"
```

**Status Footer Updates**:
```bash
# Show repo integration status
"💾 2 files modified | 📁 my-project | 💰 $0.02"
```

## 🔧 Implementation Details

### File Structure

```
lib/
├── chat_router.sh          # NEW: Smart intent detection & routing
├── code_applier.sh         # NEW: Parse & apply generated code
├── modes.sh                # MODIFIED: Add repo integration after run
└── editor.sh               # EXISTING: Use smart_edit(), edit_file_with_ai()

aiwb                        # MODIFIED: Route chat messages through router
```

### Modified Functions

**1. `handle_chat_message()` in aiwb:919**

```bash
handle_chat_message() {
    local message="$1"

    # NEW: Detect intent
    local intent=$(detect_message_intent "$message")

    case "$intent" in
        "edit"|"implement"|"fix")
            # Auto-route to edit workflow
            msg "🤖 Detected code change request..."
            smart_edit "$message"
            return $?
            ;;
        "generate"|"scaffold")
            # Route to /make with repo integration
            msg "🤖 Starting code generation workflow..."
            auto_make_with_integration "$message"
            return $?
            ;;
        "chat"|"explain")
            # Keep existing chat behavior
            # ... existing code ...
            ;;
    esac
}
```

**2. `mode_run()` in lib/modes.sh:982**

```bash
mode_run() {
    # ... existing code up to line 1199 ...

    # NEW: After preview, offer repo integration
    echo ""
    if is_repo_mode && ui_confirm "Apply this code to your repository?" "yes"; then
        msg "Analyzing generated code for file targets..."

        # Parse the output for code blocks
        local parsed_files=$(parse_generated_code "$output")

        if [[ -n "$parsed_files" ]]; then
            # Apply to repo
            apply_code_to_repo "$parsed_files"
        else
            # Fallback: ask AI which files to modify
            msg "Using AI to determine target files..."
            local target_files=$(detect_target_files "$MODE_PROMPT" "$(git ls-files)")

            if [[ -n "$target_files" ]]; then
                # Apply the generated content to detected files
                apply_content_to_files "$output" "$target_files"
            else
                warn "Could not determine target files. Code saved to: $output_file"
            fi
        fi
    fi

    # ... rest of existing code ...
}
```

### New Module: `lib/chat_router.sh`

```bash
#!/usr/bin/env bash
# chat_router.sh - Smart intent detection and routing for chat messages

detect_message_intent() {
    local message="$1"
    local lowercase=$(echo "$message" | tr '[:upper:]' '[:lower:]')

    # Keywords for different intents
    local edit_keywords="implement|add|create|update|modify|change|edit|fix|debug|remove|delete|refactor|tweak"
    local generate_keywords="generate|scaffold|boilerplate|new project|new feature|build from scratch"
    local explain_keywords="how|what|why|explain|show|tell me|help|documentation|guide"

    # Check for edit/implement intent
    if echo "$lowercase" | grep -Eq "\b($edit_keywords)\b"; then
        echo "edit"
        return 0
    fi

    # Check for generate intent
    if echo "$lowercase" | grep -Eq "\b($generate_keywords)\b"; then
        echo "generate"
        return 0
    fi

    # Check for explanation intent
    if echo "$lowercase" | grep -Eq "\b($explain_keywords)\b"; then
        echo "chat"
        return 0
    fi

    # Default to chat for ambiguous cases
    echo "chat"
}

auto_make_with_integration() {
    local description="$1"

    # Set up mode state
    MODE_CURRENT="make"
    MODE_PROMPT="$description"
    MODE_MODEL_PROVIDER="$(config_get model_provider)"
    MODE_MODEL_NAME="$(config_get model_name)"
    MODE_CHECK_PROVIDER="auto"  # Enable auto-verification

    # Run the mode
    mode_run

    # Clean up
    reset_mode
}

export -f detect_message_intent auto_make_with_integration
```

### New Module: `lib/code_applier.sh`

```bash
#!/usr/bin/env bash
# code_applier.sh - Parse and apply generated code to repository

parse_generated_code() {
    local output="$1"
    local files_json="[]"

    # Extract code blocks with file hints
    # Pattern: ```language:filepath or ```language // file: filepath

    # Use awk/sed to extract:
    # - Language
    # - File path
    # - Code content

    # Build JSON array
    echo "$files_json"
}

apply_code_to_repo() {
    local parsed_json="$1"
    local file_count=$(echo "$parsed_json" | jq 'length')

    if [[ $file_count -eq 0 ]]; then
        warn "No files detected in generated code"
        return 1
    fi

    msg "Found $file_count file(s) to modify"

    # Preview all changes
    echo ""
    echo "${BOLD}${BLUE}Preview of changes:${RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    for i in $(seq 0 $((file_count - 1))); do
        local file=$(echo "$parsed_json" | jq -r ".[$i].file")
        local content=$(echo "$parsed_json" | jq -r ".[$i].content")
        local action=$(echo "$parsed_json" | jq -r ".[$i].action")

        echo ""
        echo "${CYAN}File: $file${RESET} (${action})"

        if [[ "$action" == "update" ]]; then
            # Show diff
            show_file_diff "$file" "$content"
        else
            # Show new file preview
            echo "${GREEN}+ New file ($(echo "$content" | wc -l) lines)${RESET}"
        fi
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Confirm once for all changes
    if ui_confirm "Apply all changes to repository?" "yes"; then
        for i in $(seq 0 $((file_count - 1))); do
            local file=$(echo "$parsed_json" | jq -r ".[$i].file")
            local content=$(echo "$parsed_json" | jq -r ".[$i].content")

            # Apply the change
            echo "$content" > "$AIWB_REPO_PATH/$file"
            success "✓ Applied: $file"
        done

        echo ""
        success "All changes applied successfully!"

        # Suggest git commands
        echo ""
        echo "${DIM}Next steps:${RESET}"
        echo "  git diff              # Review changes"
        echo "  /github commit        # Commit changes"
    else
        info "Changes cancelled"
    fi
}

detect_target_files() {
    local task="$1"
    local file_list="$2"

    # Ask AI which files to modify
    local prompt="Based on this task: '$task'

Files in repository:
$file_list

Which files should be modified? Respond with ONLY a JSON array of file paths.
Example: [\"src/app.js\", \"src/utils.js\"]"

    local response=$(call_api "$prompt" "$(config_get model_provider)" "$(config_get model_name)")

    # Parse JSON response
    echo "$response" | jq -r '.[]' 2>/dev/null
}

export -f parse_generated_code apply_code_to_repo detect_target_files
```

## 🎨 User Experience Examples

### Example 1: Natural Chat Editing

```bash
$ aiwb
> Add a password strength validator to the login form

🤖 Detected code change request. Analyzing files...
📁 Found: src/components/LoginForm.jsx, src/utils/validators.js

📝 Generating changes...

Preview of changes:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File: src/components/LoginForm.jsx (update)
@@ -15,6 +15,12 @@
+  const validatePassword = (pwd) => {
+    return passwordStrength(pwd) >= 3
+  }

File: src/utils/validators.js (update)
@@ -1,0 +1,10 @@
+export const passwordStrength = (password) => {
+  let strength = 0
+  if (password.length >= 8) strength++
+  if (/[A-Z]/.test(password)) strength++
+  if (/[0-9]/.test(password)) strength++
+  if (/[^A-Za-z0-9]/.test(password)) strength++
+  return strength
+}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Apply all changes to repository? [Y/n] y

✓ Applied: src/components/LoginForm.jsx
✓ Applied: src/utils/validators.js

All changes applied successfully!

Next steps:
  git diff              # Review changes
  /github commit        # Commit changes
```

### Example 2: Workflow Mode with Integration

```bash
$ aiwb
> /make

MAKE Mode
┌─────────────────────────────────────┐
│ Prompt (text)                       │
│ Instruct (file)                     │
│ Model: gemini gemini-2.0-flash      │
│ Context/Uploads: (none)             │
│ Run                                 │
└─────────────────────────────────────┘

make> prompt Create a REST API endpoint for user profile updates

[... configuration ...]

make> run

💰 Cost Estimation: $0.03
Proceed? [Y/n] y

🤖 Generating with gemini...
✅ Output saved to: ~/.aiwb/workspace/outputs/make_gemini_20260104_143022.md

Preview:
```javascript
// API endpoint for user profile updates
app.post('/api/user/profile', async (req, res) => {
  // ... (20 lines of generated code)
```

Apply this code to your repository? [Y/n] y

🤖 Analyzing generated code for file targets...
📁 Detected: src/routes/user.js (update)

Preview of changes:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File: src/routes/user.js (update)
@@ -45,0 +45,15 @@
+app.post('/api/user/profile', async (req, res) => {
+  // ... generated endpoint code
+})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Apply changes? [Y/n] y

✓ Applied: src/routes/user.js
```

### Example 3: Ambiguous Request (Fallback)

```bash
> Improve the error handling

🤖 Analyzing repository to determine files...

Found these files with error handling:
  1. src/api/handlers.js
  2. src/utils/errors.js
  3. src/components/ErrorBoundary.jsx

Which files should I modify? [1,2,3 or 'all'] all

📝 Generating improvements for 3 files...

[... shows changes ...]
```

## ⚙️ Configuration Options

Add to `~/.aiwb/config.json`:

```json
{
  "chat": {
    "auto_detect_intent": true,
    "auto_apply_edits": false,
    "confirm_before_edit": true,
    "show_inline_diffs": true
  },
  "modes": {
    "auto_integrate_to_repo": true,
    "prefer_repo_over_output_files": true
  }
}
```

## 🚀 Migration Path

### Phase 1 (MVP): Chat Router + /edit Enhancement
- Implement `chat_router.sh`
- Hook into `handle_chat_message()`
- Test keyword detection
- Ensure `/edit` workflow is solid

### Phase 2: Mode Integration
- Add post-generation prompt to `mode_run()`
- Implement basic code application
- Test with `/make`, `/tweak`, `/debug`

### Phase 3: Smart Code Parser
- Implement `code_applier.sh`
- Parse code blocks with file hints
- Handle multiple files
- Intelligent diff generation

### Phase 4: Polish & Fallbacks
- Better error messages
- Ambiguity resolution
- Configuration options
- Documentation updates

## 📊 Success Metrics

- **Primary**: Users can request changes in natural language and see them applied to repo
- **Secondary**: `/edit`, `/make`, `/tweak`, `/debug` all integrate with repository
- **UX**: < 3 confirmations for a typical edit workflow
- **Flexibility**: Slash commands still available for power users

## 🎯 Final Vision

```bash
# The ideal workflow:
$ cd my-project
$ aiwb

> Add user authentication with JWT
  ✓ Generated auth middleware, routes, tests
  ✓ Applied to 4 files
  💾 Ready to commit

> Fix the bug in the search function
  ✓ Detected issue in src/search.js:23
  ✓ Applied fix
  💾 Ready to commit

> /github commit "Add auth + fix search"
  ✓ Committed

> /github push
  ✓ Pushed to origin/main
```

---

**Next Steps**: Start with Phase 1 implementation, create `lib/chat_router.sh`, and hook it into `handle_chat_message()`.
