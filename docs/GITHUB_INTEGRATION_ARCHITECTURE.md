# GitHub Integration Architecture

**Visual guide to AIWB's GitHub integration architecture**

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                           AIWB Core                                 │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │   Commands   │  │    Modes     │  │      UI      │            │
│  │              │  │              │  │              │            │
│  │ /commit      │  │ /make        │  │ TUI (gum)    │            │
│  │ /branch      │  │ /tweak       │  │ Prompts      │            │
│  │ /conflict    │  │ /debug       │  │ Menus        │            │
│  │ /changelog   │  │ /wizard      │  │ Dialogs      │            │
│  │ /gh-issue    │  │              │  │              │            │
│  │ /gh-pr       │  └──────┬───────┘  └──────┬───────┘            │
│  │ /gh-release  │         │                  │                    │
│  └──────┬───────┘         │                  │                    │
│         │                 │                  │                    │
│         └─────────────────┴──────────────────┘                    │
│                           │                                        │
└───────────────────────────┼────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      lib/github.sh (NEW)                            │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                    Git Operations Layer                     │   │
│  │                                                              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │   │
│  │  │   Commit     │  │   Branch     │  │   Conflict   │     │   │
│  │  │   Message    │  │   Analysis   │  │  Resolution  │     │   │
│  │  │  Generator   │  │              │  │              │     │   │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │   │
│  │         │                  │                  │             │   │
│  │         └──────────────────┴──────────────────┘             │   │
│  │                           │                                 │   │
│  │                           ▼                                 │   │
│  │                  ┌─────────────────┐                        │   │
│  │                  │  Git Commands   │                        │   │
│  │                  │  - git diff     │                        │   │
│  │                  │  - git log      │                        │   │
│  │                  │  - git branch   │                        │   │
│  │                  │  - git status   │                        │   │
│  │                  └─────────────────┘                        │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                   GitHub API Layer                          │   │
│  │                                                              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │   │
│  │  │   Issues     │  │     PRs      │  │   Releases   │     │   │
│  │  │              │  │              │  │              │     │   │
│  │  │ - list       │  │ - list       │  │ - list       │     │   │
│  │  │ - create     │  │ - create     │  │ - create     │     │   │
│  │  │ - comment    │  │ - review     │  │ - draft      │     │   │
│  │  │ - close      │  │ - merge      │  │              │     │   │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │   │
│  │         │                  │                  │             │   │
│  │         └──────────────────┴──────────────────┘             │   │
│  │                           │                                 │   │
│  │                           ▼                                 │   │
│  │                  ┌─────────────────┐                        │   │
│  │                  │  GitHub REST    │                        │   │
│  │                  │      API        │                        │   │
│  │                  │  (curl + jq)    │                        │   │
│  │                  └─────────────────┘                        │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                 Automation & Hooks Layer                    │   │
│  │                                                              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │   │
│  │  │ Pre-commit   │  │   GitHub     │  │  Changelog   │     │   │
│  │  │    Hook      │  │   Actions    │  │  Generator   │     │   │
│  │  │              │  │              │  │              │     │   │
│  │  │ - AI review  │  │ - PR review  │  │ - From git   │     │   │
│  │  │ - Auto-fix   │  │ - Commit     │  │   log        │     │   │
│  │  │ - Bypass     │  │   check      │  │ - Grouping   │     │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │   │
│  └──────────────────────────────────────────────────────────────┘   │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Existing AIWB Libraries                          │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │   lib/api.sh │  │lib/config.sh │  │lib/security  │            │
│  │              │  │              │  │      .sh     │            │
│  │ - AI API     │  │ - Settings   │  │ - Token      │            │
│  │   calls      │  │ - Workspace  │  │   encryption │            │
│  │ - Generator  │  │ - Providers  │  │ - Age crypto │            │
│  │ - Verifier   │  │              │  │              │            │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘            │
│         │                  │                  │                    │
└─────────┴──────────────────┴──────────────────┴────────────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      External Services                              │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │  Gemini API  │  │  Claude API  │  │  GitHub API  │            │
│  │              │  │              │  │              │            │
│  │ Generator    │  │ Verifier     │  │ REST API     │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagrams

### 1. AI-Powered Commit Message Generation

