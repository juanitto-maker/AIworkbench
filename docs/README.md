# Documentation Folder

This folder contains less frequently needed documentation that is excluded from Claude Code context by default to save tokens.

## What's Here

### Project Documentation
- **APP_AUDIT_REPORT.md** - Comprehensive application audit report
- **CHANGELOG.md** - Version history and changes
- **IMPLEMENTATION_ROADMAP.md** - Development roadmap and planning

### Contributor Guides
- **CODE_OF_CONDUCT.md** - Community guidelines and expectations
- **CONTRIBUTING.md** - How to contribute to the project
- **DEVELOPER_GUIDE.md** - Advanced development information
- **TESTING_GUIDE.md** - Testing practices and procedures

### Platform-Specific Docs
- **TERMUX_INSTALL.md** - Termux installation instructions
- **TERMUX_SESSION_RECOVERY.md** - Termux troubleshooting
- **TERMUX_MOBILE_STRATEGY.md** - Mobile platform strategy

### Design & Architecture
- **ARCHITECTURE_ANALYSIS.md** - System architecture overview
- **CONTEXT_PERSISTENCE_PROPOSAL.md** - Context persistence design
- **CONTEXT_GUIDE.md** - Guide to context management
- **CODE_MAP.md** - Codebase structure map

### Feature Documentation
- **SWARM_MODE_IMPLEMENTATION.md** - Swarm mode technical details
- **SWARM_MODE_USER_GUIDE.md** - Swarm mode user guide
- **GITHUB_INTEGRATION.md** - GitHub integration features

### Troubleshooting
See the `troubleshooting/` subfolder for specific issue fixes.

## Accessing These Docs in Claude Code

By default, these docs are ignored to save context tokens. To access them in a Claude Code session:

1. **Explicitly request a specific file**: "Read docs/CONTRIBUTING.md"
2. **Temporarily lift the ban**: Ask Claude to read from the docs folder
3. **Modify .claude/settings.json**: Remove or comment out the `docs/**` ignore pattern

## Essential Docs (In Root)

The following docs remain in the repo root for quick access:
- **README.md** - Project overview and main documentation
- **QUICKSTART.md** - Getting started quickly
- **QUICK_REFERENCE.md** - Quick command reference
