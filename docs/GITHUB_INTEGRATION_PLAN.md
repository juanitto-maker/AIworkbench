# GitHub Integration Plan for AIWB

**Version:** 1.0
**Created:** 2025-11-17
**Status:** Planning Phase

---

## Executive Summary

This document outlines a comprehensive plan to integrate GitHub functionality into AIWB, transforming it from a standalone AI development tool into a GitHub-aware AI assistant that can intelligently interact with repositories, automate workflows, and enhance developer productivity.

The integration aligns with **Phase 3** (Enhanced Workflows & Intelligence) and **Phase 5** (Ecosystem & Integrations) of the AIWB roadmap.

---

## 1. Current State Analysis

### Existing Git Functionality
- **Minimal git interaction:** Only security checks for API keys in git history (lib/security.sh:329-370)
- **No GitHub API integration:** No interaction with GitHub issues, PRs, or releases
- **No git workflow automation:** No AI-assisted commit messages, branch management, or merge conflict resolution
- **No CI/CD integration:** Only basic dependabot.yml and FUNDING.yml in .github/

### Opportunities
- Leverage AIWB's existing AI orchestration (Generator-Verifier loop) for git workflows
- Integrate with existing mode system (/make, /tweak, /debug)
- Use existing API abstraction layer (lib/api.sh) for GitHub API calls
- Build on existing TUI framework (lib/ui.sh) for interactive git operations

---

## 2. Architecture Design

### 2.1 New Module: lib/github.sh

A dedicated module for all GitHub and Git integration functionality.

**Core Components:**
```bash
lib/github.sh
├── Git Operations
│   ├── Smart commit message generation
│   ├── Branch analysis and suggestions
│   ├── Merge conflict detection and AI-assisted resolution
│   ├── Diff analysis and summarization
│   └── Changelog generation from git history
│
├── GitHub API Integration
│   ├── Authentication (token-based, secure storage)
│   ├── Issues (list, create, comment, close)
│   ├── Pull Requests (list, create, review, merge)
│   ├── Releases (list, create, draft)
│   └── Repository info and stats
│
└── Workflow Automation
    ├── Pre-commit hooks with AI review
    ├── PR template generation
    ├── Automated code review comments
    └── Release notes generation
```

### 2.2 New Commands

**Git Workflow Commands:**
- `/commit` - AI-powered commit message generation
- `/branch` - Branch analysis and management
- `/conflict` - AI-assisted merge conflict resolution
- `/changelog` - Generate changelog from git history
- `/review` - Pre-commit AI code review

**GitHub API Commands:**
- `/gh-issue` - Manage GitHub issues
- `/gh-pr` - Manage pull requests
- `/gh-release` - Manage releases
- `/gh-review` - Automated PR code review

### 2.3 Integration with Existing Modes

Enhance existing modes with git awareness:

**Enhanced /make mode:**
- Auto-commit generated code with AI commit messages
- Create feature branch for new implementations
- Option to create PR after completion

**Enhanced /tweak mode:**
- Detect affected files from git diff
- Generate appropriate commit message
- Suggest branch name based on changes

**Enhanced /debug mode:**
- Analyze git blame for bug context
- Check if bug exists in other branches
- Generate bug fix commit with detailed message

### 2.4 GitHub Actions Workflows

Create reusable workflow templates:

```
.github/workflows/
├── aiwb-pr-review.yml      # Automated PR code review using AIWB
├── aiwb-commit-check.yml   # Validate commit messages
├── aiwb-changelog.yml      # Auto-generate changelog on release
└── aiwb-test.yml           # Run AIWB tests on PR
```

---

## 3. Feature Specifications

### 3.1 Git Workflow Features

#### Feature: AI-Powered Commit Messages

**Functionality:**
1. Analyze `git diff --staged` to understand changes
2. Use Generator AI to create commit message following conventions
3. Use Verifier AI to ensure message is clear and follows best practices
4. Present to user for approval/editing
5. Commit with generated message

