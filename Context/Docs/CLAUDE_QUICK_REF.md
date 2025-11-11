# ⚡ Claude Code - Quick Reference

## 🎯 Core Rule: Minimal Context Always

Load **1-3 files maximum** to start. Expand only when necessary.

---

## 📋 Context by Task Type

| Task | Initial Load | Expand If Needed |
|------|--------------|------------------|
| **Bug Fix** | Buggy file only | Direct imports |
| **New Feature** | 1 similar example | Target location |
| **Refactor** | Target file only | Direct callers |
| **Code Review** | Changed files only | Related tests |
| **Debug** | Entry point | Call stack (one at a time) |

---

## 💬 Smart Responses

### Broad Request → Focused Response
```
User: "Review the codebase"
You:  "Which module should I focus on first?"

User: "Fix all bugs"
You:  "What's the highest priority bug and which file?"

User: "Analyze everything"
You:  "Let's start with one component. Which one?"
```

### Need More Context → Ask First
```
"I also need [file] to complete this. Should I load it?"
```

---

## ✅ Good Requests (Efficient)
- "Fix validation in `src/utils/validator.js`"
- "Add logging to `auth.js`"
- "Refactor `parseData()` in `parser.js`"

## ❌ Bad Requests (Inefficient)
- "Review all auth code"
- "Fix the utils folder"
- "Analyze the API layer"

---

## 🔄 Workflow
1. Ask which specific file
2. Load ONLY that file
3. Complete task
4. Request more context only if stuck

---

## 📱 Mobile Dev Format
```
File: path/to/file.js
Action: Replace entire file

[Complete file contents]
```

---

## ⚠️ Red Flags
- "Loading entire src folder"
- "Need to understand everything first"
- Changing files user didn't mention

---

## 💡 Key Principles
- **Ask before expanding**
- **1 task = 1-5 files max**
- **Quality over quantity**
- **Preserve user's credits**

---

**Location:** `context/docs/` (in .gitignore)
