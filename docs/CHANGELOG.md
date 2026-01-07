# Changelog

All notable changes to AIWB will be documented in this file.

## [3.0.0] - 2026-01-01

### 🎉 Major Release - GitHub Integration & Enhanced Workflows

This major release introduces comprehensive GitHub integration and significant UX improvements to mode-based workflows.

### ✨ Added

**GitHub Integration (v3.0):**
- ✅ **Unified `/github sync` Command** - Intelligent sync workflow replaces status/pull/push dance
  - Fetches from remote silently in background
  - Shows ahead/behind status with commit details
  - Intelligently handles 4 scenarios: in sync, behind, ahead, or diverged
  - Interactive prompts for pull/push operations (Y/n with yes default)
  - Lists commits with `git log --oneline --no-decorate` for clarity
  - Auto-resolves diverged branches with pull-then-push workflow
- ✅ **Comprehensive Git Operations** - Full git command suite:
  - `github status` - Enhanced status with auto-fetch for accurate ahead/behind
  - `github clone` - Clone repositories
  - `github add/commit/push/pull/fetch` - All basic git operations
  - `github sync` - NEW: Unified sync workflow
- ✅ **Branch Management** - Create, switch, delete, list branches
- ✅ **Issue Management** - List, view, create, close, comment on issues
- ✅ **Pull Request Management** - List, view, create, merge, close PRs
- ✅ **Workflow/CI Operations** - View and re-run GitHub Actions workflows
- ✅ **Interactive Menus** - Full TUI menus for `/github` command
  - Main menu with all operations
  - Sync option in interactive menu
  - Sub-menus for branches, issues, PRs, workflows
- ✅ **Secure Authentication** - GitHub PAT storage with encryption support
- ✅ **Documentation** - Comprehensive 820-line guide (docs/GITHUB_INTEGRATION.md)

**Enhanced Mode System:**
- ✅ **Renamed "Uploads" to "Context/Uploads"** - Clearer labeling throughout mode menus
- ✅ **"Current repo/folder" Quick-Add** - One-click option to add `pwd` to context
  - First option in Context/Uploads menu
  - No need to browse or type path manually
  - Instant context addition for current working directory
- ✅ **Updated Status Display** - Shows "Context/Uploads:" in mode status

**Universal Folder Scanning:**
- ✅ **`/smartscan` for ANY Folder** - No longer requires git repository
  - Works with local directories, not just git repos
  - Uses `detect_repo` for consistency with `/scanrepo`
  - Shows folder info whether git or not
  - Updated prompts to say "folder" instead of "repository"
- ✅ **Consistent Scanning** - Both `/smartscan` and `/scanrepo` work anywhere

### 🔧 Fixed

**GitHub Integration:**
- ✅ Auto-fetch in `github status` for accurate ahead/behind counts
- ✅ Proper error handling for network issues
- ✅ Conflict detection and user guidance
- ✅ Detached HEAD handling in sync command

**Mode System:**
- ✅ Clearer context file labeling (Context/Uploads vs Uploads)
- ✅ Faster workflow when working in current directory

**Scanning:**
- ✅ `/smartscan` no longer fails on non-git folders
- ✅ Consistent behavior between smart and full scans

### 🚀 Improved

**Developer Experience:**
- ✅ **Streamlined Git Workflow** - Single `sync` command replaces multiple steps
  - Old way: `status` → `pull` (if behind) → `push` (if ahead)
  - New way: `sync` (handles everything intelligently)
- ✅ **Better Context Management** - Quick-add current folder option
- ✅ **Flexible Scanning** - Analyze any folder structure
- ✅ **Comprehensive Help** - Updated help text in 3 locations:
  - `aiwb --help` (main CLI help)
  - `/help` (interactive chat help)
  - `aiwb github help` (GitHub-specific help)

**User Experience:**
- ✅ **Intelligent Prompting** - Sync command shows what will happen before doing it
- ✅ **Clear Commit Visibility** - See exactly what commits you're pulling/pushing
- ✅ **Safer Operations** - Confirmation prompts prevent accidental pushes/pulls
- ✅ **Clearer Labels** - "Context/Uploads" vs generic "Uploads"

### 📚 Documentation

- ✅ **docs/GITHUB_INTEGRATION.md** - Complete 820-line integration guide
  - Quick Start examples
  - All command references
  - Workflow examples
  - Architecture documentation
  - Troubleshooting guide
  - Comparison with Claude Code
- ✅ **Updated Main Help** - Added sync to all help locations
- ✅ **Inline Examples** - Example outputs for all sync scenarios

### 🎯 Breaking Changes

None! This release is fully backward compatible with v2.x.

### 📊 Statistics