**User Experience:**
```bash
$ aiwb
> /commit

Analyzing staged changes...
Files changed: 3 (lib/api.sh, lib/github.sh, docs/GITHUB_INTEGRATION_PLAN.md)

🤖 Generator: Creating commit message...
✓ Verifier: Message follows conventional commits format

Proposed commit message:
┌─────────────────────────────────────────┐
│ feat(github): Add GitHub API integration│
│                                         │
│ - Implement lib/github.sh with API     │
│   wrapper functions                     │
│ - Add authentication with token storage│
│ - Support for issues and PR management │
│ - Update docs with integration plan    │
└─────────────────────────────────────────┘

[A]ccept  [E]dit  [R]egenerate  [C]ancel
```

**Configuration:**
- Commit message style (conventional, semantic, custom)
- Verifier strictness level
- Auto-commit option for /make mode

#### Feature: Branch Analysis & Management

**Functionality:**
1. Analyze current branch against main/master
2. Identify divergence points and conflicts
3. Suggest branch cleanup or merge strategies
4. AI-powered branch naming suggestions

**User Experience:**
```bash
$ aiwb
> /branch analyze

Current branch: feature/github-integration
Base branch: main
Commits ahead: 12
Commits behind: 3
Conflicts: Potential (lib/api.sh modified in both)

🤖 AI Analysis:
- Branch has significant divergence (12 commits)
- Recommendation: Rebase onto main to resolve conflicts
- Estimated conflict complexity: Medium
- Suggested merge strategy: Rebase and squash

[R]ebase  [M]erge  [V]iew conflicts  [B]ack
```

#### Feature: AI-Assisted Merge Conflict Resolution

**Functionality:**
1. Detect merge conflicts
2. Parse conflict markers and understand both versions
3. Use AI to propose resolution based on context
4. Present diff visualization with AI suggestions
5. Allow user to accept, modify, or reject

**User Experience:**
```bash
$ aiwb
> /conflict resolve

Found 2 conflicts:
1. lib/api.sh (lines 45-67)
2. README.md (lines 12-18)

Analyzing conflict 1/2: lib/api.sh
🤖 Understanding context...
✓ Generator: Proposed resolution
✓ Verifier: Resolution maintains both feature sets

Conflict: Function signature mismatch
<<<<<< HEAD (feature/github-integration)
function call_api() {
    local endpoint="$1"
    local token="$2"
======
function call_api() {
    local provider="$1"
    local endpoint="$2"
>>>>>> main

🤖 AI Suggestion: Merge both changes
function call_api() {
    local provider="$1"
    local endpoint="$2"
    local token="${3:-}"  # Optional token param

Reasoning: New parameter added in main (provider) should be
retained. Token can be optional for backward compatibility.

[A]ccept  [E]dit  [S]kip  [M]anual
```

#### Feature: Changelog Generation

**Functionality:**
1. Parse git log with semantic commit messages
2. Group changes by type (feat, fix, refactor, etc.)
3. Generate markdown changelog
4. Support version tagging and release notes

**Configuration:**
- Changelog format (Keep a Changelog, conventional, custom)
- Group by type, scope, or date
- Include/exclude certain commit types
- Link to issues/PRs

### 3.2 GitHub API Integration

#### Feature: Issue Management

**Commands:**
```bash
/gh-issue list              # List open issues
/gh-issue create            # Create new issue with AI-generated template
/gh-issue <number>          # View specific issue
/gh-issue close <number>    # Close issue
/gh-issue comment <number>  # Add comment to issue
```

**AI Enhancements:**
- Generate issue templates based on bug/feature type
- Suggest related issues based on content
- Auto-label issues based on description
- Generate issue summary from code/errors

#### Feature: Pull Request Management

**Commands:**
```bash
/gh-pr list                 # List open PRs
/gh-pr create               # Create PR with AI-generated description
/gh-pr <number>             # View specific PR
/gh-pr review <number>      # AI code review of PR
/gh-pr merge <number>       # Merge PR (with checks)
```

**AI Enhancements:**
- Generate comprehensive PR descriptions from commits
- Automated code review with inline comments
- Suggest reviewers based on changed files
- Generate test plan from code changes