```
┌─────────┐
│  User   │
│ runs    │
│/commit  │
└────┬────┘
     │
     ▼
┌─────────────────────────────────┐
│ lib/github.sh                   │
│ commit_message_generate()       │
└────┬────────────────────────────┘
     │
     ├─────► git diff --staged ────► Parse changes
     │                                      │
     │                                      ▼
     │                            ┌─────────────────┐
     │                            │ Build AI prompt │
     │                            │ with context    │
     │                            └────────┬────────┘
     │                                     │
     │                                     ▼
     ├─────────────────────────► lib/api.sh
     │                            Generator AI call
     │                            (Gemini Flash)
     │                                     │
     │                                     ▼
     │                            ┌─────────────────┐
     │                            │ Draft commit    │
     │                            │ message         │
     │                            └────────┬────────┘
     │                                     │
     │                                     ▼
     ├─────────────────────────► lib/api.sh
     │                            Verifier AI call
     │                            (Claude Sonnet)
     │                                     │
     │                                     ▼
     │                            ┌─────────────────┐
     │                            │ Validated       │
     │                            │ message         │
     │                            └────────┬────────┘
     │                                     │
     ▼                                     ▼
┌─────────────────────────────────────────────────┐
│           lib/ui.sh                             │
│   Display message with options:                 │
│   [A]ccept [E]dit [R]egenerate [C]ancel        │
└────────────────┬────────────────────────────────┘
                 │
                 ▼ (if Accept)
           git commit -m "..."
                 │
                 ▼
           ┌─────────┐
           │ Success │
           └─────────┘
```

### 2. PR Creation with AI Description

```
┌─────────┐
│  User   │
│ runs    │
│/gh-pr   │
│ create  │
└────┬────┘
     │
     ▼
┌─────────────────────────────────┐
│ lib/github.sh                   │
│ gh_pr_create()                  │
└────┬────────────────────────────┘
     │
     ├─────► git log main..HEAD ───► Get commits
     │                                      │
     ├─────► git diff main...HEAD ─► Get changes
     │                                      │
     │                                      ▼
     │                            ┌─────────────────┐
     │                            │ Analyze commits │
     │                            │ & changes       │
     │                            └────────┬────────┘
     │                                     │
     │                                     ▼
     ├─────────────────────────► lib/api.sh
     │                            Generator AI
     │                            Generate PR desc
     │                                     │
     │                                     ▼
     │                            ┌─────────────────┐
     │                            │ PR Description: │
     │                            │ - Summary       │
     │                            │ - Changes       │
     │                            │ - Test plan     │
     │                            └────────┬────────┘
     │                                     │
     ├─────► git log --format     │       │
     │       git blame            │       │
     │                            │       │
     │                            ▼       ▼
     │                     ┌──────────────────┐
     │                     │ Suggest reviewers│
     │                     │ based on changes │
     │                     └────────┬─────────┘
     │                              │
     ▼                              ▼
┌──────────────────────────────────────────┐
│           lib/ui.sh                      │
│   Show PR preview                        │
│   [C]reate [E]dit [P]review [B]ack      │
└────────────────┬─────────────────────────┘
                 │
                 ▼ (if Create)
         ┌───────────────────┐
         │ lib/github.sh     │
         │ gh_api_call()     │
         └────────┬──────────┘
                  │
                  ▼
         POST /repos/{owner}/{repo}/pulls
                  │
                  ▼
            ┌─────────┐
            │ PR #123 │
            │ created │
            └─────────┘
```

### 3. Pre-commit Hook Workflow

```
┌──────────────┐
│ User runs:   │
│ git commit   │
└──────┬───────┘
       │
       ▼
┌──────────────────────┐
│ .git/hooks/          │
│ pre-commit           │
│ (AIWB installed)     │
└──────┬───────────────┘
       │
       ▼
┌─────────────────────────────────┐
│ lib/github.sh                   │
│ run_pre_commit_review()         │
└────┬────────────────────────────┘
     │
     ├─────► git diff --staged ────► Get changes
     │                                      │
     │                                      ▼
     │                            ┌─────────────────┐
     │                            │ Size check:     │
     │                            │ Small? Fast     │
     │                            │ Large? Thorough │
     │                            └────────┬────────┘
     │                                     │
     │                                     ▼
     ├────────────────────────► lib/api.sh
     │                           AI Code Review
     │                           (Model based on size)
     │                                     │
     │                                     ▼
     │                            ┌─────────────────┐
     │                            │ Review results: │
     │                            │ - Issues        │
     │                            │ - Suggestions   │
     │                            │ - Auto-fixes    │
     │                            └────────┬────────┘
     │                                     │
     ▼                                     ▼
┌──────────────────────────────────────────────┐
│  Display findings                            │
│                                              │
│  ⚠ Issues Found (2):                        │
│  1. Security issue at line 67                │
│  2. Missing error handling at line 112       │
│                                              │
│  [F]ix [I]gnore [A]bort [V]iew              │
└────────────────┬─────────────────────────────┘
                 │
                 ├──► Fix ────► Apply changes ──► Continue commit
                 │
                 ├──► Ignore ─────────────────► Continue commit
                 │
                 └──► Abort ──────────────────► Exit code 1
                                                 (commit cancelled)
```

