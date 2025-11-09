# Changelog

All notable changes to AIWB will be documented in this file.

## [2.0.1] - 2025-11-09

### 🐛 Fixed

**Critical Fixes:**
- ✅ **Fixed script exit bug** - Resolved issue where aiwb would exit immediately after initialization
  - Fixed `run_cleanup_handlers()` to handle empty cleanup_handlers array with `set -u`
  - Fixed `clear` command failures when TERM environment variable not set
  - Fixed `confirm()` function to gracefully handle missing or inaccessible `/dev/tty`
  - Fixed `chat_loop()` to read from `/dev/tty` for interactive input in Termux
  - **Fixed `load_session()` conditional statements causing exit with `set -e`** (ROOT CAUSE)
  - Script now properly executes commands instead of exiting with "Workspace initialized"
  - Affects all platforms (Linux, macOS, Termux)

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