**User Experience:**
```bash
$ aiwb
> /gh-pr create

Analyzing commits on branch: feature/github-integration
Comparing with: main

🤖 Generating PR description...

Title: Add comprehensive GitHub integration to AIWB

Description:
┌─────────────────────────────────────────────────────┐
│ ## Summary                                          │
│ This PR adds full GitHub integration to AIWB,      │
│ including:                                          │
│ - Git workflow automation (commits, branches)      │
│ - GitHub API integration (issues, PRs, releases)   │
│ - Pre-commit hooks with AI code review            │
│ - GitHub Actions workflows                         │
│                                                     │
│ ## Changes                                          │
│ - **New Module:** lib/github.sh (500 lines)        │
│ - **Enhanced Commands:** /commit, /branch, /gh-*   │
│ - **Documentation:** GITHUB_INTEGRATION_PLAN.md    │
│                                                     │
│ ## Test Plan                                        │
│ - [ ] Test commit message generation               │
│ - [ ] Test branch analysis                         │
│ - [ ] Test GitHub API authentication               │
│ - [ ] Test PR creation workflow                    │
│                                                     │
│ ## Breaking Changes                                 │
│ None                                                │
└─────────────────────────────────────────────────────┘

Reviewers: (AI suggestions based on git blame)
- @contributor1 (modified lib/api.sh recently)
- @contributor2 (maintains docs/)

[C]reate PR  [E]dit  [P]review  [B]ack
```

#### Feature: Release Management

**Commands:**
```bash
/gh-release list            # List releases
/gh-release create          # Create new release with AI changelog
/gh-release draft           # Create draft release
```

**AI Enhancements:**
- Auto-generate release notes from commits
- Suggest version bump (major/minor/patch) based on changes
- Create comprehensive changelog with grouped changes
- Identify breaking changes automatically

### 3.3 Pre-commit Hooks

#### Feature: AI Code Review Hook

**Installation:**
```bash
$ aiwb
> /review install-hook

Installing AIWB pre-commit hook...
✓ Created .git/hooks/pre-commit
✓ Made executable
✓ Configured to use current API settings

Hook will:
- Analyze staged changes before commit
- Run AI code review
- Check for common issues
- Suggest improvements

[Enable for this repo] [Enable globally]
```

**Hook Behavior:**
1. **Fast path:** If changes are small, quick review with Haiku model
2. **Thorough path:** Large changes get full Generator-Verifier review
3. **Interactive:** Present findings and allow bypass if needed
4. **Configurable:** Set review strictness, auto-fix options

**User Experience:**
```bash
$ git commit -m "Add feature"

AIWB Pre-commit Review
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Analyzing 145 lines across 3 files...

⚠ Issues Found (2):

1. lib/github.sh:67
   Security: API token exposed in function call
   Suggestion: Use environment variable instead

   - github_api_call("https://api.github.com", "ghp_abc123")
   + github_api_call("https://api.github.com", "$GITHUB_TOKEN")

2. lib/github.sh:112
   Best Practice: Missing error handling
   Suggestion: Add error check for curl command

   + if ! response=$(curl ...); then
   +     handle_error "API call failed"
   +     return 1
   + fi

✓ No critical issues
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[F]ix automatically  [I]gnore and commit  [A]bort  [V]iew details
```

---

## 4. Implementation Phases

### Phase 1: Foundation (Week 1-2)
**Deliverables:**
- [ ] Create lib/github.sh with basic structure
- [ ] Implement GitHub API authentication and token storage
- [ ] Add git diff parsing and analysis utilities
- [ ] Create basic /commit command with AI message generation
- [ ] Write unit tests for core functions

**Dependencies:**
- Extend lib/security.sh for GitHub token encryption
- Update lib/ui.sh for git-specific UI components

### Phase 2: Git Workflows (Week 3-4)
**Deliverables:**
- [ ] Complete /commit command with Verifier loop
- [ ] Implement /branch analyze command
- [ ] Add /conflict resolve with AI suggestions
- [ ] Create /changelog command
- [ ] Integrate with existing /make, /tweak, /debug modes