---

## Component Integration Points

### lib/github.sh Integration with Existing Modules

```
lib/github.sh
│
├─► lib/api.sh
│   │
│   ├─ call_api()           # Reuse for GitHub API
│   ├─ generator_loop()     # For commit messages, PR descriptions
│   └─ verifier_loop()      # For validating AI outputs
│
├─► lib/config.sh
│   │
│   ├─ config_get()         # Get github_* settings
│   ├─ config_set()         # Save github_* settings
│   └─ workspace_path()     # Determine working directory
│
├─► lib/security.sh
│   │
│   ├─ encrypt_with_age()   # Encrypt GitHub token
│   ├─ decrypt_with_age()   # Decrypt GitHub token
│   └─ check_git_exposure() # Already exists, enhance
│
├─► lib/ui.sh
│   │
│   ├─ ui_confirm()         # Confirm actions
│   ├─ ui_select()          # Select from options
│   ├─ ui_input()           # Get user input
│   ├─ ui_info_box()        # Display info
│   └─ ui_error()           # Display errors
│
└─► lib/modes.sh
    │
    ├─ mode_make()          # Enhance with git options
    ├─ mode_tweak()         # Add auto-commit
    └─ mode_debug()         # Add git blame context
```

---

## File Structure

```
AIworkbench/
│
├── aiwb                              # Main entry point
│
├── lib/
│   ├── api.sh                        # AI API calls (existing)
│   ├── config.sh                     # Configuration (existing)
│   ├── security.sh                   # Security & encryption (existing)
│   ├── ui.sh                         # TUI components (existing)
│   ├── modes.sh                      # Mode system (existing)
│   ├── common.sh                     # Utilities (existing)
│   ├── error.sh                      # Error handling (existing)
│   └── github.sh                     # NEW: GitHub integration
│
├── .git/hooks/
│   └── pre-commit                    # NEW: AIWB pre-commit hook
│
├── .github/
│   ├── workflows/
│   │   ├── aiwb-pr-review.yml       # NEW: PR review action
│   │   ├── aiwb-commit-check.yml    # NEW: Commit validation
│   │   └── aiwb-changelog.yml       # NEW: Changelog generation
│   ├── dependabot.yml               # Existing
│   └── FUNDING.yml                  # Existing
│
├── docs/
│   ├── GITHUB_INTEGRATION_PLAN.md        # NEW: Full plan
│   ├── GITHUB_INTEGRATION_SUMMARY.md     # NEW: Quick summary
│   ├── GITHUB_INTEGRATION_ARCHITECTURE.md # NEW: This file
│   ├── GITHUB_COMMANDS_REFERENCE.md      # NEW: Command docs
│   ├── ROADMAP.md                        # Updated
│   └── ...                               # Existing docs
│
└── tests/
    └── test_github_integration.sh    # NEW: GitHub tests
```

---

## Security Architecture

