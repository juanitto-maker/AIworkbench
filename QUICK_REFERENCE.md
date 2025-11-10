# AIWB Quick Reference - File Locations by Issue Type

## Context & Images Handling
**Primary Files:**
- `/home/user/AIworkbench/lib/modes.sh` (lines 199-296, 432-537)
  - `menu_uploads()` - Add files/directories/images
  - `menu_file_browser()` - Browse filesystem
  - `menu_outputs_browser()` - Browse generated outputs

**Global State:**
- `MODE_UPLOADS=()` array in modes.sh (line 18)

**Display:**
- modes.sh lines 645-668: Context embedding in prompts

---

## Workspace Exit Handling
**Primary Files:**
- `/home/user/AIworkbench/aiwb` (lines 17-44)
  - `cleanup_on_interrupt()` - Main exit handler
  - `trap cleanup_on_interrupt INT TERM` (line 44)
  - Exit code 130 for interrupts

**Cleanup Operations:**
- Kill background jobs and curl processes
- Clean `/tmp/aiwb_curl_*` temp files
- Return exit code 130

---

## File Viewing/Display Code
**Primary Files:**
- `/home/user/AIworkbench/lib/modes.sh` (lines 540-606)
  - `menu_view_outputs()` - View generated outputs
  - Shows file path, offers clipboard copy

**Secondary Locations:**
- aiwb lines 667-673: Preview in cmd_generate()
- aiwb lines 762-767: Preview in mode_run()
- ui.sh lines 250-275: ui_info_box() for display
- ui.sh lines 232-247: ui_header() for headers

---

## Menu Implementations

### /context Menu
**Location:** `/home/user/AIworkbench/aiwb` lines 950-1011
**Function:** `cmd_context(subcommand, args)`

Commands:
- `add <files/dirs>` - Add to context
- `list` - Show current context
- `remove <item>` - Remove from context
- `clear` - Clear all context

### /settings Menu
**Location:** `/home/user/AIworkbench/aiwb` lines 1353-1405
**Function:** `cmd_settings()`

Options:
- Provider selection
- Model selection
- Preferences (auto-estimate, confirm before generate, show costs)
- Cost tracking (monthly budget)
- Security (audit, encryption, key testing)

### /maker or /make Menu
**Location:** `/home/user/AIworkbench/lib/modes.sh` lines 904-965
**Function:** `mode_loop("make")`

Workflow:
1. Prompt (set text instructions)
2. Instruct (load from file)
3. Model (choose provider/model)
4. Uploads (add context files)
5. Check (configure verification)
6. Status (display current state)
7. Run (execute generation)
8. View outputs (browse outputs)

### /history Menu
**Location:** `/home/user/AIworkbench/aiwb` lines 1497-1522
**Function:** `cmd_history()`

Display: Chat logs with fzf, gum filter, or ls
Logs in: `~/.aiwb/workspace/logs/chat_*.log`

### /costs Menu
**Location:** `/home/user/AIworkbench/aiwb` lines 1525-1554
**Function:** `cmd_costs()`

Display:
- Total spent (USD)
- By provider breakdown
- Recent activity (last 10)
- Source: `~/.aiwb/workspace/logs/usage.jsonl`

---

## AI Output/Streaming Code
**Primary Files:**
- `/home/user/AIworkbench/aiwb` (lines 534-574)
  - `handle_chat_message()` - Main chat streaming
  - `copy_to_clipboard()` (lines 491-532) - Post-response clipboard offer

**Streaming Implementation:**
- api.sh: Uses buffered curl with temp files
- aiwb: "Thinking..." indicator (simple, non-blocking)
- modes.sh: "Generating response..." indicator

**Output Handling:**
- Direct stdout for real-time display
- Truncate logs only (>100 lines: first 50 + last 50)
- Full output saved to files

**Clipboard:**
- 5-second timeout for Ctrl+Y
- Auto-detects: pbcopy, termux-clipboard-set, xclip, xsel, wl-copy

---

## External Storage Browsing
**Primary Files:**
- `/home/user/AIworkbench/lib/modes.sh` (lines 213-244)
  - Storage location menu in `menu_uploads()`
  - Paths checked: `$HOME/storage/shared`, `/storage/emulated/0`, `/sdcard`

**Common.sh Support:**
- `is_termux()` (lines 9-11) - Detects Termux
- `get_platform()` (lines 21-27) - Returns platform type

**Browser Features:**
- Emoji indicators: 📁 (dir), 📄 (file)
- Parent directory (..) navigation
- Sorted display
- Select files or whole directories

---

## Instruct File Handling
**Primary Files:**
- `/home/user/AIworkbench/lib/modes.sh`
  - `menu_instruct()` (lines 104-121) - Load from file
  - `get_instruction_display()` (lines 50-58) - Show current file
  - `mode_run()` (lines 619-623) - Use file in execution