**Dependencies:**
- Phase 1 completion
- Testing framework for git operations

### Phase 3: GitHub API Features (Week 5-6)
**Deliverables:**
- [ ] Implement /gh-issue commands (list, create, view, close)
- [ ] Implement /gh-pr commands (list, create, view, review)
- [ ] Add /gh-release commands
- [ ] Create AI-powered PR description generator
- [ ] Add automated code review for PRs

**Dependencies:**
- Phase 1 completion (API authentication)
- GitHub API testing environment

### Phase 4: Automation & Hooks (Week 7-8)
**Deliverables:**
- [ ] Create pre-commit hook with AI review
- [ ] Implement hook installation command
- [ ] Add configuration for hook behavior
- [ ] Create GitHub Actions workflows
- [ ] Add CI/CD integration examples

**Dependencies:**
- Phase 2 & 3 completion
- Testing in real repositories

### Phase 5: Documentation & Polish (Week 9-10)
**Deliverables:**
- [ ] Complete user documentation (GITHUB_INTEGRATION.md)
- [ ] Create tutorial and examples
- [ ] Add configuration reference
- [ ] Write contributor guide for GitHub features
- [ ] Create video demos/GIFs
- [ ] Comprehensive test suite

**Dependencies:**
- All previous phases
- User feedback from beta testing

---

## 5. Technical Specifications

### 5.1 GitHub API Integration

**Authentication:**
- Token-based authentication (Personal Access Tokens)
- Secure storage using age encryption (like API keys)
- Support for fine-grained tokens with minimal permissions
- Token validation and refresh

**API Endpoints to Support:**
```bash
# Repository
GET /repos/{owner}/{repo}
GET /repos/{owner}/{repo}/commits

# Issues
GET /repos/{owner}/{repo}/issues
POST /repos/{owner}/{repo}/issues
PATCH /repos/{owner}/{repo}/issues/{number}
POST /repos/{owner}/{repo}/issues/{number}/comments

# Pull Requests
GET /repos/{owner}/{repo}/pulls
POST /repos/{owner}/{repo}/pulls
GET /repos/{owner}/{repo}/pulls/{number}
POST /repos/{owner}/{repo}/pulls/{number}/reviews
PUT /repos/{owner}/{repo}/pulls/{number}/merge

# Releases
GET /repos/{owner}/{repo}/releases
POST /repos/{owner}/{repo}/releases
```

**Rate Limiting:**
- Implement rate limit detection (5000 req/hour for authenticated)
- Cache API responses where appropriate
- Graceful degradation when rate limited
- User notification of rate limit status

**Error Handling:**
- Network errors (retry with exponential backoff)
- Authentication errors (prompt for token refresh)
- Permission errors (clear error messages)
- API changes (version compatibility checks)

### 5.2 Git Integration

**Git Commands Used:**
```bash
# Diff and Status
git diff --staged                    # Staged changes for commit
git diff main...feature-branch       # Branch comparison
git status --porcelain              # Machine-readable status
git log --oneline --graph           # Commit history

# Branch Management
git branch -vv                       # Branch list with tracking
git rev-parse --abbrev-ref HEAD     # Current branch name
git merge-base main HEAD            # Find common ancestor

# Conflict Detection
git diff --name-only --diff-filter=U  # List conflicted files
git diff --check                       # Check for whitespace issues

# History Analysis
git log --pretty=format:"%s"        # Commit messages
git blame -L start,end file         # Line-level attribution
git show commit:file                # File at specific commit
```

**Repository Detection:**
- Automatic git repository detection (check for .git/)
- Handle git worktrees and submodules
- Support bare repositories (limited functionality)
- Graceful degradation in non-git directories

### 5.3 AI Model Selection

**Generator Models (for creation):**
- Primary: Gemini 2.0 Flash (fast, cost-effective)
- Fallback: Claude 3.5 Haiku (for complex commit messages)
- Local: Ollama models for offline usage

