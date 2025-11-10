# AIWB Codebase Structure & Location Guide

## Project Overview
**AIWB** (AIWorkbench) is a multi-model AI orchestration platform for the command line written in Bash. It supports multiple AI providers (Gemini, Claude, OpenAI, Groq, xAI, Ollama) and features a mode-based workflow system.

---

## 1. MAIN ENTRY POINT

### Primary File
- **Location:** `/home/user/AIworkbench/aiwb`
- **Type:** Executable Bash script (47KB, ~1,700 lines)
- **Key Sections:**
  - **Interrupt Handling** (lines 10-44): SIGINT/SIGTERM cleanup
  - **Bootstrap** (lines 47-64): Loads all library files
  - **Initialization** (lines 67-124): Check dependencies, init workspace, load config
  - **Main Commands** (lines 146-1708): All top-level command handlers
  - **Main Function** (lines 1610-1708): Entry point and command routing

**Key Functions:**
- `cleanup_on_interrupt()` - Graceful exit handler for Ctrl+C
- `check_dependencies()` - Verifies bash, jq, curl availability
- `initialize()` - Sets up workspace and loads all config/session
- `main()` - Routes commands and initializes application

---

## 2. LIBRARY FILES STRUCTURE

### Core Libraries (in `/home/user/AIworkbench/lib/`)

#### **common.sh** (9KB, ~377 lines)
**Location:** `/home/user/AIworkbench/lib/common.sh`

**Purpose:** Shared utilities and cross-platform compatibility layer

**Key Sections:**
- **Platform Detection** (lines 5-27): `is_termux()`, `is_macos()`, `is_linux()`, `get_platform()`
- **Input Reading** (lines 52-94): `safe_read()` - Termux-compatible input with /dev/tty fallback
- **Output Formatting** (lines 100-163): Colors, logging functions (msg, info, success, warn, err, debug)
- **Path Utilities** (lines 166-202): `get_workspace()`, `ensure_dir()`, `get_aiwb_home()`
- **Clipboard Support** (lines 321-371): `copy_to_clipboard()`, `has_clipboard()`

**Critical Functions:**
- `safe_read()` - Safe input reading with Termux support
- `get_workspace()` - Returns workspace directory
- `copy_to_clipboard()` - Cross-platform clipboard operations

---

#### **config.sh** (7.8KB, ~276 lines)
**Location:** `/home/user/AIworkbench/lib/config.sh`

**Purpose:** Configuration management and model defaults

**Key Sections:**
- **Config Paths** (lines 10-24): Files for config, session, env vars, API keys
- **Workspace Init** (lines 30-74): `init_workspace()` - Creates directory structure
- **Config Management** (lines 111-170): `load_config()`, `config_get()`, `config_set()`
- **Session Management** (lines 176-219): `save_session()`, `load_session()`
- **Model Defaults** (lines 225-269): `get_default_model()`, `get_available_models()`

**Workspace Structure Created:**
```
~/.aiwb/
├── config.json          (main configuration)
├── .session            (session state)
├── .aiwb.env           (API keys)
├── .keys.age           (encrypted keys)
└── workspace/
    ├── projects/
    ├── tasks/          (task prompts)
    ├── snapshots/
    ├── logs/           (chat logs, usage.jsonl)
    ├── templates/
    ├── history/
    └── outputs/        (generated outputs)
```

---

#### **ui.sh** (11.3KB, ~400 lines)
**Location:** `/home/user/AIworkbench/lib/ui.sh`

**Purpose:** Beautiful Terminal UI components using `gum` or fallback

**Key Sections:**
- **Input Functions** (lines 17-70): `ui_input()`, `ui_password()`, `ui_write()`
- **Selection Functions** (lines 77-155): `ui_choose()`, `ui_choose_multi()`, `ui_filter()`
- **Confirmation** (lines 161-174): `ui_confirm()`
- **Progress/Spinners** (lines 180-225): `ui_progress()`, `ui_spinner()`
- **Formatting** (lines 232-340): Headers, info boxes, tables, styled text
- **Status Display** (lines 347-393): `ui_show_status()` - Shows current session status

**Display Functions:**
- `ui_header()` - Fancy bordered headers
- `ui_info_box()` - Colored info boxes (info/success/warning/error)
- `ui_table()` - Tabular data display
- `ui_style()` - Text styling (color, bold)

---

