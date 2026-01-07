# Repository Token Optimization Setup

Please analyze this repository and organize it for optimal Claude Code token usage. Follow this comprehensive strategy:

## Phase 1: Repository Analysis

First, analyze the current repository structure:

1. **List all root-level files and directories**
   - Identify all `.md`, `.txt`, `.pdf`, `.docx` files in root
   - List all directories and their purposes
   - Check for existing `.claude/` configuration

2. **Categorize by importance for coding sessions**:

   **ESSENTIAL (Keep in root)**:
   - Main README.md (project overview)
   - Quick start/getting started guides
   - Quick reference/cheat sheets
   - Main installation scripts (install.sh, setup.py, etc.)
   - Core configuration files (.gitignore, package.json, requirements.txt, etc.)
   - Architecture diagram/overview (if brief and critical)

   **MOVE TO `docs/`**:
   - LICENSE, CODE_OF_CONDUCT.md
   - CHANGELOG.md, HISTORY.md
   - CONTRIBUTING.md
   - Detailed developer guides
   - API documentation (if extensive)
   - Architecture deep-dives
   - Audit reports, compliance docs
   - Design proposals, RFCs
   - Platform-specific installation guides
   - Migration guides
   - Troubleshooting guides (unless frequently needed)

   **MOVE TO `scripts/`** (create if needed):
   - Test scripts (test_*.sh, run_tests.py, etc.)
   - Debug utilities
   - Build scripts (if not essential)
   - Deployment scripts
   - Database migration scripts
   - Data seeding/fixture scripts
   - Performance profiling scripts
   - CI/CD helper scripts (keep .github/workflows/ in place)

   **MOVE TO `examples/`** (create if needed):
   - Sample configurations
   - Usage examples
   - Demo applications
   - Tutorial files

   **MOVE TO `templates/`** (create if needed):
   - Boilerplate files
   - Code templates
   - Prompt templates

## Phase 2: File Organization

Execute the reorganization:

1. **Create necessary directories**:
   ```bash
   mkdir -p docs scripts examples templates
   ```

2. **Move files to appropriate locations**:
   - Use `git mv` to preserve history
   - Move files in logical groups
   - Create README.md in each new folder explaining its contents

3. **Update any references**:
   - Search for broken links in README.md
   - Update paths in documentation
   - Fix references in scripts

## Phase 3: Configure Claude Code

1. **Create `.claude/settings.json`**:
   ```json
   {
     "$schema": "https://raw.githubusercontent.com/anthropics/claude-code/main/settings-schema.json",
     "ignorePaths": [
       "docs/**",
       "scripts/**",
       "examples/**",
       "templates/**",
       "**/*.pdf",
       "**/*.docx",
       "**/*.pptx",
       "**/*.png",
       "**/*.jpg",
       "**/*.jpeg",
       "**/*.gif",
       "**/*.svg",
       "**/node_modules/**",
       "**/__pycache__/**",
       "**/venv/**",
       "**/vendor/**",
       "**/dist/**",
       "**/build/**",
       "**/.next/**",
       "**/coverage/**"
     ]
   }
   ```

   Adjust based on project type:
   - **Node.js**: Add `node_modules`, `dist`, `build`, `.next`
   - **Python**: Add `__pycache__`, `venv`, `.venv`, `*.pyc`
   - **Ruby**: Add `vendor`, `.bundle`
   - **Java**: Add `target`, `.gradle`, `build`
   - **Go**: Add `vendor`, `bin`
   - **Rust**: Add `target`