```
┌──────────────────────────────────────────────────┐
│              User's GitHub Token                 │
│          (Personal Access Token / PAT)           │
└────────────────────┬─────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │  First Time Setup:    │
         │  aiwb                 │
         │  > /keys              │
         │  > Add GitHub token   │
         └───────┬───────────────┘
                 │
                 ▼
    ┌────────────────────────────┐
    │   lib/security.sh          │
    │   encrypt_with_age()       │
    │                            │
    │   - Generate encryption    │
    │     key from passphrase    │
    │   - Encrypt token with age │
    └──────┬─────────────────────┘
           │
           ▼
    ┌──────────────────────────────────┐
    │  ~/.config/aiwb/github_token.age │
    │  (Encrypted token storage)       │
    │  Permissions: 600 (user only)    │
    └──────┬───────────────────────────┘
           │
           │ When needed
           ▼
    ┌────────────────────────────┐
    │   lib/security.sh          │
    │   decrypt_with_age()       │
    │                            │
    │   - Decrypt token          │
    │   - Load into memory       │
    │   - Use for API call       │
    │   - Clear from memory      │
    └──────┬─────────────────────┘
           │
           ▼
    ┌──────────────────────────────┐
    │  lib/github.sh               │
    │  gh_api_call()               │
    │                              │
    │  - Add token to header       │
    │  - Make API request          │
    │  - Token never logged        │
    └──────┬───────────────────────┘
           │
           ▼
    ┌──────────────────────────────┐
    │  GitHub API                  │
    │  (https://api.github.com)    │
    └──────────────────────────────┘
```

### Security Principles

1. **Encryption at Rest:** Tokens encrypted with age (same as API keys)
2. **Memory Safety:** Tokens only decrypted when needed, cleared after use
3. **No Logging:** Tokens never appear in logs or debug output
4. **Minimal Permissions:** Request only required scopes
5. **File Permissions:** Config files readable only by user (600)
6. **Validation:** Token validated before use, clear error on expiry

---

## API Request Flow

### GitHub API Request Pattern

```
┌─────────────────┐
│  Command        │
│  /gh-issue list │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│ lib/github.sh                   │
│ gh_issue_list()                 │
└────────┬────────────────────────┘
         │
         ├─► config_get("github_username")
         ├─► config_get("github_default_repo")
         │
         ▼
┌─────────────────────────────────┐
│ gh_api_call()                   │
│                                 │
│ Parameters:                     │
│ - method: GET                   │
│ - endpoint: /repos/...          │
│ - auth: required                │
└────────┬────────────────────────┘
         │
         ├─► decrypt_with_age(github_token)
         │
         ▼
┌─────────────────────────────────┐
│ Build curl request:             │
│                                 │
│ curl -H "Authorization:         │
│       Bearer $token"            │
│      -H "Accept:                │
│       application/vnd.github+   │
│       json"                     │
│      https://api.github.com/    │
│      repos/{owner}/{repo}/      │
│      issues                     │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ Execute request with:           │
│ - Retry on network error (3x)   │
│ - Rate limit detection          │
│ - Error handling                │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ Parse JSON response with jq:    │
│                                 │
│ - Extract data                  │
│ - Handle pagination             │
│ - Check for errors              │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ Return formatted data:          │
│                                 │
│ #123 - Bug in API (open)        │
│ #122 - Add feature X (open)     │
│ #121 - Update docs (closed)     │
└─────────────────────────────────┘
```

---

## Configuration Data Model

```
~/.config/aiwb/
│
├── config.json
│   │
│   ├─ model_provider: "gemini"
│   ├─ model_name: "gemini-2.0-flash"
│   │
│   ├─ github_username: "juanitto-maker"       # NEW
│   ├─ github_default_repo: "AIworkbench"     # NEW
│   │
│   ├─ commit_style: "conventional"            # NEW
│   ├─ commit_auto_verify: true                # NEW
│   ├─ commit_require_approval: true           # NEW
│   │
│   ├─ branch_naming_convention: "feature/*"   # NEW
│   ├─ branch_auto_suggest: true               # NEW
│   │
│   ├─ review_pre_commit_enabled: false        # NEW
│   ├─ review_strictness: "medium"             # NEW
│   ├─ review_auto_fix: false                  # NEW
│   │
│   ├─ pr_auto_fill_description: true          # NEW
│   ├─ pr_suggest_reviewers: true              # NEW
│   ├─ pr_include_test_plan: true              # NEW
│   │
│   ├─ changelog_format: "keepachangelog"      # NEW
│   ├─ changelog_group_by: "type"              # NEW
│   └─ changelog_include_all: false            # NEW
│
├── keys.age                  # Existing: encrypted API keys
│
└── github_token.age          # NEW: encrypted GitHub token
```

---

## Testing Architecture