#### **api.sh** (33.9KB, ~959 lines)
**Location:** `/home/user/AIworkbench/lib/api.sh`

**Purpose:** API interaction with multiple providers

**Key Sections:**
- **Error Display** (lines 12-63): `display_api_error()` - Comprehensive error messages
- **API Key Management** (lines 84-120): `get_api_key()`, `has_api_key()`
- **Token Estimation** (lines 127-142): `estimate_tokens()` - Rough char-to-token conversion
- **Provider-Specific Calls:**
  - Gemini (lines 148-260): `call_gemini()`, `stream_gemini()`
  - Claude (lines 266-360): `call_claude()`
  - OpenAI (lines 366-480): `call_openai()`
  - Groq (lines 486-593): `call_groq()`
  - xAI (lines 599-706): `call_xai()`
  - Ollama (lines 712-799): `call_ollama()`
- **Unified API** (lines 806-855): `call_api()` - Dispatcher based on provider
- **Cost Calculation** (lines 862-952): `get_pricing()`, `calculate_cost()`

**Key API Functions:**
- `call_api(prompt, provider, model, max_tokens)` - Main entry point
- All `call_*()` functions include interrupt handling (exit code 130 for SIGINT)
- Each provider uses curl with proper error handling and JSON parsing

**Error Handling:**
- All API calls have timeout (300s) and connect timeout (10s)
- Proper separation of curl errors vs API errors in response
- Returns exit code 130 on user interrupt

---

#### **error.sh** (9.1KB, ~340 lines)
**Location:** `/home/user/AIworkbench/lib/error.sh`

**Purpose:** Error codes, messages, and handling strategies

**Key Sections:**
- **Error Codes** (lines 11-23): E_SUCCESS, E_DEPENDENCY, E_API_KEY, E_API_CALL, etc.
- **Error Messages** (lines 29-43): Mapping of codes to messages
- **Error Solutions** (lines 50-139): `get_error_solution()` - Helpful troubleshooting
- **Error Helpers** (lines 156-211): `require_file()`, `require_dir()`, `require_command()`, `require_api_key()`
- **Retry Logic** (lines 228-299): `retry()`, `retry_api_call()` with exponential backoff
- **Validation** (lines 306-333): `validate_json()`, `validate_provider()`, `validate_model()`

---

#### **security.sh** (12.3KB, partial view)
**Location:** `/home/user/AIworkbench/lib/security.sh`

**Purpose:** API key management and encryption

**Key Sections:**
- **Key Storage** (lines 12-65): `set_api_key()` - Stores keys in .aiwb.env with 600 permissions
- **Interactive Setup** (lines 68-onwards): `setup_keys_interactive()` - Walks through key setup
- Key encryption support with `age` tool
- Security audit functions

**API Key Locations:**
- Stored in: `~/.aiwb/.aiwb.env`
- Environment variables: GEMINI_API_KEY, ANTHROPIC_API_KEY, OPENAI_API_KEY, GROQ_API_KEY, XAI_API_KEY

---

#### **modes.sh** (28.8KB, ~974 lines)
**Location:** `/home/user/AIworkbench/lib/modes.sh`

**Purpose:** Mode-based workflow system (/make, /tweak, /debug)

**Key Sections & Features:**

**1. Mode State Management** (lines 12-47)
- Global variables: MODE_CURRENT, MODE_PROMPT, MODE_INSTRUCT_FILE, MODE_MODEL_PROVIDER, MODE_MODEL_NAME, MODE_UPLOADS, MODE_CHECK_*
- `init_mode()` - Initialize mode state
- `reset_mode()` - Clear mode state

**2. Menu Functions** (lines 92-429)
- `menu_prompt()` (92-100) - Set text instructions
- `menu_instruct()` (104-121) - Load from file
- `menu_model()` (124-147) - Choose provider/model
- `menu_uploads()` (199-296) - Add context files
  - Includes storage selection: Internal Storage, External Storage (SD Card), Current Directory
  - File browser: `menu_file_browser()` (432-487)
  - Outputs browser: `menu_outputs_browser()` (490-537)
  - External storage paths: `$HOME/storage/shared`, `/storage/emulated/0`, `/sdcard`
- `menu_check()` (299-330) - Configure verification model
- `menu_status()` (383-429) - Display mode status
- `menu_view_outputs()` (540-606) - Browse and view generated outputs