- **New Commands**: 1 (`/github sync`)
- **Enhanced Commands**: 2 (`/smartscan`, `/github status`)
- **Files Changed**: 4 (aiwb, lib/github.sh, lib/modes.sh, docs/GITHUB_INTEGRATION.md)
- **Lines Added**: ~350
- **Documentation**: 1 comprehensive guide (820 lines)
- **New Features**: 3 major (GitHub sync, Context/Uploads rename, universal scanning)

### 🔄 Migration from 2.x

No migration needed! All v2.x features work exactly as before. New features are additions:

```bash
# New unified sync workflow (recommended)
aiwb github sync

# Traditional workflow still works
aiwb github status
aiwb github pull
aiwb github push
```

---

## [2.0.1] - 2025-11-09

### 🐛 Fixed

**Critical Fixes:**
- ✅ **Fixed script exit bug and Termux intermittent failures** - Resolved issue where aiwb would exit immediately or fail randomly in error loops
  - Fixed `run_cleanup_handlers()` to handle empty cleanup_handlers array with `set -u`
  - Fixed `clear` command failures when TERM environment variable not set
  - **Fixed `load_session()` conditional statements causing exit with `set -e`** (ROOT CAUSE #1)
  - **Created unified `safe_read()` function for Termux compatibility** (ROOT CAUSE #2 - INTERMITTENT FAILURES)
    - **Eliminated redundant and conflicting `/dev/tty` handling** that caused error loops in Termux
    - Previous code had inconsistent approaches causing intermittent behavior:
      - `confirm()` used `( : < /dev/tty ) 2>/dev/null` test
      - `chat_loop()` used `[[ -c /dev/tty ]] && [[ -r /dev/tty ]]` test
      - These different tests behaved differently in Termux, causing "working, then bug, then working" cycles
    - New `safe_read()` provides single, unified, Termux-aware input handling:
      - Prefers /dev/tty in Termux (most reliable for Android/Termux)
      - Falls back to stdin gracefully if /dev/tty unavailable
      - Uses file descriptor 3 to avoid conflicts with stdin/stdout/stderr
      - Proper error handling compatible with `set -e`
    - Updated all input functions to use `safe_read()`:
      - `confirm()`, `ui_choose()`, `ui_input()`, `ui_filter()`, `ui_choose_multi()`, `chat_loop()`
    - **Eliminates intermittent "error loop" behavior** - no more random failures
  - Script now properly executes commands instead of exiting with "Workspace initialized"
  - Affects all platforms (Linux, macOS, Termux) - **especially critical for Termux reliability**

- ✅ **Fixed API blocking issue** - Resolved hanging/blocking when making API calls (especially in Termux)
  - Added connection timeout (10s) and max request time (300s) to all API calls
  - Fixed stderr redirection buffering issues with `--no-buffer` flag and `2>&1` removal
  - Improved error handling to properly display API errors instead of silent failures
  - Affects all providers: Groq, OpenAI, Claude, Gemini, and Ollama
  - Particularly impacts mobile/Termux environments where network buffering can cause hangs

- ✅ **Updated Groq default model** - Migrated from decommissioned llama-3.1-70b-versatile to llama-3.3-70b-versatile
  - Old model was decommissioned by Groq and caused silent failures
  - New model offers better performance and tool use capabilities
  - Updated default model, available models list, and pricing information

- ✅ **Fixed gum join failures** - Added error handling for gum join commands
  - Fixed early exit issues when gum join fails in Termux/mobile environments
  - Added fallback rendering when gum join is unavailable or fails
  - Affects ui_show_status and ui_join functions

**Enhancements:**
- ✅ **Added xAI/Grok support** - Full integration for xAI's Grok models
  - Added grok-beta, grok-code-fast-1, grok-2, and grok-2-mini models
  - OpenAI-compatible API implementation
  - Pricing information: grok-beta $5 input / $15 output per 1M tokens
  - Free $25 API credits per month during beta
- ✅ **Added Groq vision models** - llama-3.2-11b-vision-preview and llama-3.2-90b-vision-preview
- ✅ **Expanded Groq model support** - Added llama-3.2-1b-preview and llama-3.2-3b-preview for lightweight tasks

## [2.0.0] - 2025-11-08

### 🎉 Major Release - Complete Refactor

This is a complete rewrite of AIWB with focus on cross-platform compatibility, security, and user experience.

### ✨ Added

**Core Features:**
- ✅ **Automated Generator-Verifier Loop** - True multi-model collaboration with `aiwb refine`
- ✅ **Beautiful TUI Interface** - Modern terminal UI with gum integration
- ✅ **Multi-Provider Support** - Gemini, Claude, OpenAI, and Ollama (local)
- ✅ **Secure Key Management** - Encrypted storage with age, proper permissions
- ✅ **Real-Time Cost Tracking** - Monitor spending as you work
- ✅ **Session Management** - History, replay, and export capabilities
- ✅ **Template System** - Reusable prompts for common tasks
- ✅ **Shell Completion** - Tab completion for bash and zsh

**Infrastructure:**
- ✅ **Shared Library System** - Modular, maintainable codebase
  - `lib/common.sh` - Platform detection and utilities
  - `lib/config.sh` - Configuration management
  - `lib/ui.sh` - Beautiful TUI components
  - `lib/api.sh` - API interaction layer
  - `lib/error.sh` - Comprehensive error handling
  - `lib/security.sh` - Secure key management

**User Experience:**
- ✅ **Interactive Menus** - Intuitive navigation with gum or fallback
- ✅ **Progress Indicators** - Spinners and progress bars
- ✅ **Helpful Error Messages** - Actionable solutions for every error
- ✅ **Cost Estimation** - Before-and-after cost tracking
- ✅ **Health Check** - `aiwb doctor` to diagnose issues

**Documentation:**
- ✅ **Quick Start Guide** - Get running in 5 minutes
- ✅ **Comprehensive Examples** - Real-world usage scenarios
- ✅ **Template Library** - REST API, code review, debugging
- ✅ **Enhanced README** - Clear, accurate documentation

**Security:**
- ✅ **API Key Encryption** - Optional age-based encryption
- ✅ **Security Audit** - Check for exposed keys
- ✅ **Proper Permissions** - 600 on sensitive files
- ✅ **Git Protection** - .gitignore prevents key commits

### 🔧 Fixed

**Cross-Platform Compatibility:**
- ✅ Fixed ALL shebangs (40+ scripts) from Termux-specific to universal `#!/usr/bin/env bash`
- ✅ Removed hardcoded paths (`/data/data/com.termux/*`)
- ✅ Platform detection for Linux, macOS, and Termux
- ✅ Workspace auto-detection (Android-visible on Termux, ~/.aiwb elsewhere)

**Code Quality:**
- ✅ Consistent error handling across all scripts
- ✅ Proper exit codes
- ✅ No more silent failures
- ✅ Comprehensive debug mode

### 🚀 Improved

**Performance:**
- ✅ Faster startup with lazy loading
- ✅ Efficient API calls with retry logic
- ✅ Better caching and session management

**Developer Experience:**
- ✅ Cleaner codebase with shared libraries
- ✅ Easier to extend with new providers
- ✅ Better separation of concerns
- ✅ Comprehensive error messages

### 📚 Documentation

- ✅ **QUICKSTART.md** - 5-minute getting started guide
- ✅ **ENHANCEMENT_PROPOSALS.md** - Detailed analysis and roadmap
- ✅ **examples/** - Real-world usage examples
- ✅ **templates/** - Reusable prompt templates
- ✅ **.gitignore** - Protect sensitive data

### 🔄 Changed

**Breaking Changes:**
- ⚠️ **New command structure**: `aiwb <command>` instead of separate scripts
- ⚠️ **Config location**: Now uses `~/.aiwb/config.json` (migrates automatically)
- ⚠️ **Workspace structure**: Organized with proper directories

**Deprecation:**
- ⚠️ Old scripts in `bin-edit/` still work but are deprecated
- ⚠️ Use new `aiwb` command for all operations
- ⚠️ Migration path provided for existing users

### 🏗️ Architecture

**New Structure:**
```
AIworkbench/
├── aiwb                    # New main entry point
├── lib/                    # Shared libraries
│   ├── common.sh
│   ├── config.sh
│   ├── ui.sh
│   ├── api.sh
│   ├── error.sh
│   └── security.sh
├── completions/            # Shell completions
│   ├── aiwb.bash
│   └── aiwb.zsh
├── templates/              # Prompt templates
│   ├── rest-api.prompt.md
│   ├── code-review.prompt.md
│   └── debug-helper.prompt.md
├── examples/               # Usage examples
│   ├── 01-first-chat.md
│   └── 02-code-generation.md
└── bin-edit/               # Legacy scripts (deprecated)
```

### 🎯 Migration Guide

For existing users:

```bash
# Backup your old workspace
cp -r ~/storage/shared/aiwb ~/storage/shared/aiwb.backup

# New workspace will be created automatically
aiwb

# Import old tasks if needed
cp ~/storage/shared/aiwb.backup/tasks/* ~/.aiwb/workspace/tasks/
```

### 🙏 Contributors

This release represents a complete overhaul based on critical user feedback and professional code review.

### 📊 Statistics

- **Files Changed**: 50+
- **Lines Added**: ~5,000
- **Bugs Fixed**: 15+ critical issues
- **New Features**: 12 major additions
- **Documentation**: 8 new guides

---

## [1.0.0] - Previous Release

Initial release with basic Gemini/Claude support (Termux-only).

### Known Issues (Fixed in 2.0)
- ❌ Termux-only (hardcoded paths)
- ❌ No automated loops
- ❌ Plaintext API keys
- ❌ Missing documentation
- ❌ No error handling

---

For full details, see [ENHANCEMENT_PROPOSALS.md](ENHANCEMENT_PROPOSALS.md)