**Verifier Models (for review):**
- Primary: Claude 3.5 Sonnet (thorough analysis)
- Fast: Gemini 2.5 Flash (quick checks)
- Configurable based on task complexity

**Prompts:**
- Template system for git-specific prompts
- Context-aware prompts based on file types
- Conventional commit format enforcement
- Code review best practices prompts

### 5.4 Configuration

**New Configuration Options:**
```bash
# GitHub Settings
github_token=""                      # Encrypted GitHub token
github_username=""                   # GitHub username
github_default_repo=""              # Default repo for commands

# Commit Settings
commit_style="conventional"          # conventional, semantic, custom
commit_auto_verify=true             # Always run Verifier on commits
commit_require_approval=true        # User approval before commit

# Branch Settings
branch_naming_convention="feature/*" # Branch naming pattern
branch_auto_suggest=true            # AI branch name suggestions

# Review Settings
review_pre_commit_enabled=false     # Enable pre-commit hook
review_strictness="medium"          # low, medium, high
review_auto_fix=false              # Auto-apply suggested fixes

# PR Settings
pr_auto_fill_description=true       # Generate PR descriptions
pr_suggest_reviewers=true           # Suggest reviewers
pr_include_test_plan=true          # Add test plan to PR

# Changelog Settings
changelog_format="keepachangelog"   # keepachangelog, conventional
changelog_group_by="type"           # type, scope, date
changelog_include_all=false         # Include all commit types
```

### 5.5 Security Considerations

**Token Security:**
- Store GitHub tokens encrypted with age (same as API keys)
- Never log tokens or expose in debug output
- Support token scoping (request minimal permissions)
- Regular token validation and expiry checks

**Code Safety:**
- Never auto-commit without user confirmation
- Require explicit approval for destructive operations (force push, etc.)
- Validate AI-generated commands before execution
- Sandbox execution for untrusted repositories

**Privacy:**
- Don't send full repository content to AI APIs
- Only send diffs/relevant context
- Respect .gitignore and .aiwb-ignore patterns
- Option to review all AI API requests

---

## 6. User Documentation Plan

### 6.1 Documentation Structure

**New Documentation Files:**
```
docs/
├── GITHUB_INTEGRATION.md           # Main integration guide
├── GITHUB_COMMANDS_REFERENCE.md    # Command reference
├── GITHUB_WORKFLOWS.md             # Workflow examples
├── GITHUB_API_SETUP.md             # API setup and authentication
└── GITHUB_TROUBLESHOOTING.md       # Common issues and solutions
```

**Update Existing Documentation:**
- README.md: Add GitHub integration highlights
- QUICKSTART.md: Include GitHub setup steps
- USAGE.md: Add GitHub command examples
- ROADMAP.md: Update with implementation status

### 6.2 Example Workflows

**Workflow 1: AI-Assisted Feature Development**
```bash
# 1. Create feature branch with AI suggestion
$ aiwb
> /branch create
AI suggests: feature/github-integration-api

# 2. Develop using /make mode
> /make
make> prompt Create GitHub API wrapper functions
make> model gemini 2.0-flash
make> uploads lib/api.sh
make> run

# 3. AI-powered commit
> /commit
[Generated commit message shown]
[Verifier approves]
Committed: feat(github): Add GitHub API wrapper functions

# 4. Create PR with AI description
> /gh-pr create
[AI generates comprehensive PR description]
PR created: #123
```

**Workflow 2: Code Review Automation**
```bash
# Developer pushes changes
$ git push origin feature/new-feature

# GitHub Action triggers AIWB review
# Posts automated review comments on PR

# Developer reviews AI suggestions locally
$ aiwb
> /gh-pr review 123
[Shows AI review with inline suggestions]
[Developer can apply or dismiss suggestions]
```

**Workflow 3: Release Preparation**
```bash
# 1. Generate changelog
$ aiwb
> /changelog generate --from v2.0.0 --to HEAD
[AI analyzes commits and creates changelog]

# 2. Create release
> /gh-release create
Version: v2.1.0
[AI generates release notes from changelog]
[Includes breaking changes, features, fixes]

# 3. Review and publish
[Preview release notes]
[Publish to GitHub]
```