**Features:**
- Load markdown/text files as instructions
- Stored in: `MODE_INSTRUCT_FILE` global
- Conflicts with `MODE_PROMPT` (mutually exclusive)
- Word count display
- Content embedded in final prompt

**File Format:**
- Plain text or markdown
- Any extension acceptable
- Full content included in request

---

## API & Provider Implementation
**Location:** `/home/user/AIworkbench/lib/api.sh`

**Provider Functions:**
- Gemini: `call_gemini()` (lines 148-260)
- Claude: `call_claude()` (lines 266-360)
- OpenAI: `call_openai()` (lines 366-480)
- Groq: `call_groq()` (lines 486-593)
- xAI: `call_xai()` (lines 599-706)
- Ollama: `call_ollama()` (lines 712-799)

**Unified Interface:**
- `call_api(prompt, provider, model, max_tokens)` (lines 806-855)
- `estimate_tokens(text)` (lines 127-142)
- `calculate_cost(provider, model, input_tokens, output_tokens)` (lines 935-952)

**Error Handling:**
- `display_api_error()` (lines 12-63) - Comprehensive error display
- Timeout: 300s, Connect: 10s
- Exit code 130 on interrupt
- Temp file cleanup on error

---

## Configuration & State Files
**Location:** `~/.aiwb/`

**Files:**
- `config.json` - Main configuration (provider, model, preferences)
- `.session` - Session state (workspace, task, project)
- `.aiwb.env` - API keys (bash exports, 600 permissions)
- `.keys.age` - Encrypted keys (optional)

**Workspace:**
- `workspace/outputs/` - Generated files (*.md)
- `workspace/logs/chat_*.log` - Chat history
- `workspace/logs/usage.jsonl` - API usage tracking
- `workspace/tasks/` - Task prompts
- `workspace/templates/` - Workflow templates

---

## Key Global Variables
**modes.sh (line 13-21):**
```bash
MODE_CURRENT=""              # make, tweak, or debug
MODE_PROMPT=""               # Text instructions
MODE_INSTRUCT_FILE=""        # File-based instructions
MODE_MODEL_PROVIDER=""       # Provider (gemini, claude, etc)
MODE_MODEL_NAME=""           # Specific model
MODE_UPLOADS=()              # Array of context files
MODE_CHECK_PROVIDER=""       # Verification provider
MODE_CHECK_MODEL=""          # Verification model
MODE_CHECK_INSTRUCT=""       # Custom verification instructions
```

**aiwb (line 14):**
```bash
AIWB_IN_API_CALL=0           # Track if in API call
```

---

## Error Codes
- 0: Success
- 1: General error
- 2: Command misuse
- 3: Missing dependency
- 4: Configuration error
- 5: API key error
- 6: API call failed
- 7: Network error
- 8: Authentication failed
- 9: Rate limit exceeded
- 10: File not found
- 11: Permission denied
- 12: Invalid input
- **130: Interrupted (Ctrl+C)**

---

## Debug & Troubleshooting

**Enable Debug Mode:**
```bash
AIWB_DEBUG=1 aiwb [command]
```

**View Logs:**
```bash
~/.aiwb/workspace/logs/
  ├── chat_*.log         (chat history)
  └── usage.jsonl        (API usage)
```

**Check Configuration:**
```bash
~/.aiwb/config.json
```

**View API Keys:**
```bash
~/.aiwb/.aiwb.env
```

---

## Implementation Notes

### Interrupt Handling Pattern
All API calls should:
1. Check exit code 130 from `call_api()`
2. Return 130 if interrupted
3. Avoid cleanup (handled globally)

### File Context Pattern
When adding context:
1. Read file with `cat "$file"`
2. Embed in prompt with separator
3. For directories: list key files, show first 20 lines
4. Embed in final prompt before API call

### Menu Pattern
All menus:
1. Use `ui_choose()` for selection
2. Load current state from globals
3. Update globals on changes
4. Return 0 on success, 130 on interrupt
5. Show "Back" option for navigation

### Output Display Pattern
- Use `cat` for small files
- Use `less` for large files
- Offer clipboard copy
- Show file path
- Allow pagination

---

## File Locations Summary
| Feature | Primary File | Line Range |
|---------|---|---|
| Context handling | modes.sh | 199-296, 645-668 |
| Exit cleanup | aiwb | 17-44 |
| File viewing | modes.sh | 540-606 |
| /context menu | aiwb | 950-1011 |
| /settings menu | aiwb | 1353-1405 |
| /make mode | modes.sh | 904-965 |
| /history menu | aiwb | 1497-1522 |
| /costs menu | aiwb | 1525-1554 |
| API calls | api.sh | 148-855 |
| Instruct files | modes.sh | 104-121 |
| External storage | modes.sh | 213-244 |
| Error handling | error.sh | Full file |
| Config mgmt | config.sh | Full file |
| Platform support | common.sh | Full file |
| UI components | ui.sh | Full file |