2. **Create `claude.md` in root**:
   ```markdown
   # Claude Code Project Guidelines

   ## 🎯 Context Focus Strategy

   This project uses token-saving to optimize Claude Code sessions.

   ## 📂 Primary Context (Always Available)

   Focus on these directories for typical coding sessions:
   - `/src` or `/lib` - Main source code
   - `/tests` - Test files (when working on tests)
   - `/config` - Configuration files
   - Root docs: README.md, QUICKSTART.md

   ## 🚫 Ignored by Default

   **DO NOT read unless explicitly requested:**

   ### `/docs/**` - Documentation Archive
   - Contributing guides, developer docs
   - Architecture deep-dives
   - Compliance and audit reports
   - **Exception**: Read only when user explicitly requests

   ### `/scripts/**` - Utility Scripts
   - Test runners, build scripts
   - Debug utilities, deployment scripts
   - **Exception**: Read when debugging or explicitly requested

   ### `/examples/**` & `/templates/**`
   - Sample code and boilerplate
   - **Exception**: Read when user asks for examples

   ### File Types Always Ignored
   - Images: `**/*.png`, `*.jpg`, `*.svg`
   - Documents: `**/*.pdf`, `*.docx`
   - Build artifacts: `dist/`, `build/`, `node_modules/`

   ## 💡 Working with Ignored Content

   If you need something from ignored folders:
   1. **User names specific file**: Ask if they want to lift restriction
   2. **Temporarily needed**: Request permission first
   3. **Permanent access**: Edit `.claude/settings.json`

   ## 🔧 Typical Session Focus

   For most sessions, focus on:
   - Understanding core source code
   - Implementing features
   - Fixing bugs
   - Writing/updating tests

   **Only expand context when**:
   - User requests documentation updates
   - Contributing guidelines needed
   - Examples or templates required
   ```

3. **Create `docs/README.md`**:
   Document what's in the docs folder and how to access it.

4. **Create `scripts/README.md`**:
   Document available scripts and their purposes.

## Phase 4: Verification

1. **Check the final structure**:
   ```bash
   # Show clean root directory
   ls -la

   # Verify docs folder
   ls docs/

   # Verify scripts folder
   ls scripts/
   ```

2. **Test the configuration**:
   - Verify `.claude/settings.json` is valid JSON
   - Ensure no broken links in documentation
   - Check that essential files remain accessible

## Phase 5: Git Commit

Create clear commits:

1. **First commit**: "Organize documentation for token optimization"
   - Move docs to docs/
   - Create docs/README.md

2. **Second commit**: "Move scripts to dedicated folder"
   - Move scripts to scripts/
   - Create scripts/README.md

3. **Third commit**: "Add Claude Code token optimization config"
   - Add .claude/settings.json
   - Add claude.md
   - Update any broken references

## Expected Outcome

**Root directory should contain**:
- Essential documentation (README, QUICKSTART)
- Core configuration files
- Main installation scripts
- Source code directories (src/, lib/, app/, etc.)
- Test directories (if frequently used)
- Standard project files (.gitignore, package.json, etc.)

**Organized folders**:
- `docs/` - All extensive documentation
- `scripts/` - All utility/development scripts
- `examples/` - Sample code and demos
- `templates/` - Boilerplate and templates

**Configuration**:
- `.claude/settings.json` - Technical ignore patterns
- `claude.md` - Human-readable guidelines
- README files in organized folders

## Project-Specific Adjustments

Customize based on project type:

**Web Application (React/Next.js/Vue)**:
- Keep: `package.json`, `tsconfig.json`, main `README.md`
- Focus: `/src`, `/components`, `/pages`, `/app`
- Ignore: `/public/images`, `/dist`, `/build`, `/.next`

**Python Application**:
- Keep: `requirements.txt`, `pyproject.toml`, `setup.py`, main `README.md`
- Focus: `/src`, `/app`, main package directory
- Ignore: `__pycache__`, `/venv`, `*.pyc`, `/dist`

**API/Backend**:
- Keep: Main config, API docs overview, README
- Focus: `/src`, `/api`, `/routes`, `/controllers`, `/models`
- Ignore: Extensive API docs (move to docs/api/)

**CLI Tool**:
- Keep: Installation instructions, quick reference, README
- Focus: Main executable, `/lib`, `/src`
- Ignore: Detailed user guides (move to docs/)

**Library/Package**:
- Keep: README, installation, quick start
- Focus: `/src`, `/lib`, main package code
- Ignore: Examples (move to examples/), extensive guides (move to docs/)

## Notes

- Always use `git mv` to preserve file history
- Update all documentation references
- Create README files in new folders
- Test that nothing breaks after reorganization
- Commit in logical, atomic steps
- This is a ONE-TIME setup per repository
- Future sessions will automatically benefit from token savings

---

**After running this setup, typical Claude Code sessions will use 40-60% fewer tokens by excluding non-essential content while keeping critical development context readily available.**
