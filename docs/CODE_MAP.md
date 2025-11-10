# AIWB Code Map - Complete File Reference

## Quick Navigation

**Total Lines of Code**: 6,209  
**Main Language**: Bash  
**Architecture**: Modular CLI with 6 core libraries

---

## Core Entry Point

### `/aiwb` (1,886 lines)
**Main executable, REPL loop, command dispatcher**

| Section | Lines | Purpose |
|---------|-------|---------|
| Interrupt handling | 15-44 | Ctrl+C trap, cleanup |
| Bootstrap | 46-64 | Script setup, path resolution |
| Initialization | 66-143 | Dependencies, workspace, config |
| Commands | 145-1800 | All user-facing commands |
| Main dispatch | 1802-1886 | REPL loop, command routing |

**Key Functions**:
- `check_dependencies()` - Verify bash, jq, curl
- `initialize()` - Setup workspace, config, keys
- `cmd_help()` - Display help
- `cmd_chat()` - Interactive chat
- `cmd_make/tweak/debug()` - Mode entry points
- `cmd_quick()` - One-shot generation
- `cmd_wizard()` - Guided workflow
- `cmd_keys()` - API key management
- `cmd_settings()` - Configuration menu
- `cmd_status()` - System status
- `cmd_doctor()` - Health check

**Global State**:
- `AIWB_IN_API_CALL` - Flag for interrupt safety
- `SCRIPT_DIR`, `LIB_DIR` - Path resolution
- Trap handlers for signals

---

## Library Modules

### `lib/common.sh` (384 lines)
**Platform utilities, logging, cross-platform helpers**

| Section | Lines | Purpose |
|---------|-------|---------|
| Platform detection | 9-27 | is_termux(), is_macos(), is_linux() |
| Command availability | 33-44 | have(), require() |
| Safe input reading | 58-101 | safe_read() for Termux/Linux/macOS |
| Output formatting | 107-171 | Colors, logging, spinner |
| Path utilities | 174-210 | get_aiwb_home(), get_workspace() |
| JSON utilities | 216-235 | json_get(), json_set() |
| String utilities | 242-257 | trim(), lowercase(), uppercase() |
| Confirmation | 263-296 | confirm() with gum fallback |
| Version compare | 302-304 | version_gte() |
| Cleanup handlers | 311-326 | add_cleanup_handler(), trap |
| Clipboard utilities | 333-378 | copy_to_clipboard(), has_clipboard() |

**Key Data**:
- Color codes: RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, BOLD, DIM, RESET
- Platform detection functions
- Logging levels: msg(), info(), success(), warn(), err(), debug()

**Dependencies**: None (pure bash)

---

### `lib/config.sh` (320 lines)
**Configuration management, workspace initialization, model defaults**

| Section | Lines | Purpose |
|---------|-------|---------|
| Configuration paths | 10-24 | Getters for config/session/env/keys files |
| Workspace initialization | 30-116 | init_workspace(), directory creation |
| Config file management | 122-173 | get_default_config(), load_config() |
| Config get/set | 176-212 | config_get(), config_set() with jq |
| Session management | 218-261 | save_session(), load_session() |
| Model defaults | 267-314 | get_default_model(), get_available_models() |

**Default Configuration**:
```json
{
  "version": "2.0.0",
  "model_provider": "gemini",
  "model_name": "2.5-flash",
  "preferences": {
    "auto_estimate": true,
    "confirm_before_generate": true,
    "show_costs": true
  },
  "cost_tracking": { "enabled": true }
}
```

**Available Models by Provider**:
- Gemini: 2.5-flash, 2.5-flash-lite, 2.5-pro, 2.0-flash, 2.0-pro
- Claude: 3-haiku, 3.5-haiku, 3.5-sonnet, 3-opus, sonnet-4-5
- OpenAI: gpt-4o, gpt-4o-mini, gpt-4-turbo, o1, o3
- Groq: llama-3.3-70b, llama-4, mixtral-8x7b
- xAI: grok-beta, grok-4, grok-3
- Ollama: Any local model

**Dependencies**: common.sh, jq

---

### `lib/api.sh` (1,304 lines)
**AI provider integrations, vision API support, cost calculations**

