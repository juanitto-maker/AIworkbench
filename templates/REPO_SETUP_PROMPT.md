# Quick Start: Repository Token Optimization

Copy and paste this prompt to Claude Code when starting work on any new repository:

---

## 📋 PROMPT START

Please help me optimize this repository for Claude Code token usage:

1. **Analyze the repository structure** and identify:
   - Essential files needed for typical coding sessions (keep in root)
   - Documentation that can be moved to `docs/` folder
   - Scripts that can be moved to `scripts/` folder
   - Examples that can be moved to `examples/` folder

2. **Reorganize the files**:
   - Create `docs/`, `scripts/`, `examples/`, `templates/` folders as needed
   - Move non-essential files using `git mv` to preserve history
   - Keep in root: README.md, QUICKSTART.md, core config files, main install scripts
   - Move to docs/: LICENSE, CONTRIBUTING, CHANGELOG, detailed guides, architecture docs
   - Move to scripts/: test scripts, debug utilities, build scripts
   - Create README.md in each new folder explaining its contents

3. **Create `.claude/settings.json`** with ignore patterns:
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
       "**/*.png",
       "**/*.jpg"
     ]
   }
   ```
   Add project-specific patterns (node_modules, venv, dist, build, etc.)

4. **Create `claude.md`** in root with guidelines:
   - What to focus on (main source code directories)
   - What's ignored by default (docs, scripts, examples)
   - How to access ignored content when needed
   - Project-specific context rules

5. **Update any broken references** in documentation

6. **Commit the changes** in logical steps:
   - First: Move docs
   - Second: Move scripts
   - Third: Add Claude config files

For detailed instructions, see: `templates/repo-token-optimization.prompt.md`

## 📋 PROMPT END

---

## Result

After this setup, your Claude Code sessions will:
- ✅ Use 40-60% fewer tokens automatically
- ✅ Focus on relevant code during development
- ✅ Still allow access to docs/scripts when needed
- ✅ Work consistently across all sessions

## Project Types

The prompt adapts to:
- **Web apps** (React, Vue, Next.js)
- **Python** projects (Django, Flask, FastAPI)
- **Node.js** backend APIs
- **CLI tools** and scripts
- **Libraries** and packages
- **Any other** project type

## When to Use

Run this **once per repository** when:
- Starting a new project with Claude Code
- First time working on an existing repo
- Repo has grown and has lots of documentation
- You want to reduce token costs

## Files Created

After running the prompt, you'll have:
- `.claude/settings.json` - Automatic ignore patterns
- `claude.md` - Project-specific guidelines
- `docs/README.md` - Documentation index
- `scripts/README.md` - Scripts index
- Organized folder structure

## Customization

Edit `.claude/settings.json` to:
- Add more ignore patterns
- Remove patterns for specific projects
- Adjust based on your workflow

Edit `claude.md` to:
- Define project-specific focus areas
- Add custom exceptions
- Update as project evolves
