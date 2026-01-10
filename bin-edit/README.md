# Bin-Edit Scripts

This directory contains helper scripts for AIworkbench (AIWB) internal operations. These scripts support various workflows, task management, and AI provider interactions.

## Overview

The bin-edit scripts are organized into several categories:

### Core Orchestration Scripts

- **`aiwb.sh`** - AIworkbench orchestrator (chat-first TUI)
  - Default interaction is chat mode
  - Handles workspace initialization and key management
  - Supports slash commands for various operations

- **`chat-runner.sh`** - Agent runner for AIworkbench
  - Manages task workflows (estimate, generate, tweak, debug)
  - Provides JSON-based planning and confirmation
  - Cross-platform support (Termux/Linux/macOS)

### AI Provider Scripts

#### Claude Provider
- **`claude-runner.sh`** - Claude-specific API runner
- **`cgo.sh`** - Claude code generation
- **`cout.sh`** - Claude output handler
- **`cpre.sh`** - Claude preprocessing/estimation

#### Gemini Provider
- **`gemini-runner.sh`** - Gemini-specific API runner
- **`ggo.sh`** - Gemini code generation
- **`gout.sh`** - Gemini output handler
- **`gpre.sh`** - Gemini preprocessing/estimation
- **`gmodel.sh`** - Gemini model management
- **`gsync.sh`** - Gemini synchronization utilities

> **Note:** The main AIWB application now uses `lib/api.sh` for API calls. The provider-specific runners are maintained for backward compatibility with the bin-edit workflow system.

### AI Utility Scripts

- **`ai-buildprompt.sh`** - Constructs prompts with context
- **`ai-clean.sh`** - Cleans up generated files and temporary data
- **`ai-cost.sh`** - Estimates API call costs
- **`ai-helpers.sh`** - Common helper functions
- **`ai-img.sh`** - Image handling and processing
- **`ai-preflight.sh`** - Pre-execution validation and checks
- **`ai-prev.sh`** - Preview generated content before applying
- **`ai-snap.sh`** - Creates snapshots of project state

### Task Management Scripts

Task management follows the pattern: `t<action>.sh`

- **`tnew.sh`** - Create new task
- **`tedit.sh`** - Edit existing task
- **`tlist.sh`** - List all tasks
- **`tstatus.sh`** - Show task status
- **`tdone.sh`** - Mark task as complete
- **`tset.sh`** - Set task properties
- **`tdelete.sh`** - Delete task
- **`tclean.sh`** - Clean completed tasks
- **`tid.sh`** - Get/set task ID
- **`ptasks.sh`** - Project task operations

### Project Management Scripts

Project management follows the pattern: `p<action>.sh`

- **`pset.sh`** - Set project properties
- **`pstatus.sh`** - Show project status
- **`plog.sh`** - View project logs

### Upload/Context Management Scripts

Upload management follows the pattern: `u<action>.sh`

- **`uin.sh`** - Add files to upload context
- **`uls.sh`** - List files in upload context
- **`uclear.sh`** - Clear upload context

### Utility Scripts

- **`bincheck.sh`** - Verify binary dependencies
- **`binpush.sh`** - Deploy/update binary tools
- **`envkeys.sh`** - Environment and API key management
- **`fixexec.sh`** - Fix executable permissions
- **`keys-setup.sh`** - Initial API key setup
- **`paths.sh`** - Path resolution utilities
- **`quote.sh`** - String quoting/escaping utilities
- **`snap.sh`** - Snapshot utilities
- **`wbhelp.sh`** - Workbench help display
- **`wlog.sh`** - Workbench logging

## Usage

These scripts are typically called internally by the main AIWB application. However, they can be used directly for advanced workflows or automation.

### Example: Direct Task Creation

```bash
# Create a new task
./bin-edit/tnew.sh "Implement user authentication"

# List tasks
./bin-edit/tlist.sh

# Mark task as done
./bin-edit/tdone.sh 1
```

### Example: Add Files to Context

```bash
# Add files to upload context
./bin-edit/uin.sh src/main.js src/config.js

# List context
./bin-edit/uls.sh

# Clear context
./bin-edit/uclear.sh
```

## Architecture Notes

### Workflow System

The bin-edit scripts implement a separate task-based execution system that complements the main AIWB chat interface:

1. **Planning Phase** (`chat-runner.sh`) - Analyzes tasks and creates execution plans
2. **Estimation Phase** (`cpre.sh`/`gpre.sh`) - Estimates costs and complexity
3. **Generation Phase** (`cgo.sh`/`ggo.sh`) - Generates code or content
4. **Output Phase** (`cout.sh`/`gout.sh`) - Processes and displays results

### Design Philosophy

- **Cross-platform compatibility** - Works on Linux, macOS, and Termux (Android)
- **Minimal dependencies** - Requires only bash, jq, and curl
- **Optional enhancements** - Uses `gum` for better UX when available
- **Fail-safe defaults** - Graceful degradation when tools are missing

## Development Guidelines

When modifying or adding scripts:

1. **Follow naming conventions**:
   - AI utilities: `ai-<function>.sh`
   - Task operations: `t<action>.sh`
   - Project operations: `p<action>.sh`
   - Upload operations: `u<action>.sh`

2. **Include header comments**:
   ```bash
   #!/usr/bin/env bash
   # script-name.sh - Brief description
   # - Key feature 1
   # - Key feature 2
   ```

3. **Use standard helper functions**:
   ```bash
   have()  { command -v "$1" >/dev/null 2>&1; }
   err()   { printf "\033[1;31mEE\033[0m %s\n" "$*" >&2; }
   warn()  { printf "\033[1;33m!!\033[0m %s\n" "$*" >&2; }
   msg()   { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
   ```

4. **Set proper error handling**:
   ```bash
   set -o pipefail
   ```

5. **Support cross-platform operations**:
   - Check for platform-specific commands
   - Provide fallbacks for missing tools
   - Handle path differences (Termux vs standard Unix)

## Deprecation Notice

Some scripts may be marked for deprecation as functionality is consolidated into the main `lib/` modules:

- **Provider-specific runners** - Being consolidated into `lib/api.sh`
- **Duplicate utilities** - Moving to `lib/common.sh`

Check individual script headers for deprecation warnings and migration guidance.

## Related Documentation

- [Main AIWB Documentation](../docs/README.md)
- [Usage Guide](../docs/USAGE.md)
- [Developer Guide](../docs/DEVELOPER_GUIDE.md)
- [Architecture Analysis](../docs/ARCHITECTURE_ANALYSIS.md)

## Support

For issues or questions about these scripts:
1. Check the main AIWB help: `aiwb --help`
2. Review the documentation in the `docs/` directory
3. Open an issue in the project repository