| Section | Lines | Purpose |
|---------|-------|---------|
| Error display | 12-63 | display_api_error() with full details |
| API key management | 84-125 | get_api_key(), has_api_key() |
| Image handling | 132-171 | is_image_file(), encode_image_base64() |
| Token estimation | 178-193 | estimate_tokens(), estimate_file_tokens() |
| Gemini API | 199-312 | call_gemini(), call_gemini_vision() |
| Claude API | 433-597 | call_claude(), call_claude_vision() |
| OpenAI API | 604-750 | call_openai() |
| Groq API | 757-846 | call_groq() |
| xAI/Grok API | 853-986 | call_xai() |
| Ollama API | 992-1087 | call_ollama() (local) |
| Main dispatcher | 1086-1135 | call_api() router |
| Vision dispatcher | 1139-1192 | call_api_with_images() |
| Cost calculations | 1198+ | calculate_cost() per provider |

**Key Functions**:
- `call_api(prompt, provider, model, max_tokens)` - Main dispatcher
- `call_api_with_images(prompt, provider, model, max_tokens, ...images)` - Vision support
- `call_gemini(prompt, model, max_tokens)` - Gemini API call
- `call_claude(prompt, model, max_tokens)` - Claude API call
- `estimate_tokens(text)` - Rough token count (chars/4)
- `calculate_cost(provider, model, input_tokens, output_tokens)` - Cost estimation

**API Providers Supported**: 6 (Gemini, Claude, OpenAI, Groq, xAI, Ollama)

**Vision Support**: 
- Gemini: call_gemini_vision() ✓
- Claude: call_claude_vision() ✓
- Others: Text fallback

**Dependencies**: common.sh, config.sh, jq, curl, age

---

### `lib/modes.sh` (1,146 lines)
**Mode-based workflows (/make, /tweak, /debug), context assembly**

| Section | Lines | Purpose |
|---------|-------|---------|
| Mode state management | 9-47 | Global MODE_* variables |
| Display functions | 49-84 | get_*_display() helpers |
| Menu prompt/instruct | 92-226 | menu_prompt(), menu_instruct() |
| Menu model | 229-301 | menu_model(), menu_model_provider(), menu_model_specific() |
| Menu uploads | 304-420 | menu_uploads(), file browser, output browser |
| Mode execution | 740-960 | mode_run() - MAIN CONTEXT ASSEMBLY |
| Status display | 962+ | Workflow status functions |

**Mode State Variables**:
```bash
MODE_CURRENT=""              # make/tweak/debug
MODE_PROMPT=""               # Text instructions
MODE_INSTRUCT_FILE=""        # File instructions
MODE_UPLOADS=()              # Context files array
MODE_MODEL_PROVIDER=""       # AI provider
MODE_MODEL_NAME=""           # Model name
MODE_CHECK_PROVIDER=""       # Verification provider
MODE_CHECK_MODEL=""          # Verification model
```

**Key Functions**:
- `init_mode(mode)` - Initialize mode state
- `reset_mode()` - Clear mode state
- `menu_prompt()` - Set text instructions
- `menu_instruct()` - Load file instructions
- `menu_uploads()` - Add context files/directories
- `menu_model()` - Select provider and model
- `mode_run()` - **Main execution: Context assembly, API call, cost tracking**
- `menu_file_browser(path)` - Browse files for upload
- `menu_view_outputs()` - View generated outputs

**Context Assembly** (lines 750-838):
1. Load prompt from text or file
2. Identify image files
3. Build text context with file contents
4. Estimate tokens
5. Show cost dialog
6. Dispatch to API (with images if needed)
7. Handle verification (optional)
8. Save output to workspace
9. Log costs to usage.jsonl

**Dependencies**: common.sh, config.sh, api.sh, ui.sh

---

### `lib/ui.sh` (414 lines)
**Terminal UI with gum integration, fallback to basic prompts**

| Section | Lines | Purpose |
|---------|-------|---------|
| Gum availability | 5-20 | Check if gum installed |
| UI header | 25-35 | Display formatted headers |
| Input functions | 40-120 | ui_input(), ui_select(), ui_choose() |
| Confirmation | 125-160 | ui_confirm() |
| Status functions | 165-220 | ui_blink(), ui_clear_line() |
| Fallback methods | Various | Basic implementations without gum |

