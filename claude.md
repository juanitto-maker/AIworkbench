# Claude Code Project Guidelines

## 🎯 Context Focus Strategy

This project uses a **token-saving strategy** to optimize Claude Code sessions. Follow these guidelines to minimize unnecessary context usage.

## 📂 What to Focus On

**PRIMARY CONTEXT** - Always available and relevant:
- `/lib/**` - Core application code (shell scripts)
- `/bin-edit/**` - Binary editing utilities
- `/completions/**` - Shell completion scripts
- Root-level essential docs:
  - `README.md` - Project overview
  - `QUICKSTART.md` - Getting started guide
  - `QUICK_REFERENCE.md` - Command reference

**MAIN EXECUTABLES**:
- `aiwb` - Main application binary
- `install.sh` - Installation script
- `uninstall.sh` - Uninstallation script

## 🚫 What to Ignore (Unless Explicitly Requested)

**DO NOT** read these folders unless specifically asked:

### `/docs/**` - Documentation Archive
Contains comprehensive documentation excluded by default:
- Legal files (LICENSE, CODE_OF_CONDUCT)
- Contributor guides (CONTRIBUTING, DEVELOPER_GUIDE)
- Architecture docs, audit reports, roadmaps
- Platform-specific guides (Termux documentation)
- **Exception**: Only read if user explicitly requests (e.g., "Read the audit report", "Show me CONTRIBUTING.md")

### `/scripts/**` - Development Scripts
Contains test, debug, and utility scripts:
- Test suites (`test_*.sh`)
- Debug utilities (`debug_*.sh`)
- Platform installers (`install-termux.sh`)
- **Exception**: Only read when debugging or explicitly requested

### `/examples/**` - Example Files
Example configurations and usage demos.

### `/templates/**` - Template Files
Prompt templates and boilerplate files.

### Additional Ignore Patterns
- `**/*.pdf` - PDF documentation
- `**/*.docx` - Word documents
- `**/*.png`, `**/*.jpg`, `**/*.jpeg`, `**/*.gif` - Image files (unless debugging UI)
- Generated HTML files

## 💡 Working with Ignored Content

If you need something from an ignored folder:

1. **User explicitly names a file**:
   - "Read docs/DEVELOPER_GUIDE.md" → Ask if they want to lift the restriction or proceed

2. **Temporary access needed**:
   - Ask: "Would you like me to access the docs folder for this? It's normally excluded to save tokens."

3. **Permanent changes needed**:
   - Edit `.claude/settings.json` to remove ignore patterns

## 🔧 Typical Session Focus

For most coding sessions, focus on:
- Understanding the codebase in `/lib`
- Modifying core functionality
- Adding new features to existing modules
- Bug fixes and improvements
- Testing with the main `aiwb` executable

**Only expand context** when:
- User asks for documentation updates
- Debugging requires reading test scripts
- Contributing guidelines are needed
- Architecture review is requested

## 📝 Best Practices

1. **Start minimal**: Begin with just the files you need
2. **Expand gradually**: Add context only when necessary
3. **Ask before reading**: If unsure about reading ignored content, ask the user first
4. **Respect the structure**: The ignore patterns exist for a reason - to keep sessions efficient

---

**Note**: This configuration is enforced by `.claude/settings.json`. Modify that file to change ignore patterns permanently.