```
tests/test_github_integration.sh
│
├── Unit Tests
│   │
│   ├─ test_gh_api_call()
│   │   ├─ Mock curl responses
│   │   ├─ Test error handling
│   │   ├─ Test rate limiting
│   │   └─ Test authentication
│   │
│   ├─ test_commit_message_generate()
│   │   ├─ Mock git diff output
│   │   ├─ Mock AI API responses
│   │   ├─ Test message formatting
│   │   └─ Test conventional commit style
│   │
│   ├─ test_branch_analyze()
│   │   ├─ Mock git branch output
│   │   ├─ Test divergence detection
│   │   └─ Test conflict detection
│   │
│   └─ test_pr_description_generate()
│       ├─ Mock git log output
│       ├─ Mock AI API responses
│       └─ Test description formatting
│
├── Integration Tests
│   │
│   ├─ test_full_commit_workflow()
│   │   ├─ Create test repo
│   │   ├─ Make changes
│   │   ├─ Run /commit
│   │   └─ Verify commit
│   │
│   ├─ test_pr_creation_workflow()
│   │   ├─ Create test branch
│   │   ├─ Make commits
│   │   ├─ Run /gh-pr create (dry-run)
│   │   └─ Verify PR description
│   │
│   └─ test_pre_commit_hook()
│       ├─ Install hook
│       ├─ Stage problematic code
│       ├─ Attempt commit
│       └─ Verify review triggered
│
└── Mock Utilities
    │
    ├─ mock_git_command()
    ├─ mock_github_api()
    ├─ mock_ai_response()
    └─ create_test_repo()
```

---

## Performance Considerations

### Response Time Targets

```
Operation                          | Target | Bottleneck | Optimization
----------------------------------|--------|------------|---------------
/commit (message generation)      | <5s    | AI API     | Use fast model
/branch analyze                   | <10s   | Git log    | Limit history
/conflict resolve                 | <15s   | AI API     | Context size
/gh-issue list                    | <3s    | GitHub API | Caching
/gh-pr create                     | <15s   | AI API     | Parallel calls
Pre-commit hook (small changes)   | <10s   | AI API     | Fast model
Pre-commit hook (large changes)   | <30s   | AI API     | Configurable
```

### Optimization Strategies

1. **Caching:**
   - GitHub API responses (issues, PRs) cached for 5 minutes
   - Git log results cached per branch
   - AI prompts cached for identical diffs

2. **Parallelization:**
   - Generator and git operations in parallel where possible
   - Multiple GitHub API calls batched
   - Async AI requests (not waiting for full response)

3. **Model Selection:**
   - Fast models (Haiku, Flash) for simple tasks
   - Thorough models (Sonnet) only when needed
   - Local models (Ollama) for offline usage

4. **Context Optimization:**
   - Send only relevant diff context to AI
   - Limit git log depth (default: last 100 commits)
   - Truncate large files (> 1000 lines)

---

## Error Handling Architecture

```
Error Types & Handling
│
├── Network Errors
│   ├─ GitHub API unreachable
│   │   └─► Retry with exponential backoff (3 attempts)
│   │
│   └─ AI API unreachable
│       └─► Fallback to simpler commit message
│           or local model
│
├── Authentication Errors
│   ├─ Invalid GitHub token
│   │   └─► Prompt user to update token
│   │
│   ├─ Expired GitHub token
│   │   └─► Clear error message, link to GitHub settings
│   │
│   └─ Insufficient permissions
│       └─► List required scopes, guide to fix
│
├── Git Errors
│   ├─ Not a git repository
│   │   └─► Graceful message, disable git features
│   │
│   ├─ No staged changes
│   │   └─► Suggest: git add <files>
│   │
│   └─ Merge in progress
│       └─► Detect state, offer conflict resolution
│
├── Rate Limiting
│   ├─ GitHub API rate limit
│   │   └─► Show remaining quota
│   │       └─► Suggest waiting time
│   │
│   └─ AI API rate limit
│       └─► Switch to alternative model
│           or queue request
│
└── User Errors
    ├─ Invalid command arguments
    │   └─► Show usage help
    │
    ├─ Conflicting options
    │   └─► Clear error, suggest fix
    │
    └─ Missing configuration
        └─► Interactive setup wizard
```

---

**End of Architecture Documentation**

*For implementation details, see GITHUB_INTEGRATION_PLAN.md*
*For quick overview, see GITHUB_INTEGRATION_SUMMARY.md*