**3. File Browsing** (lines 432-537)
- `menu_file_browser(dir)` - Browse files with parent/subdirectory navigation
- `menu_outputs_browser()` - Browse previous outputs
- External storage detection for Android/Termux

**4. Execution** (lines 609-898)
- `mode_run()` (609-898) - Main execution flow:
  - Validates instructions set
  - Builds final prompt with mode context
  - Adds uploaded files as context
  - Estimates costs
  - Asks for confirmation
  - Calls API
  - Saves output to workspace/outputs
  - Shows preview
  - Runs verification if configured
  - Displays actual costs
  - Shows "What's next?" menu

**5. Mode Loop** (lines 904-965)
- `mode_loop(mode)` - Main menu loop for mode (/make, /tweak, /debug)
- Returns exit code 130 on interrupt

**Key Features:**
- Context/image handling through uploads array
- Instruct file loading and handling
- Model selection with cross-provider support
- File browsing with external storage support
- Output generation, saving, and viewing
- Clipboard support for output copying
- Cost estimation and tracking

---

## 3. SPECIFIC FEATURE LOCATIONS

### **Context & Image Handling**

**Files Involved:**
1. **modes.sh** - Primary location
   - `menu_uploads()` (lines 199-296) - Add files/directories
   - `menu_file_browser()` (lines 432-487) - Browse filesystem
   - `menu_outputs_browser()` (lines 490-537) - Browse previous outputs

2. **aiwb** - Chat interface
   - `cmd_context()` (lines 950-1011) - /context command
   - MODE_UPLOADS array - Global storage

**Functionality:**
- Add files/directories to context
- Browse internal storage (HOME)
- Browse external storage (Android SD card paths)
- Browse previous outputs
- List, remove, clear context files
- Context embedded in prompts via `mode_run()` (lines 645-668)

---

### **Workspace Exit Handling**

**Files Involved:**
1. **aiwb** - Main script
   - `cleanup_on_interrupt()` (lines 17-41) - Ctrl+C handler
   - Trap setup (line 44): `trap cleanup_on_interrupt INT TERM`
   - Exit code 130 for SIGINT

2. **modes.sh**
   - `mode_loop()` (lines 904-965) - Returns 130 on interrupt
   - `mode_run()` (lines 736-739) - Checks exit code 130

3. **api.sh**
   - All API calls return exit code 130 on interrupt
   - Cleanup of temp files on interrupt

**Exit Sequence:**
```
Ctrl+C → cleanup_on_interrupt() 
  → Kill background jobs
  → Kill curl processes
  → Clean /tmp/aiwb_curl_* files
  → echo "Goodbye!" 
  → exit 130
```

---

### **File Viewing/Display Code**

**Files Involved:**
1. **modes.sh** - Primary viewer
   - `menu_view_outputs()` (lines 540-606)
   - Displays selected output file
   - Shows file location
   - Offers clipboard copy

2. **aiwb** - Show preview in various places
   - `cmd_generate()` (lines 667-673) - Preview first 20 lines
   - `mode_run()` (lines 762-767) - Preview first 20 lines
   - `cmd_improve()` (lines 1237-1238) - Preview improved version

3. **ui.sh**
   - `ui_info_box()` (lines 250-275) - Display info boxes
   - `ui_header()` (lines 232-247) - Display headers

**Display Patterns:**
- Use `cat` to display file contents
- Use `less` for pagination (if available)
- Offer clipboard copy with Ctrl+Y after response
- Truncate long files (show first 50 + last 50 lines if >100 lines)

---

### **Menu Implementations**

#### **/context Menu** - `aiwb` lines 950-1011
```
cmd_context(subcommand, args)
  - add <files/dirs>    → mode_uploads()
  - list                → Show MODE_UPLOADS array with sizes
  - remove <item>       → Remove from MODE_UPLOADS
  - clear               → Clear all MODE_UPLOADS
  - (no args)          → Show help
```

#### **/settings Menu** - `aiwb` lines 1353-1405
```
cmd_settings()
  - Provider: <current>      → Select new provider
  - Model: <current>         → Select from available models
  - Preferences              → settings_preferences()
  - Cost Tracking            → settings_cost_tracking()
  - Security                 → settings_security()
  - Back                     → Exit menu
```