---

## 7. Testing Strategy

### 7.1 Unit Tests

**Test Coverage for lib/github.sh:**
- Git command parsing and output handling
- GitHub API request construction
- Response parsing and error handling
- Token encryption/decryption
- Diff analysis functions
- Commit message generation

**Test Framework:**
- Use existing test_aiwb_*.sh framework
- Add github-specific test suite: test_github_integration.sh
- Mock git commands for consistent testing
- Mock GitHub API responses

### 7.2 Integration Tests

**Test Scenarios:**
1. **Commit Message Generation:**
   - Test with various diff types (add, modify, delete)
   - Test with multiple files
   - Test with merge commits
   - Test with empty commits

2. **Branch Analysis:**
   - Test with feature branches ahead/behind main
   - Test with merge conflicts
   - Test with complex branch histories

3. **GitHub API:**
   - Test authentication flow
   - Test rate limiting handling
   - Test error scenarios (network, permissions)
   - Test pagination for large result sets

4. **Pre-commit Hooks:**
   - Test with various code changes
   - Test with security issues
   - Test with style violations
   - Test bypass mechanisms

### 7.3 Manual Testing Checklist

**Before Release:**
- [ ] Test in fresh git repository
- [ ] Test in existing repository with history
- [ ] Test with various git configurations
- [ ] Test with different GitHub account types
- [ ] Test on Linux, macOS, Termux
- [ ] Test with different AI models/providers
- [ ] Test with rate limiting scenarios
- [ ] Test with network failures
- [ ] Test with invalid credentials
- [ ] Test user documentation accuracy

---

## 8. Success Metrics

**User Adoption:**
- 50% of active users enable GitHub integration within 1 month
- 25% of users install pre-commit hooks
- Average 10+ /commit or /gh-* commands per user per week

**Quality Metrics:**
- 90%+ user acceptance rate for AI-generated commit messages
- 80%+ user acceptance rate for AI PR descriptions
- 70%+ of pre-commit issues fixed before commit
- <5% false positive rate in code reviews

**Performance:**
- Commit message generation: <5 seconds
- Branch analysis: <10 seconds
- PR creation: <15 seconds
- Pre-commit hook: <30 seconds (configurable timeout)

**Cost Efficiency:**
- Average cost per commit: <$0.01
- Average cost per PR review: <$0.10
- Total monthly cost increase: <$5 for active user

---

## 9. Risks and Mitigation

### 9.1 Technical Risks

**Risk: GitHub API Rate Limiting**
- **Impact:** Users hit rate limits with frequent commands
- **Probability:** Medium
- **Mitigation:**
  - Implement response caching
  - Show rate limit status to users
  - Use conditional requests (ETags)
  - Graceful degradation when limited

**Risk: Git Command Compatibility**
- **Impact:** Different git versions behave differently
- **Probability:** Medium
- **Mitigation:**
  - Test with multiple git versions (2.20+)
  - Use portable git commands
  - Feature detection for advanced commands
  - Clear error messages for unsupported features

**Risk: AI Model Availability**
- **Impact:** API downtime affects git workflows
- **Probability:** Low
- **Mitigation:**
  - Fallback to simpler commit messages
  - Local mode with Ollama
  - Queue commands for retry
  - Graceful degradation

### 9.2 User Experience Risks

**Risk: Learning Curve**
- **Impact:** Users find GitHub features too complex
- **Probability:** Medium
- **Mitigation:**
  - Comprehensive documentation
  - Interactive tutorials
  - /wizard integration for GitHub tasks
  - Sensible defaults

**Risk: Over-automation**
- **Impact:** Users lose control, distrust AI suggestions
- **Probability:** Low
- **Mitigation:**
  - Always show AI reasoning
  - Require user approval for critical actions
  - Easy override/bypass mechanisms
  - Transparency in AI decisions

### 9.3 Security Risks