**Key Functions**:
- `ui_input(prompt)` - Get user text input
- `ui_confirm(prompt, default)` - Yes/No confirmation
- `ui_choose(title, ...options)` - Menu selection
- `ui_select(title, ...options)` - Alternative menu
- `ui_header(title)` - Pretty header display
- `ui_blink(message)` - Animated progress

**Fallback Behavior**:
- If gum available: Beautiful interactive menus
- If gum missing: Plain read/printf prompts
- No functionality lost, just less pretty

**Dependencies**: common.sh

---

### `lib/error.sh` (339 lines)
**Error codes, error handling, diagnostics**

| Section | Lines | Purpose |
|---------|-------|---------|
| Error codes | 1-50 | E_SUCCESS, E_PARAM, E_CONFIG, E_API, etc. |
| Error messages | 55-150 | Error code to message mapping |
| Error display | 155-200 | display_error(), common solutions |
| Retry logic | 205-260 | Handle rate limits, timeouts |
| Diagnostics | 265-339 | Debug info, stack traces |

**Error Codes**:
- E_SUCCESS=0, E_PARAM=1, E_CONFIG=2, E_API=3, E_EXEC=4, E_DEPENDENCY=5, E_RATE_LIMIT=6, E_TIMEOUT=7, E_CANCELLED=130

**Key Functions**:
- `err(message)` - Log error to stderr
- `die(code, message)` - Exit with error code
- `handle_api_error(response)` - Parse API error
- `retry_with_backoff()` - Exponential backoff

**Rate Limit Handling**:
- Detect 429 responses and rate_limit error messages
- Wait 60 seconds
- Retry once

**Dependencies**: common.sh

---

### `lib/security.sh` (416 lines)
**API key management, Age encryption, secure storage**

| Section | Lines | Purpose |
|---------|-------|---------|
| Key storage paths | 10-30 | Determine key file locations |
| Key loading | 35-100 | load_keys(), decrypt with age |
| Key setup | 105-200 | Interactive key configuration |
| Encryption/decryption | 205-280 | age-based encryption |
| Key validation | 285-320 | Check key validity, permissions |
| Cleanup | 325-416 | Secure deletion of temp keys |

**Key Functions**:
- `load_keys()` - Load and decrypt API keys
- `encrypt_keys_interactive()` - Setup encryption
- `get_api_key(provider)` - Retrieve specific key
- `save_keys_encrypted()` - Store encrypted keys
- `validate_api_key(provider)` - Check key works

**Supported Storage**:
1. Environment variables (plain text)
2. ~/.aiwb/.aiwb.env (plain text file)
3. ~/.aiwb/.keys.age (encrypted with age)

**Dependencies**: common.sh, config.sh, jq, age, curl

---

## Configuration Files

### `~/.aiwb/config.json`
**Main configuration file**

```json
{
  "version": "2.0.0",
  "workspace": "/home/user/.aiwb/workspace",
  "model_provider": "gemini",
  "model_name": "2.5-flash",
  "current_task": "",
  "current_project": "",
  "preferences": {
    "auto_estimate": true,
    "confirm_before_generate": true,
    "show_costs": true,
    "stream_output": false,
    "tier_default": "Medium"
  },
  "cost_tracking": {
    "enabled": true,
    "monthly_budget": 0,
    "currency": "USD"
  },
  "security": {
    "encrypt_keys": false,
    "warn_on_exposure": true
  }
}
```

### `~/.aiwb/.session`
**Session state for resuming**

```json
{
  "workspace": "/home/user/.aiwb/workspace",
  "model_provider": "gemini",
  "model_name": "2.5-flash",
  "task": "my_task",
  "project": "my_project",
  "timestamp": "2025-11-10T12:34:56Z"
}
```

### `~/.aiwb/.aiwb.env`
**API keys (unencrypted)**

```bash
export GEMINI_API_KEY="..."
export ANTHROPIC_API_KEY="..."
export OPENAI_API_KEY="..."
export GROQ_API_KEY="..."
export XAI_API_KEY="..."
```

### `~/.aiwb/.keys.age`
**Encrypted API keys (recommended)**

---

## Workspace Structure