**Submenus:**
- `settings_preferences()` (lines 1408-1440): Auto-estimate, confirm before generate, show costs
- `settings_cost_tracking()` (lines 1443-1455): Set monthly budget
- `settings_security()` (lines 1458-1477): Run audit, encrypt keys, test keys

#### **/maker or /make Menu** - Uses `mode_loop("make")`
```
mode_loop("make")
  - Prompt (text)
  - Instruct (file)
  - Model: <provider model>
  - Uploads: <count>
  - Check: <verification>
  - Status
  - Run
  - View outputs
  - Back
```

#### **/history Menu** - `aiwb` lines 1497-1522
```
cmd_history()
  Uses fzf, gum filter, or ls to browse chat_*.log files
  Displays with less pager if available
```

#### **/costs Menu** - `aiwb` lines 1525-1554
```
cmd_costs()
  - Total spent (USD)
  - By Provider (tab-separated table)
  - Recent activity (last 10 entries)
  - Uses usage.jsonl log file
```

---

### **AI Output/Streaming Code**

**Files Involved:**
1. **aiwb** - Main streaming orchestration
   - `handle_chat_message()` (lines 534-574) - Chat streaming
   - `copy_to_clipboard()` (lines 491-532) - Post-response clipboard offer

2. **api.sh** - Provider-specific streaming
   - `stream_gemini()` (lines 253-260) - Falls back to regular call
   - Each provider has buffered curl request with temp files

3. **modes.sh** - Output streaming
   - `mode_run()` (lines 721-726) - Shows "Generating response..." indicator
   - Output displayed immediately after generation

**Streaming Patterns:**
- Uses simple "Thinking..." message (no complex spinner) to avoid deadlocks
- Clears message with `echo -ne "\r\033[K"`
- Responses piped directly to stdout
- Long responses (>100 lines) truncated in logs only (not display)

**Clipboard Feature:**
- Waits 5 seconds for Ctrl+Y to copy response to clipboard
- Works after each AI response
- Auto-detects: pbcopy (macOS), termux-clipboard-set (Termux), xclip/xsel/wl-copy (Linux)

---

### **External Storage Browsing**

**Files Involved:**
1. **modes.sh** - Primary location
   - `menu_uploads()` (lines 213-244) - Storage selection menu
   - External storage paths checked:
     - `$HOME/storage/shared` (Termux primary)
     - `/storage/emulated/0` (Android fallback)
     - `/sdcard` (Legacy Android)

2. **common.sh** - Platform detection
   - `is_termux()` (lines 9-11) - Detects Termux environment
   - `get_platform()` (lines 21-27) - Returns platform string

**Menu Flow:**
```
menu_uploads()
  → "Browse files"
    → Storage selection
      → "Internal Storage ($HOME)" → menu_file_browser("$HOME")
      → "External Storage" → menu_file_browser(<detected_path>)
      → "Current Directory" → menu_file_browser(".")
  → "Browse outputs" → menu_outputs_browser()
  → "Type path manually" → manual entry
```

**File Browser:**
- Shows emoji indicators: 📁 for directories, 📄 for files
- Parent directory (..) option
- Sorted display
- Can select files or directories
- Selected items added to MODE_UPLOADS array

---

### **Instruct File Handling**

**Files Involved:**
1. **modes.sh** - Primary handler
   - `menu_instruct()` (lines 104-121)
   - `get_instruction_display()` (lines 50-58) - Shows "File: <name>"

2. **aiwb** - Instruct command in chat
   - `handle_slash_command()` (lines 358-442) - Routes /instruct if added

3. **modes.sh** - Usage in execution
   - `mode_run()` (lines 619-623) - Reads and uses instruct file

**Instruct File Features:**
- Load markdown files as instructions
- File path stored in MODE_INSTRUCT_FILE global
- Conflicts with MODE_PROMPT (clears text if file set, vice versa)
- File size shown in word count
- Content embedded in final prompt (lines 620)
- Can add `.md` extension for markdown formatting

**File Format:**
- Plain text or markdown
- Full content loaded into prompt
- Embedded with `=== FILE CONTENT ===` header

---

## 4. KEY GLOBAL VARIABLES & STATE