**Risk: Token Exposure**
- **Impact:** GitHub tokens leaked in logs or errors
- **Probability:** Low
- **Mitigation:**
  - Encrypted token storage
  - No logging of sensitive data
  - Regular security audits
  - Clear documentation on token permissions

**Risk: Malicious Code in AI Responses**
- **Impact:** AI suggests harmful git commands
- **Probability:** Very Low
- **Mitigation:**
  - Whitelist of safe git commands
  - User confirmation for destructive operations
  - Sandbox testing environment
  - Clear warnings for dangerous actions

---

## 10. Future Enhancements (Post-MVP)

### 10.1 Advanced Features

**Multi-Repository Management:**
- Manage multiple repos from single AIWB session
- Cross-repo change coordination
- Mono-repo support with workspace awareness

**Advanced Conflict Resolution:**
- 3-way merge visualization
- AI-powered semantic merge
- Conflict prediction before merge

**GitHub Workflows Integration:**
- Trigger GitHub Actions from AIWB
- Monitor workflow runs
- View logs and artifacts
- Re-run failed workflows

**Team Features:**
- Shared configuration templates
- Team coding standards enforcement
- Collaborative code review
- Usage analytics for teams

### 10.2 Integration Opportunities

**Editor Integration:**
- VS Code extension calling AIWB for commits
- Vim plugin for in-editor GitHub operations
- JetBrains IDE integration

**CI/CD Platforms:**
- GitLab CI support
- Bitbucket Pipelines
- Generic webhook support

**Other Git Platforms:**
- GitLab API integration
- Bitbucket API integration
- Self-hosted git servers (Gitea, Gogs)

---

## 11. Timeline and Milestones

### Milestone 1: Foundation (End of Week 2)
- lib/github.sh created with basic API integration
- GitHub token authentication working
- Basic /commit command functional
- **Demo:** Show AI-generated commit message

### Milestone 2: Git Workflows (End of Week 4)
- All git workflow commands implemented
- Integration with existing modes complete
- **Demo:** Complete workflow from /make to /commit

### Milestone 3: GitHub API (End of Week 6)
- Issues and PR management working
- Automated PR code review functional
- **Demo:** Create issue, PR, and review from AIWB

### Milestone 4: Automation (End of Week 8)
- Pre-commit hooks installed and working
- GitHub Actions workflows created
- **Demo:** Pre-commit review preventing bugs

### Milestone 5: Release (End of Week 10)
- Documentation complete
- All tests passing
- Beta testing complete
- **Release:** AIWB v2.1 with GitHub integration

---

## 12. Open Questions

1. **Commit Message Style:**
   - Should we enforce a single style (conventional commits) or support multiple?
   - How strict should the Verifier be on commit message format?

2. **API Costs:**
   - What's the acceptable cost per commit/PR for users?
   - Should we have a "budget mode" for cost-sensitive users?

3. **Pre-commit Hook Default:**
   - Should hooks be opt-in or opt-out?
   - Should we have different hook profiles (strict, balanced, lenient)?

4. **Multi-repo Support:**
   - Should MVP support multiple repos or defer to future?
   - How do we handle repo context switching?

5. **GitHub Enterprise:**
   - Should we support GitHub Enterprise from day one?
   - Different API endpoints and authentication?

---

## 13. Appendix

### A. Conventional Commit Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:** feat, fix, docs, style, refactor, perf, test, chore

### B. GitHub Token Permissions

**Minimum Required Permissions:**
- `repo` - Full control of private repositories
  - `repo:status` - Access commit status
  - `repo_deployment` - Access deployment status
  - `public_repo` - Access public repositories
- `workflow` - Update GitHub Action workflows (optional)

### C. Related Projects

**Inspiration:**
- GitHub CLI (`gh`) - Command-line GitHub integration
- Conventional Commits - Commit message specification
- commitizen - Interactive commit message tool
- semantic-release - Automated release management

### D. References

- [GitHub REST API Documentation](https://docs.github.com/en/rest)
- [Git Documentation](https://git-scm.com/doc)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)

---

**End of Document**

*This plan is a living document and will be updated as implementation progresses and requirements evolve.*