```
~/.aiwb/
├── config.json                  # Configuration
├── .aiwb.env                    # API keys (plain)
├── .keys.age                    # API keys (encrypted)
├── .session                     # Session state
└── workspace/
    ├── projects/                # Project folders
    ├── tasks/
    │   └── inbox.prompt.md      # Default task
    ├── outputs/                 # Generated files
    ├── logs/
    │   ├── chat_*.log           # Chat history
    │   └── usage.jsonl          # Cost tracking
    ├── templates/               # User templates
    ├── history/                 # Session history
    └── snapshots/               # Workspace backups
```

---

## Important Code Patterns

### Error Handling Pattern
```bash
function safe_operation() {
    local input="$1"
    [[ -z "$input" ]] && { err "Input required"; return "$E_PARAM"; }
    local result
    result=$(command "$input") || { err "Command failed"; return "$E_EXEC"; }
    echo "$result"
    return 0
}
```

### Platform Detection Pattern
```bash
if is_termux; then
    # Android-specific
elif is_macos; then
    # macOS-specific
else
    # Linux default
fi
```

### Safe Input Pattern
```bash
# With prompt
safe_read -p "Enter value: " var_name

# Without prompt
safe_read var_name

# Falls back: Termux /dev/tty → stdin → error
```

### JSON Configuration Pattern
```bash
# Get config value
value=$(config_get "key.nested")

# Set config value
config_set "key.nested" "newvalue"

# Uses jq internally, never manual JSON editing
```

### API Call Pattern
```bash
# Simple text call
output=$(call_api "$prompt" "provider" "model")

# With images
output=$(call_api_with_images "$prompt" "provider" "model" "" "${images[@]}")

# Check result
if [[ $? -eq 0 ]]; then
    # Success
else
    # Failure already logged
fi
```

---

## Dependencies & Requirements

### Required Tools
- bash (4.0+)
- jq (JSON parsing)
- curl (HTTP requests)

### Optional Tools
- gum (Beautiful terminal UI) - falls back gracefully
- age (API key encryption) - for secure key storage
- ollama (Local models) - only if using Ollama provider

### Platform Support
- Linux (Ubuntu, Debian, Arch, Fedora, etc.)
- macOS (Intel & Apple Silicon)
- Android (Termux)

---

## Function Call Graph

```
aiwb (main)
├─ initialize()
│  ├─ check_dependencies()
│  ├─ init_workspace()
│  ├─ load_config()
│  ├─ load_session()
│  └─ load_keys()
│
├─ cmd_make/tweak/debug()
│  └─ mode_loop()
│      ├─ menu_prompt()
│      ├─ menu_instruct()
│      ├─ menu_uploads()
│      ├─ menu_model()
│      └─ mode_run()
│         ├─ estimate_tokens()
│         ├─ call_api() OR call_api_with_images()
│         │  ├─ call_gemini()
│         │  ├─ call_claude()
│         │  ├─ call_openai()
│         │  ├─ call_groq()
│         │  ├─ call_xai()
│         │  └─ call_ollama()
│         ├─ Save to workspace
│         └─ Track cost
│
├─ cmd_quick()
│  └─ Single call_api()
│
├─ cmd_keys()
│  └─ load_keys() / encrypt_keys_interactive()
│
└─ cmd_settings()
   └─ Configuration UI
```

---

## Testing Entry Points

### Unit Testing
```bash
# Shell syntax check
shellcheck aiwb lib/*.sh

# Manual testing
./aiwb --debug

# Test specific command
./aiwb quick "Create hello world"
```

### Integration Testing
```bash
# Run test suite
./test_aiwb_comprehensive.sh

# Quick functional test
./test_aiwb_functionality.sh

# Health check
./debug_aiwb.sh
```

---

## Total Code Statistics

```
File              Lines    % of Total
────────────────────────────────────
aiwb              1,886    30.4%
lib/api.sh        1,304    21.0%
lib/modes.sh      1,146    18.4%
lib/security.sh     416     6.7%
lib/ui.sh           414     6.7%
lib/common.sh       384     6.2%
lib/config.sh       320     5.2%
lib/error.sh        339     5.5%
────────────────────────────────────
TOTAL             6,209   100.0%
```

**Architecture Score**: Excellent modularity, clear separation of concerns, easy to extend.