### Mode State (modes.sh)
```bash
MODE_CURRENT=""              # "make", "tweak", or "debug"
MODE_PROMPT=""               # Text instructions
MODE_INSTRUCT_FILE=""        # File-based instructions
MODE_MODEL_PROVIDER=""       # "gemini", "claude", etc.
MODE_MODEL_NAME=""           # Specific model name
MODE_UPLOADS=()              # Array of file/directory paths
MODE_CHECK_PROVIDER=""       # Verification provider
MODE_CHECK_MODEL=""          # Verification model
MODE_CHECK_INSTRUCT=""       # Custom check instructions
```

### Runtime Flags (aiwb)
```bash
AIWB_IN_API_CALL=0           # Track if in API call
AIWB_DEBUG=0                 # Debug mode flag
GUM_AVAILABLE=false          # TUI availability
```

---

## 5. DIRECTORY STRUCTURE

```
/home/user/AIworkbench/
├── aiwb                      (47KB executable, main entry point)
├── lib/
│   ├── common.sh            (9KB - platform, utilities)
│   ├── config.sh            (7.8KB - config management)
│   ├── ui.sh                (11.3KB - TUI components)
│   ├── api.sh               (33.9KB - API calls)
│   ├── error.sh             (9.1KB - error handling)
│   ├── security.sh          (12.3KB - key management)
│   └── modes.sh             (28.8KB - mode system)
├── templates/               (Example templates)
├── docs/                    (Documentation)
├── completions/             (Shell completions)
└── Context/                 (Context files)

~/.aiwb/                      (User home)
├── config.json              (Main config)
├── .session                 (Session state)
├── .aiwb.env                (API keys, sourced)
├── .keys.age                (Encrypted keys)
└── workspace/
    ├── projects/
    ├── tasks/
    ├── outputs/             (Generated files here)
    ├── logs/                (Chat logs, usage.jsonl)
    ├── templates/
    ├── snapshots/
    └── history/
```

---

## 6. KEY COMMAND FLOW

### Interactive Chat Flow
```
aiwb
  → initialize() [loads config, keys, workspace]
  → cmd_chat()
  → chat_loop()
    → While true:
      → gum input or safe_read for prompt
      → If /command: handle_slash_command()
        → /make, /tweak, /debug → mode_loop()
        → /context → cmd_context()
        → /settings → cmd_settings()
        → /history → cmd_history()
      → Else: handle_chat_message()
        → call_api()
        → track_usage()
        → Show response
```

### Mode Execution Flow
```
mode_loop(mode)
  → Display menu with current state
  → User choices:
    → "Prompt" → menu_prompt()
    → "Instruct" → menu_instruct()
    → "Model" → menu_model()
    → "Uploads" → menu_uploads()
    → "Run" → mode_run()
      → Build final prompt
      → Show cost estimate
      → call_api()
      → Save output
      → Optionally verify
      → Show "What's next?" menu
```

---

## 7. EXIT CODES

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Command misuse |
| 3 | Missing dependency |
| 4 | Configuration error |
| 5 | API key error |
| 6 | API call failed |
| 7 | Network error |
| 8 | Authentication failed |
| 9 | Rate limit exceeded |
| 10 | File not found |
| 11 | Permission denied |
| 12 | Invalid input |
| 130 | Interrupted (SIGINT/Ctrl+C) |

---

## 8. IMPORTANT NOTES FOR DEBUGGING

1. **Debug Mode:** Run with `AIWB_DEBUG=1 aiwb [command]`
2. **Log Files:** Check `~/.aiwb/workspace/logs/`
3. **Chat History:** `~/.aiwb/workspace/logs/chat_*.log`
4. **Usage Tracking:** `~/.aiwb/workspace/logs/usage.jsonl`
5. **Config File:** `~/.aiwb/config.json` (JSON format)
6. **API Keys:** `~/.aiwb/.aiwb.env` (bash export format, 600 permissions)

---

## 9. MULTI-PROVIDER SUPPORT

Each provider has its own implementation in `api.sh`:

| Provider | Model Function | Default Model | Max Tokens |
|----------|---|---|---|
| **Gemini** | `call_gemini()` | 2.5-flash | 16000 |
| **Claude** | `call_claude()` | 3-haiku-20240307 | 4096 (haiku) / 8192 (other) |
| **OpenAI** | `call_openai()` | gpt-4o-mini | 16000 |
| **Groq** | `call_groq()` | llama-3.3-70b-versatile | 16000 |
| **xAI** | `call_xai()` | grok-3 | 16000 |
| **Ollama** | `call_ollama()` | llama3.2:latest | (local) |

