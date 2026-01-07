# Scripts Folder

This folder contains development, testing, and utility scripts that are excluded from Claude Code context by default to save tokens.

## What's Here

### Test Scripts
- **test_aiwb_comprehensive.sh** - Comprehensive test suite for all features
- **test_aiwb_functionality.sh** - Core functionality tests
- **test_dependency_check.sh** - Dependency validation
- **test_large_prompt_fix.sh** - Large prompt handling tests
- **test_preflight_cost.sh** - Token cost estimation tests

### Debug Scripts
- **debug_aiwb.sh** - Main debugging utility
- **debug_termux_issue.sh** - Termux-specific debugging

### Platform-Specific Installers
- **install-termux.sh** - Termux installation script
- **termux-clean-install.sh** - Clean Termux installation

### Utility Scripts
- **cleanup.sh** - Repository cleanup and maintenance

## Usage

These scripts are meant for:
- Development and testing during active development
- Troubleshooting specific issues
- Platform-specific installations
- Repository maintenance

## Accessing Scripts in Claude Code

By default, these scripts are ignored to save context tokens. To access them:

1. **Explicitly request**: "Read scripts/test_aiwb_comprehensive.sh"
2. **Temporarily lift the ban**: Ask Claude to read from the scripts folder
3. **Modify .claude/settings.json**: Remove or comment out the `scripts/**` ignore pattern

## Essential Scripts (In Root)

The main installation scripts remain in the repo root:
- **install.sh** - Main installation script
- **uninstall.sh** - Main uninstallation script
