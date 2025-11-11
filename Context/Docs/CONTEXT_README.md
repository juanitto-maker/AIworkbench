# Context Folder

This folder contains local development guidance and reference materials for working with this codebase. It is **not tracked in git** (added to .gitignore).

## 📁 Structure

```
context/
├── images/     # Screenshots, diagrams, UI mockups, reference images
├── code/       # Code snippets, examples, quick references
└── docs/       # Instructions, guidelines, AI assistant context files
```

## 🎯 Purpose

### images/
Store visual references for development:
- UI mockups and designs
- Architecture diagrams
- Screenshots of bugs or expected behavior
- Flowcharts and wireframes
- Reference images for features

### code/
Store code-related references:
- Useful code snippets
- Algorithm examples
- Configuration templates
- Quick copy-paste solutions
- Pattern examples

### docs/
Store development instructions:
- Claude Code instructions (for AI efficiency)
- Project-specific guidelines
- Development workflows
- Architecture decisions
- Quick reference guides

## 🤖 AI Assistant Usage

If you use Claude Code or similar AI assistants:

1. Place instruction files in `context/docs/`
2. Reference them at session start: "Read context/docs/CLAUDE_INSTRUCTIONS.md first"
3. Keep instructions focused and minimal
4. Update as project evolves

## 📝 Notes

- This folder is personal/team-specific
- Not shared via git (in .gitignore)
- Each developer can customize their context folder
- Helps preserve AI rate limits by providing focused context
- Speeds up onboarding and development

## 🚀 Quick Setup

1. Create the structure:
   ```bash
   mkdir -p context/images context/code context/docs
   ```

2. Add to .gitignore:
   ```bash
   echo "context/" >> .gitignore
   ```

3. Add instruction files to context/docs/
4. Start developing efficiently!

---

**This folder is your personal development assistant - organize it however works best for you!**
