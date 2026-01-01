# GitHub Integration Guide

**Version 3.0** - Enhanced with unified sync workflow

AIWB provides comprehensive GitHub integration similar to Claude Code, allowing you to manage repositories, issues, pull requests, and workflows directly from the command line.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Authentication](#authentication)
3. [Repository Operations](#repository-operations)
4. [Branch Management](#branch-management)
5. [Issue Management](#issue-management)
6. [Pull Request Management](#pull-request-management)
7. [Workflow/CI Operations](#workflowci-operations)
8. [Interactive Mode](#interactive-mode)
9. [Workflow Examples](#workflow-examples)
10. [Architecture](#architecture)
11. [Troubleshooting](#troubleshooting)

---

## Quick Start

```bash
# 1. Set up GitHub authentication
aiwb github auth

# 2. Check status and sync with remote
aiwb github sync          # New in v3.0: unified sync workflow

# 3. Make changes, commit, and sync
aiwb github commit "Add new feature"
aiwb github sync          # Automatically pushes if ahead

# 4. Create a pull request
aiwb github pr create "New feature" "Description of changes" main
```

---

## Authentication

### Setting Up GitHub Token

AIWB requires a GitHub Personal Access Token (PAT) to interact with the GitHub API.

#### Create a Token

1. Go to https://github.com/settings/tokens/new
2. Select the following scopes:
   - `repo` - Full control of private repositories
   - `workflow` - Update GitHub Action workflows
   - `read:org` - Read organization membership (optional)
3. Generate and copy the token

#### Configure the Token

**Method 1: Interactive Setup (Recommended)**
```bash
aiwb github auth
```

**Method 2: Through Keys Menu**
```bash
aiwb keys
# Select "GitHub" from the menu
```

**Method 3: Environment Variable**
```bash
export GITHUB_TOKEN="your_token_here"
```

**Method 4: Direct Configuration**
```bash
# Stored securely in ~/.aiwb/.aiwb.env
echo 'export GITHUB_TOKEN="your_token"' >> ~/.aiwb/.aiwb.env
chmod 600 ~/.aiwb/.aiwb.env
```

### Verify Authentication

```bash
aiwb github whoami
```

Output:
```
╔═══════════════════════════════════════════════════════════╗
║ GitHub User                                                ║
╚═══════════════════════════════════════════════════════════╝
Username: @yourusername
Name: Your Name
Email: your@email.com
Bio: Developer
Public repos: 42
Followers: 100
Following: 50
Created: 2020-01-15T10:30:00Z
```

---

## Repository Operations

### Git Status

Show comprehensive git status with formatting:

```bash
aiwb github status
```

Output:
```
╔═══════════════════════════════════════════════════════════╗
║ Git Status                                                 ║
╚═══════════════════════════════════════════════════════════╝
Branch: feature-branch
Tracking: origin/feature-branch
Ahead: 2, Behind: 0

Changes:
  modified:   src/app.js
  modified:   README.md (not staged)
  added:      src/new-file.js
  untracked:  temp.log

Recent commits:
  abc1234 Fix authentication bug
  def5678 Add new feature
  ghi9012 Update dependencies
```

### Clone Repository

```bash
# Clone with owner/repo format
aiwb github clone octocat/Hello-World

# Clone to specific directory
aiwb github clone octocat/Hello-World ./my-project
```

### Stage Files

```bash
# Stage all changes
aiwb github add

# Stage specific files
aiwb github add src/app.js README.md
```

### Commit Changes

```bash
# Simple commit
aiwb github commit "Add new feature"

# Commit with staging
aiwb github add && aiwb github commit "Fix bug"
```

### Push Changes

```bash
# Push to current branch
aiwb github push

# Push to specific remote/branch
aiwb github push origin feature-branch

# Force push (use with caution!)
aiwb github push origin feature-branch --force
```

### Pull Changes

```bash
# Pull from tracking branch
aiwb github pull

# Pull from specific remote/branch
aiwb github pull origin main
```

### Fetch Updates

```bash
# Fetch from origin
aiwb github fetch

# Fetch from specific remote
aiwb github fetch upstream
```

### Sync with Remote (New in v3.0)

The unified sync command handles the entire sync workflow in one command - it fetches, shows status, and intelligently prompts to pull/push based on the current state:

```bash
# Sync with origin (default)
aiwb github sync

# Sync with specific remote
aiwb github sync upstream
```

**How it works:**

1. **Fetches from remote** (silently in the background)
2. **Calculates ahead/behind status** against the remote branch
3. **Takes action based on status:**
   - **In sync**: Shows success message
   - **Behind remote**: Lists commits to pull, prompts to pull
   - **Ahead of remote**: Lists commits to push, prompts to push
   - **Diverged** (both ahead and behind): Shows both commit lists, prompts to pull then push

**Example Output (when behind):**
```
==> Syncing with remote...
Branch: main
Behind: 3 commits

Commits to pull:
  a1b2c3d Fix deployment issue
  d4e5f6g Update dependencies
  h7i8j9k Add dark mode

Pull these 3 commit(s) from remote? (Y/n):
```

**Example Output (when ahead):**
```
==> Syncing with remote...
Branch: main
Ahead: 2 commits

Commits to push:
  k9j8i7h Add new feature
  f6e5d4c Update README

Push these 2 commit(s) to remote? (Y/n):
```

**Example Output (when diverged):**
```
==> Syncing with remote...
Branch: main
Ahead: 2, Behind: 1

⚠  Branches have diverged!

Commits to pull:
  x1y2z3a Hotfix from teammate

Commits to push:
  k9j8i7h Add new feature
  f6e5d4c Update README

Pull first, then push? (Y/n):
```

This replaces the traditional workflow:
```bash
# Old way (multiple commands)
aiwb github status
aiwb github pull    # If behind
aiwb github push    # If ahead

# New way (single command)
aiwb github sync
```

### Repository Info

```bash
# Current repository info
aiwb github repo

# Specific repository info
aiwb github repo octocat/Hello-World
```

### Fork Repository

```bash
# Fork to your account
aiwb github fork octocat/Hello-World

# Fork to an organization
aiwb github fork octocat/Hello-World my-org
```

---

## Branch Management

### List Branches

```bash
# List local branches
aiwb github branch list

# List local and remote branches
aiwb github branch list --remote
```

### Create Branch

```bash
# Create from current branch
aiwb github branch create feature-new

# Create from specific base
aiwb github branch create feature-new main
```

### Switch Branch

```bash
aiwb github branch switch feature-new
```

### Delete Branch

```bash
# Safe delete (fails if not merged)
aiwb github branch delete feature-old

# Force delete
aiwb github branch delete feature-old --force
```

---

## Issue Management

### List Issues

```bash
# List open issues
aiwb github issue list

# List closed issues
aiwb github issue list closed

# List all issues
aiwb github issue list all
```

Output:
```
╔═══════════════════════════════════════════════════════════╗
║ Issues for owner/repo                                      ║
╚═══════════════════════════════════════════════════════════╝
#42 [open] Bug: Login fails on mobile (@user1)
#41 [open] Feature: Add dark mode (@user2)
#40 [open] Docs: Update README (@user3)
```

### View Issue Details

```bash
aiwb github issue view 42
```

Output:
```
╔═══════════════════════════════════════════════════════════╗
║ Issue #42                                                  ║
╚═══════════════════════════════════════════════════════════╝
Title: Bug: Login fails on mobile
State: open
Author: @user1
Created: 2024-01-15T10:30:00Z
Labels: bug, high-priority

Description:
When trying to log in on mobile devices, the app crashes
after entering credentials.

Steps to reproduce:
1. Open app on mobile
2. Enter credentials
3. Click login
4. App crashes

Comments: 5
```

### Create Issue

```bash
# Basic issue
aiwb github issue create "Bug: Login fails" "Description of the bug"

# With labels
aiwb github issue create "Feature request" "Add dark mode" "enhancement,ui"
```

### Close/Reopen Issue

```bash
# Close issue
aiwb github issue close 42

# Reopen issue
aiwb github issue reopen 42
```

### Add Comment

```bash
aiwb github issue comment 42 "This is fixed in PR #45"
```

---

## Pull Request Management

### List Pull Requests

```bash
# List open PRs
aiwb github pr list

# List closed PRs
aiwb github pr list closed

# List all PRs
aiwb github pr list all
```

Output:
```
╔═══════════════════════════════════════════════════════════╗
║ Pull Requests for owner/repo                               ║
╚═══════════════════════════════════════════════════════════╝
#45 [open] Add authentication feature (@dev1) [feature-auth -> main]
#44 [open] Fix typos in docs (@dev2) [fix-typos -> main]
#43 [merged] Update dependencies (@dev3) [deps-update -> main]
```

### View PR Details

```bash
aiwb github pr view 45
```

Output:
```
╔═══════════════════════════════════════════════════════════╗
║ Pull Request #45                                           ║
╚═══════════════════════════════════════════════════════════╝
Title: Add authentication feature
State: open
Author: @dev1
Branch: feature-auth -> main
Created: 2024-01-15T10:30:00Z
Mergeable: true
Changed files: 12
Additions: +450, Deletions: -23

Description:
This PR adds JWT-based authentication to the API.

Changes:
- Add auth middleware
- Create login/logout endpoints
- Add user session management
```

### Create Pull Request

```bash
# Create PR from current branch to main
aiwb github pr create "Add new feature" "Description of changes" main

# The current branch is automatically used as the head
```

### View Changed Files

```bash
aiwb github pr files 45
```

Output:
```
modified    src/auth/middleware.js    +120/-5
modified    src/routes/api.js         +45/-10
added       src/auth/jwt.js           +85/-0
modified    package.json              +3/-1
```

### Merge Pull Request

```bash
# Regular merge
aiwb github pr merge 45

# Squash merge
aiwb github pr merge 45 squash

# Rebase merge
aiwb github pr merge 45 rebase
```

### Close PR (Without Merging)

```bash
aiwb github pr close 45
```

---

## Workflow/CI Operations

### List Workflow Runs

```bash
aiwb github workflow list
```

Output:
```
╔═══════════════════════════════════════════════════════════╗
║ Workflow Runs for owner/repo                               ║
╚═══════════════════════════════════════════════════════════╝
[success] CI Tests #123 (main) - 2024-01-15T10:30:00Z
[failure] CI Tests #122 (feature-branch) - 2024-01-15T09:15:00Z
[in_progress] Deploy #121 (main) - 2024-01-15T10:45:00Z
```

### View Workflow Run

```bash
aiwb github workflow view 123
```

Output:
```
Workflow: CI Tests
Run: #123
Status: completed
Conclusion: success
Branch: main
Commit: abc1234
Started: 2024-01-15T10:30:00Z
URL: https://github.com/owner/repo/actions/runs/123
```

### Re-run Workflow

```bash
aiwb github workflow rerun 122
```

---

## Interactive Mode

AIWB provides a full interactive menu for GitHub operations:

```bash
aiwb github
# Or
aiwb gh
```

### Main Menu

```
GitHub Operations
─────────────────
❯ Status - Show git status
  Clone - Clone a repository
  Commit - Commit changes
  Push - Push to remote
  Pull - Pull from remote
  Sync - Sync with remote (fetch, pull/push as needed)
  Branches - Manage branches
  Issues - Manage issues
  PRs - Manage pull requests
  Workflows - View CI/CD runs
  Auth - Configure token
  Back
```

### In Chat Mode

```bash
aiwb
> /github              # Open interactive menu
> /github status       # Quick status
> /github sync         # Unified sync workflow
> /github commit       # Commit with prompts
> /github push         # Push changes
> /github pull         # Pull changes
> /github pr create    # Create PR interactively
```

---

## Workflow Examples

### Complete Feature Development Workflow

```bash
# 1. Start from main branch (using new sync command)
aiwb github branch switch main
aiwb github sync          # Replaces: pull + status

# 2. Create feature branch
aiwb github branch create feature-awesome

# 3. Make your changes...
# (edit files)

# 4. Check status
aiwb github status

# 5. Stage and commit
aiwb github add
aiwb github commit "Add awesome feature"

# 6. Push branch (using new sync command)
aiwb github sync          # Intelligent push with status check

# 7. Create pull request
aiwb github pr create "Add awesome feature" "This PR adds..." main

# 8. After review, merge
aiwb github pr merge 123 squash

# 9. Clean up
aiwb github branch switch main
aiwb github sync          # Sync instead of pull
aiwb github branch delete feature-awesome
```

### Bug Fix Workflow

```bash
# 1. Create issue
aiwb github issue create "Bug: App crashes on startup" "Steps to reproduce..."

# 2. Create fix branch
aiwb github branch create fix-startup-crash

# 3. Make fix and commit
aiwb github add
aiwb github commit "Fix startup crash (closes #42)"

# 4. Push and create PR
aiwb github push
aiwb github pr create "Fix startup crash" "Fixes #42" main
```

### Fork and Contribute Workflow

```bash
# 1. Fork repository
aiwb github fork original-owner/project

# 2. Clone your fork
aiwb github clone your-username/project

# 3. Create feature branch
cd project
aiwb github branch create my-contribution

# 4. Make changes and push
aiwb github add
aiwb github commit "Add my contribution"
aiwb github push

# 5. Create PR to original repo (do this on GitHub.com)
```

---

## Architecture

### File Structure

```
lib/github.sh (~1,200 lines)
├── Configuration
│   ├── get_github_token()
│   ├── has_github_token()
│   └── set_github_token()
│
├── API Helpers
│   └── github_api(method, endpoint, data)
│
├── Repository Operations
│   ├── github_get_current_repo()
│   ├── github_clone()
│   ├── github_repo_info()
│   ├── github_list_repos()
│   └── github_fork()
│
├── Git Operations
│   ├── github_status()
│   ├── github_add()
│   ├── github_commit()
│   ├── github_push()
│   ├── github_pull()
│   ├── github_fetch()
│   └── github_sync()          # New in v3.0
│
├── Branch Operations
│   ├── github_branches()
│   ├── github_branch_create()
│   ├── github_branch_switch()
│   └── github_branch_delete()
│
├── Issue Operations
│   ├── github_issues_list()
│   ├── github_issue_view()
│   ├── github_issue_create()
│   ├── github_issue_close()
│   ├── github_issue_reopen()
│   └── github_issue_comment()
│
├── PR Operations
│   ├── github_pr_list()
│   ├── github_pr_view()
│   ├── github_pr_create()
│   ├── github_pr_merge()
│   ├── github_pr_close()
│   └── github_pr_files()
│
├── Workflow Operations
│   ├── github_workflows_list()
│   ├── github_workflow_view()
│   └── github_workflow_rerun()
│
├── User Operations
│   └── github_whoami()
│
└── Interactive Menus
    ├── github_menu()
    ├── github_branches_menu()
    ├── github_issues_menu()
    ├── github_pr_menu()
    ├── github_workflows_menu()
    └── github_auth_menu()
```

### API Flow

```
User Command
     │
     ▼
cmd_github() [aiwb]
     │
     ▼
github_*() function [lib/github.sh]
     │
     ├─► Git Command (local)
     │   └─► git status/commit/push/etc.
     │
     └─► GitHub API (remote)
         │
         ▼
    github_api()
         │
         ▼
    curl -H "Authorization: Bearer $token"
         │
         ▼
    JSON Response
         │
         ▼
    Parse with jq
         │
         ▼
    Display to User
```

### Integration Points

1. **Main Script (aiwb)**:
   - `cmd_github()` - Command handler
   - `cmd_github_help()` - Help text
   - Slash command `/github` in chat mode

2. **Security (lib/security.sh)**:
   - GitHub token in `set_api_key()`
   - Token validation patterns
   - Audit for exposed tokens

3. **Doctor Command**:
   - Checks GitHub token status
   - Reports in health check

---

## Troubleshooting

### "GitHub token not set"

```bash
# Set up authentication
aiwb github auth

# Or check if token exists
aiwb doctor
```

### "Not in a git repository"

```bash
# Initialize git if needed
git init

# Or navigate to a git repository
cd /path/to/your/repo
```

### "Could not parse GitHub repository from remote"

```bash
# Check your remote URL
git remote -v

# Should be in format:
# origin  https://github.com/owner/repo.git
# or
# origin  git@github.com:owner/repo.git
```

### "API rate limit exceeded"

- Wait for rate limit reset (usually 1 hour)
- Authenticated requests have higher limits (5000/hour vs 60/hour)
- Ensure your token is properly configured

### "Permission denied"

- Check that your token has the required scopes (`repo`, `workflow`)
- Regenerate token with correct permissions
- Ensure you have push access to the repository

### Debug Mode

Enable debug output for troubleshooting:

```bash
AIWB_DEBUG=1 aiwb github status
```

---

## Security Considerations

1. **Token Storage**: Tokens are stored in `~/.aiwb/.aiwb.env` with `600` permissions (owner read/write only)

2. **Token Encryption**: Optionally encrypt with age:
   ```bash
   aiwb keys
   # Select "Encrypt keys"
   ```

3. **Audit for Exposure**: The security audit checks for tokens in git history:
   ```bash
   aiwb security-audit
   ```

4. **Environment Variables**: Tokens can be passed via environment:
   ```bash
   GITHUB_TOKEN=xxx aiwb github status
   ```

---

## Comparison with Claude Code

| Feature | AIWB | Claude Code |
|---------|------|-------------|
| Git status | `aiwb github status` | Built-in |
| Clone repos | `aiwb github clone` | Built-in |
| Commit changes | `aiwb github commit` | Built-in |
| Push/Pull | `aiwb github push/pull` | Built-in |
| **Unified sync** | `aiwb github sync` ✨ | N/A |
| Create issues | `aiwb github issue create` | Built-in |
| Create PRs | `aiwb github pr create` | Built-in |
| View workflows | `aiwb github workflow list` | Built-in |
| Interactive menu | `aiwb github` | Context-aware |
| Token storage | Encrypted option | System keychain |

AIWB provides a CLI-focused approach that works seamlessly in terminal environments, including Termux on Android.

---

*For more information, see the [main documentation](README.md) or run `aiwb github help`.*
