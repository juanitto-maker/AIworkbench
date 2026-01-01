#!/usr/bin/env bash
# github.sh - GitHub integration for AIWB (similar to Claude Code)
# Provides repository management, issues, PRs, and git operations

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[[ -z "${AIWB_LIB_CONFIG_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
[[ -z "${AIWB_LIB_UI_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"

# ============================================================================
# GITHUB CONFIGURATION
# ============================================================================

GITHUB_API_ENDPOINT="https://api.github.com"

# Get GitHub token (from config or environment)
get_github_token() {
    local env_file token
    env_file="$(get_env_file)"

    # Source env file if exists
    if [[ -f "$env_file" ]]; then
        source "$env_file"
    fi

    # Check multiple sources for token
    token="${GITHUB_TOKEN:-}"
    [[ -z "$token" ]] && token="${GH_TOKEN:-}"

    echo "$token"
}

# Check if GitHub token is set
has_github_token() {
    local token
    token="$(get_github_token)"
    [[ -n "$token" ]]
}

# Set GitHub token
set_github_token() {
    local token="$1"
    local env_file
    env_file="$(get_env_file)"

    if [[ -z "$token" ]]; then
        err "GitHub token cannot be empty"
        return 1
    fi

    # Create or update env file
    ensure_dir "$(dirname "$env_file")"
    touch "$env_file"
    chmod 600 "$env_file"

    # Update or append key
    if grep -q "^export GITHUB_TOKEN=" "$env_file" 2>/dev/null; then
        if is_macos; then
            sed -i '' "s|^export GITHUB_TOKEN=.*|export GITHUB_TOKEN=\"${token}\"|" "$env_file"
        else
            sed -i "s|^export GITHUB_TOKEN=.*|export GITHUB_TOKEN=\"${token}\"|" "$env_file"
        fi
    else
        echo "export GITHUB_TOKEN=\"${token}\"" >> "$env_file"
    fi

    # Export to current session
    export GITHUB_TOKEN="$token"

    success "GitHub token saved securely"
}

# ============================================================================
# GITHUB API HELPERS
# ============================================================================

# Make authenticated GitHub API request
github_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    local token
    token="$(get_github_token)"

    if [[ -z "$token" ]]; then
        err "GitHub token not set. Run: aiwb github auth"
        return 1
    fi

    local url="${GITHUB_API_ENDPOINT}${endpoint}"
    local curl_args=(
        -sS
        --max-time 30
        --connect-timeout 10
        -H "Accept: application/vnd.github+json"
        -H "Authorization: Bearer $token"
        -H "X-GitHub-Api-Version: 2022-11-28"
        -X "$method"
    )

    if [[ -n "$data" ]]; then
        curl_args+=(-H "Content-Type: application/json" -d "$data")
    fi

    local response http_code
    local tmp_file=$(mktemp)

    http_code=$(curl "${curl_args[@]}" -w "%{http_code}" -o "$tmp_file" "$url")
    response=$(cat "$tmp_file")
    rm -f "$tmp_file"

    # Check for errors
    if [[ "$http_code" -ge 400 ]]; then
        local error_msg
        error_msg=$(echo "$response" | jq -r '.message // "Unknown error"' 2>/dev/null)
        err "GitHub API error ($http_code): $error_msg"
        debug "Full response: $response"
        return 1
    fi

    echo "$response"
}

# ============================================================================
# REPOSITORY OPERATIONS
# ============================================================================

# Get current repository info (from git remote)
github_get_current_repo() {
    if ! have git; then
        err "Git is not installed"
        return 1
    fi

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        err "Not in a git repository"
        return 1
    fi

    # Try to get the remote URL
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null)

    if [[ -z "$remote_url" ]]; then
        err "No origin remote configured"
        return 1
    fi

    # Parse owner/repo from URL
    local owner_repo
    if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
        owner_repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    else
        err "Could not parse GitHub repository from remote URL: $remote_url"
        return 1
    fi

    echo "$owner_repo"
}

# Clone a repository
github_clone() {
    local repo="$1"
    local dest="${2:-}"

    if ! have git; then
        err "Git is not installed"
        return 1
    fi

    # If only repo name given (no owner), try to get from user
    if [[ ! "$repo" =~ / ]]; then
        local token
        token="$(get_github_token)"
        if [[ -n "$token" ]]; then
            # Get authenticated user
            local user
            user=$(github_api GET "/user" | jq -r '.login // empty' 2>/dev/null)
            if [[ -n "$user" ]]; then
                repo="$user/$repo"
            fi
        fi
    fi

    local url="https://github.com/${repo}.git"

    if [[ -z "$dest" ]]; then
        dest="${repo##*/}"
    fi

    msg "Cloning $repo..."

    if git clone "$url" "$dest"; then
        success "Cloned to $dest"
        return 0
    else
        err "Failed to clone $repo"
        return 1
    fi
}

# Get repository info
github_repo_info() {
    local repo="${1:-}"

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    github_api GET "/repos/$repo"
}

# List repositories (for authenticated user)
github_list_repos() {
    local type="${1:-all}"  # all, owner, public, private, member
    local sort="${2:-updated}"  # created, updated, pushed, full_name
    local per_page="${3:-30}"

    github_api GET "/user/repos?type=$type&sort=$sort&per_page=$per_page"
}

# Fork a repository
github_fork() {
    local repo="$1"
    local org="${2:-}"  # Optional: fork to organization

    local data="{}"
    if [[ -n "$org" ]]; then
        data="{\"organization\": \"$org\"}"
    fi

    msg "Forking $repo..."
    local response
    response=$(github_api POST "/repos/$repo/forks" "$data")

    if [[ $? -eq 0 ]]; then
        local fork_url
        fork_url=$(echo "$response" | jq -r '.html_url // empty')
        success "Forked to: $fork_url"
        echo "$response"
    fi
}

# ============================================================================
# GIT OPERATIONS (Local)
# ============================================================================

# Get git status with nice formatting
github_status() {
    if ! have git; then
        err "Git is not installed"
        return 1
    fi

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        err "Not in a git repository"
        return 1
    fi

    # Auto-fetch from remote to get accurate ahead/behind status
    git fetch origin --quiet 2>/dev/null || true

    ui_header "Git Status"

    # Current branch
    local branch
    branch=$(git branch --show-current 2>/dev/null || echo "HEAD detached")
    echo "Branch: ${CYAN}$branch${RESET}"

    # Remote tracking
    local tracking
    tracking=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "none")
    echo "Tracking: $tracking"

    # Ahead/behind
    if [[ "$tracking" != "none" ]]; then
        local ahead behind
        ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
        behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
        echo "Ahead: $ahead, Behind: $behind"
    fi

    echo ""

    # Status
    local status_output
    status_output=$(git status --porcelain 2>/dev/null)

    if [[ -z "$status_output" ]]; then
        success "Working tree clean"
    else
        echo "Changes:"
        echo "$status_output" | while read -r line; do
            local status="${line:0:2}"
            local file="${line:3}"
            case "$status" in
                "M "*)  echo "  ${GREEN}modified:${RESET}   $file" ;;
                " M"*)  echo "  ${YELLOW}modified:${RESET}   $file (not staged)" ;;
                "A "*)  echo "  ${GREEN}added:${RESET}      $file" ;;
                "D "*)  echo "  ${RED}deleted:${RESET}    $file" ;;
                "R "*)  echo "  ${BLUE}renamed:${RESET}    $file" ;;
                "??"*)  echo "  ${DIM}untracked:${RESET}  $file" ;;
                *)      echo "  $line" ;;
            esac
        done
    fi

    echo ""

    # Recent commits
    echo "Recent commits:"
    git log --oneline -5 2>/dev/null | while read -r line; do
        echo "  $line"
    done
}

# Stage files
github_add() {
    local files=("$@")

    if [[ ${#files[@]} -eq 0 ]]; then
        # Add all changes
        git add -A
        success "Staged all changes"
    else
        git add "${files[@]}"
        success "Staged: ${files[*]}"
    fi
}

# Commit changes
github_commit() {
    local message="$1"
    local files=("${@:2}")

    if [[ -z "$message" ]]; then
        err "Commit message required"
        return 1
    fi

    # Stage files if specified
    if [[ ${#files[@]} -gt 0 ]]; then
        git add "${files[@]}"
    fi

    # Check if there's anything to commit
    if git diff --cached --quiet 2>/dev/null; then
        warn "Nothing to commit"
        return 0
    fi

    if git commit -m "$message"; then
        local hash
        hash=$(git rev-parse --short HEAD)
        success "Committed: $hash - $message"
    else
        err "Commit failed"
        return 1
    fi
}

# Push changes
github_push() {
    local remote="${1:-origin}"
    local branch="${2:-}"
    local force="${3:-false}"

    if [[ -z "$branch" ]]; then
        branch=$(git branch --show-current 2>/dev/null)
    fi

    local push_args=("$remote" "$branch")

    # Set upstream if not tracking
    if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
        push_args=("-u" "$remote" "$branch")
    fi

    if [[ "$force" == "true" ]]; then
        push_args+=("--force")
        warn "Force pushing to $remote/$branch..."
    else
        msg "Pushing to $remote/$branch..."
    fi

    if git push "${push_args[@]}"; then
        success "Pushed successfully"
    else
        err "Push failed"
        return 1
    fi
}

# Pull changes
github_pull() {
    local remote="${1:-origin}"
    local branch="${2:-}"

    if [[ -z "$branch" ]]; then
        branch=$(git branch --show-current 2>/dev/null)
    fi

    msg "Pulling from $remote/$branch..."

    if git pull "$remote" "$branch"; then
        success "Pulled successfully"
    else
        err "Pull failed (possible conflicts)"
        return 1
    fi
}

# Fetch changes
github_fetch() {
    local remote="${1:-origin}"

    msg "Fetching from $remote..."

    if git fetch "$remote"; then
        success "Fetched successfully"
    else
        err "Fetch failed"
        return 1
    fi
}

# Sync with remote (fetch, pull, push as needed)
github_sync() {
    local remote="${1:-origin}"

    if ! have git; then
        err "Git is not installed"
        return 1
    fi

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        err "Not in a git repository"
        return 1
    fi

    # Get current branch
    local branch
    branch=$(git branch --show-current 2>/dev/null)
    if [[ -z "$branch" ]]; then
        err "HEAD is detached, cannot sync"
        return 1
    fi

    msg "Syncing with remote..."

    # Fetch from remote silently
    if ! git fetch "$remote" --quiet 2>/dev/null; then
        err "Failed to fetch from $remote (network issue?)"
        return 1
    fi

    # Check if remote branch exists
    if ! git rev-parse --verify "$remote/$branch" >/dev/null 2>&1; then
        warn "Remote branch $remote/$branch does not exist"
        echo "Branch: ${CYAN}$branch${RESET}"
        echo ""
        if ui_confirm "Push local branch to remote?" "yes"; then
            github_push "$remote" "$branch"
        fi
        return 0
    fi

    # Calculate ahead/behind
    local ahead behind
    ahead=$(git rev-list --count "$remote/$branch..HEAD" 2>/dev/null || echo "0")
    behind=$(git rev-list --count "HEAD..$remote/$branch" 2>/dev/null || echo "0")

    echo "Branch: ${CYAN}$branch${RESET}"

    # Handle different scenarios
    if [[ "$ahead" -eq 0 && "$behind" -eq 0 ]]; then
        # In sync
        success "Already in sync with remote"
        return 0

    elif [[ "$ahead" -eq 0 && "$behind" -gt 0 ]]; then
        # Behind only
        echo "Behind: ${YELLOW}$behind${RESET} commits"
        echo ""
        echo "Commits to pull:"
        git log HEAD.."$remote/$branch" --oneline --no-decorate 2>/dev/null | while IFS= read -r commit; do
            echo "  $commit"
        done
        echo ""

        if ui_confirm "Pull these $behind commit(s) from remote?" "yes"; then
            msg "Pulling from $remote/$branch..."
            if git pull "$remote" "$branch"; then
                success "Pulled successfully"
                success "Sync complete!"
            else
                err "Pull failed (possible conflicts)"
                return 1
            fi
        else
            warn "Sync cancelled"
        fi

    elif [[ "$ahead" -gt 0 && "$behind" -eq 0 ]]; then
        # Ahead only
        echo "Ahead: ${GREEN}$ahead${RESET} commits"
        echo ""
        echo "Commits to push:"
        git log "$remote/$branch..HEAD" --oneline --no-decorate 2>/dev/null | while IFS= read -r commit; do
            echo "  $commit"
        done
        echo ""

        if ui_confirm "Push these $ahead commit(s) to remote?" "yes"; then
            msg "Pushing to $remote/$branch..."
            if git push "$remote" "$branch"; then
                success "Pushed successfully"
                success "Sync complete!"
            else
                err "Push failed"
                return 1
            fi
        else
            warn "Sync cancelled"
        fi

    else
        # Both ahead and behind (diverged)
        echo "Ahead: ${GREEN}$ahead${RESET}, Behind: ${YELLOW}$behind${RESET}"
        echo ""
        warn "Branches have diverged!"
        echo ""

        echo "Commits to pull:"
        git log HEAD.."$remote/$branch" --oneline --no-decorate 2>/dev/null | while IFS= read -r commit; do
            echo "  $commit"
        done
        echo ""

        echo "Commits to push:"
        git log "$remote/$branch..HEAD" --oneline --no-decorate 2>/dev/null | while IFS= read -r commit; do
            echo "  $commit"
        done
        echo ""

        if ui_confirm "Pull first, then push?" "yes"; then
            msg "Pulling from $remote/$branch..."
            if git pull "$remote" "$branch"; then
                success "Pulled successfully"

                # After pull, check if we still need to push
                local new_ahead
                new_ahead=$(git rev-list --count "$remote/$branch..HEAD" 2>/dev/null || echo "0")

                if [[ "$new_ahead" -gt 0 ]]; then
                    msg "Pushing to $remote/$branch..."
                    if git push "$remote" "$branch"; then
                        success "Pushed successfully"
                        success "Sync complete!"
                    else
                        err "Push failed"
                        return 1
                    fi
                else
                    success "Sync complete!"
                fi
            else
                err "Pull failed (possible conflicts)"
                echo ""
                warn "Please resolve conflicts manually and try again"
                return 1
            fi
        else
            warn "Sync cancelled"
        fi
    fi
}

# ============================================================================
# BRANCH OPERATIONS
# ============================================================================

# List branches
github_branches() {
    local show_remote="${1:-false}"

    ui_header "Branches"

    local current
    current=$(git branch --show-current 2>/dev/null)

    echo "Local branches:"
    git branch --list 2>/dev/null | while read -r line; do
        if [[ "$line" == "* "* ]]; then
            echo "  ${GREEN}${line}${RESET} (current)"
        else
            echo "  $line"
        fi
    done

    if [[ "$show_remote" == "true" ]]; then
        echo ""
        echo "Remote branches:"
        git branch -r 2>/dev/null | while read -r line; do
            echo "  $line"
        done
    fi
}

# Create and switch to new branch
github_branch_create() {
    local name="$1"
    local base="${2:-}"

    if [[ -z "$name" ]]; then
        err "Branch name required"
        return 1
    fi

    if [[ -n "$base" ]]; then
        git checkout -b "$name" "$base"
    else
        git checkout -b "$name"
    fi

    success "Created and switched to branch: $name"
}

# Switch branch
github_branch_switch() {
    local name="$1"

    if [[ -z "$name" ]]; then
        err "Branch name required"
        return 1
    fi

    if git checkout "$name" 2>/dev/null; then
        success "Switched to branch: $name"
    else
        # Try to checkout remote branch
        if git checkout -b "$name" "origin/$name" 2>/dev/null; then
            success "Checked out remote branch: $name"
        else
            err "Branch not found: $name"
            return 1
        fi
    fi
}

# Delete branch
github_branch_delete() {
    local name="$1"
    local force="${2:-false}"

    if [[ -z "$name" ]]; then
        err "Branch name required"
        return 1
    fi

    local delete_flag="-d"
    [[ "$force" == "true" ]] && delete_flag="-D"

    if git branch "$delete_flag" "$name"; then
        success "Deleted branch: $name"
    else
        err "Failed to delete branch: $name"
        return 1
    fi
}

# ============================================================================
# ISSUE OPERATIONS
# ============================================================================

# List issues
github_issues_list() {
    local repo="${1:-}"
    local state="${2:-open}"  # open, closed, all
    local per_page="${3:-10}"

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    local response
    response=$(github_api GET "/repos/$repo/issues?state=$state&per_page=$per_page")

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    ui_header "Issues for $repo"

    echo "$response" | jq -r '.[] | select(.pull_request == null) | "#\(.number) [\(.state)] \(.title) (@\(.user.login))"' 2>/dev/null
}

# Get issue details
github_issue_view() {
    local repo="${1:-}"
    local number="$2"

    if [[ -z "$number" ]]; then
        err "Issue number required"
        return 1
    fi

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    local response
    response=$(github_api GET "/repos/$repo/issues/$number")

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    ui_header "Issue #$number"

    echo "$response" | jq -r '
        "Title: \(.title)",
        "State: \(.state)",
        "Author: @\(.user.login)",
        "Created: \(.created_at)",
        "Labels: \((.labels | map(.name) | join(", ")) // "none")",
        "",
        "Description:",
        (.body // "No description")
    ' 2>/dev/null

    # Show comments count
    local comments
    comments=$(echo "$response" | jq -r '.comments // 0')
    echo ""
    echo "Comments: $comments"
}

# Create issue
github_issue_create() {
    local repo="${1:-}"
    local title="$2"
    local body="${3:-}"
    local labels="${4:-}"

    if [[ -z "$title" ]]; then
        err "Issue title required"
        return 1
    fi

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    # Build JSON payload
    local payload
    payload=$(jq -n \
        --arg title "$title" \
        --arg body "$body" \
        '{title: $title, body: $body}')

    if [[ -n "$labels" ]]; then
        payload=$(echo "$payload" | jq --arg labels "$labels" '.labels = ($labels | split(","))')
    fi

    local response
    response=$(github_api POST "/repos/$repo/issues" "$payload")

    if [[ $? -eq 0 ]]; then
        local issue_url issue_number
        issue_url=$(echo "$response" | jq -r '.html_url // empty')
        issue_number=$(echo "$response" | jq -r '.number // empty')
        success "Created issue #$issue_number: $issue_url"
        echo "$response"
    fi
}

# Close issue
github_issue_close() {
    local repo="${1:-}"
    local number="$2"

    if [[ -z "$number" ]]; then
        err "Issue number required"
        return 1
    fi

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    local payload='{"state": "closed"}'
    local response
    response=$(github_api PATCH "/repos/$repo/issues/$number" "$payload")

    if [[ $? -eq 0 ]]; then
        success "Closed issue #$number"
    fi
}

# Reopen issue
github_issue_reopen() {
    local repo="${1:-}"
    local number="$2"

    if [[ -z "$number" ]]; then
        err "Issue number required"
        return 1
    fi

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    local payload='{"state": "open"}'
    local response
    response=$(github_api PATCH "/repos/$repo/issues/$number" "$payload")

    if [[ $? -eq 0 ]]; then
        success "Reopened issue #$number"
    fi
}

# Add comment to issue
github_issue_comment() {
    local repo="${1:-}"
    local number="$2"
    local body="$3"

    if [[ -z "$number" || -z "$body" ]]; then
        err "Issue number and comment body required"
        return 1
    fi

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    local payload
    payload=$(jq -n --arg body "$body" '{body: $body}')

    local response
    response=$(github_api POST "/repos/$repo/issues/$number/comments" "$payload")

    if [[ $? -eq 0 ]]; then
        success "Added comment to issue #$number"
    fi
}

# ============================================================================
# PULL REQUEST OPERATIONS
# ============================================================================

# List pull requests
github_pr_list() {
    local repo="${1:-}"
    local state="${2:-open}"  # open, closed, all
    local per_page="${3:-10}"

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    local response
    response=$(github_api GET "/repos/$repo/pulls?state=$state&per_page=$per_page")

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    ui_header "Pull Requests for $repo"

    echo "$response" | jq -r '.[] | "#\(.number) [\(.state)] \(.title) (@\(.user.login)) [\(.head.ref) -> \(.base.ref)]"' 2>/dev/null
}

# Get PR details
github_pr_view() {
    local repo="${1:-}"
    local number="$2"

    if [[ -z "$number" ]]; then
        err "PR number required"
        return 1
    fi

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    local response
    response=$(github_api GET "/repos/$repo/pulls/$number")

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    ui_header "Pull Request #$number"

    echo "$response" | jq -r '
        "Title: \(.title)",
        "State: \(.state)",
        "Author: @\(.user.login)",
        "Branch: \(.head.ref) -> \(.base.ref)",
        "Created: \(.created_at)",
        "Mergeable: \(.mergeable // "checking...")",
        "Changed files: \(.changed_files)",
        "Additions: +\(.additions), Deletions: -\(.deletions)",
        "",
        "Description:",
        (.body // "No description")
    ' 2>/dev/null
}

# Create pull request
github_pr_create() {
    local repo="${1:-}"
    local title="$2"
    local body="${3:-}"
    local head="${4:-}"
    local base="${5:-main}"

    if [[ -z "$title" ]]; then
        err "PR title required"
        return 1
    fi

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    if [[ -z "$head" ]]; then
        head=$(git branch --show-current 2>/dev/null)
        if [[ -z "$head" ]]; then
            err "Could not determine current branch"
            return 1
        fi
    fi

    # Build JSON payload
    local payload
    payload=$(jq -n \
        --arg title "$title" \
        --arg body "$body" \
        --arg head "$head" \
        --arg base "$base" \
        '{title: $title, body: $body, head: $head, base: $base}')

    local response
    response=$(github_api POST "/repos/$repo/pulls" "$payload")

    if [[ $? -eq 0 ]]; then
        local pr_url pr_number
        pr_url=$(echo "$response" | jq -r '.html_url // empty')
        pr_number=$(echo "$response" | jq -r '.number // empty')
        success "Created PR #$pr_number: $pr_url"
        echo "$response"
    fi
}

# Merge pull request
github_pr_merge() {
    local repo="${1:-}"
    local number="$2"
    local method="${3:-merge}"  # merge, squash, rebase
    local commit_title="${4:-}"

    if [[ -z "$number" ]]; then
        err "PR number required"
        return 1
    fi

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    # Build JSON payload
    local payload
    payload=$(jq -n --arg method "$method" '{merge_method: $method}')

    if [[ -n "$commit_title" ]]; then
        payload=$(echo "$payload" | jq --arg title "$commit_title" '.commit_title = $title')
    fi

    local response
    response=$(github_api PUT "/repos/$repo/pulls/$number/merge" "$payload")

    if [[ $? -eq 0 ]]; then
        success "Merged PR #$number"
    fi
}

# Close pull request (without merging)
github_pr_close() {
    local repo="${1:-}"
    local number="$2"

    if [[ -z "$number" ]]; then
        err "PR number required"
        return 1
    fi

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    local payload='{"state": "closed"}'
    local response
    response=$(github_api PATCH "/repos/$repo/pulls/$number" "$payload")

    if [[ $? -eq 0 ]]; then
        success "Closed PR #$number"
    fi
}

# List PR files
github_pr_files() {
    local repo="${1:-}"
    local number="$2"

    if [[ -z "$number" ]]; then
        err "PR number required"
        return 1
    fi

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    local response
    response=$(github_api GET "/repos/$repo/pulls/$number/files")

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo "$response" | jq -r '.[] | "\(.status)\t\(.filename)\t+\(.additions)/-\(.deletions)"' 2>/dev/null | column -t
}

# ============================================================================
# WORKFLOW OPERATIONS
# ============================================================================

# List workflow runs
github_workflows_list() {
    local repo="${1:-}"
    local per_page="${2:-10}"

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    local response
    response=$(github_api GET "/repos/$repo/actions/runs?per_page=$per_page")

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    ui_header "Workflow Runs for $repo"

    echo "$response" | jq -r '.workflow_runs[] | "[\(.conclusion // .status)] \(.name) #\(.run_number) (\(.head_branch)) - \(.created_at)"' 2>/dev/null
}

# Get workflow run details
github_workflow_view() {
    local repo="${1:-}"
    local run_id="$2"

    if [[ -z "$run_id" ]]; then
        err "Workflow run ID required"
        return 1
    fi

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    local response
    response=$(github_api GET "/repos/$repo/actions/runs/$run_id")

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo "$response" | jq -r '
        "Workflow: \(.name)",
        "Run: #\(.run_number)",
        "Status: \(.status)",
        "Conclusion: \(.conclusion // "in progress")",
        "Branch: \(.head_branch)",
        "Commit: \(.head_sha[:7])",
        "Started: \(.created_at)",
        "URL: \(.html_url)"
    ' 2>/dev/null
}

# Re-run workflow
github_workflow_rerun() {
    local repo="${1:-}"
    local run_id="$2"

    if [[ -z "$run_id" ]]; then
        err "Workflow run ID required"
        return 1
    fi

    if [[ -z "$repo" ]]; then
        repo=$(github_get_current_repo) || return 1
    fi

    local response
    response=$(github_api POST "/repos/$repo/actions/runs/$run_id/rerun" "{}")

    if [[ $? -eq 0 ]]; then
        success "Re-running workflow #$run_id"
    fi
}

# ============================================================================
# USER OPERATIONS
# ============================================================================

# Get authenticated user info
github_whoami() {
    local response
    response=$(github_api GET "/user")

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    ui_header "GitHub User"

    echo "$response" | jq -r '
        "Username: @\(.login)",
        "Name: \(.name // "Not set")",
        "Email: \(.email // "Not public")",
        "Bio: \(.bio // "No bio")",
        "Public repos: \(.public_repos)",
        "Followers: \(.followers)",
        "Following: \(.following)",
        "Created: \(.created_at)"
    ' 2>/dev/null
}

# ============================================================================
# INTERACTIVE MENUS
# ============================================================================

# Main GitHub menu
github_menu() {
    while true; do
        local choice
        choice=$(ui_choose "GitHub Operations" \
            "Status - Show git status" \
            "Clone - Clone a repository" \
            "Commit - Commit changes" \
            "Push - Push to remote" \
            "Pull - Pull from remote" \
            "Branches - Manage branches" \
            "Issues - Manage issues" \
            "PRs - Manage pull requests" \
            "Workflows - View CI/CD runs" \
            "Auth - Configure token" \
            "Back")

        case "$choice" in
            "Status"*)   github_status ;;
            "Clone"*)    github_clone_interactive ;;
            "Commit"*)   github_commit_interactive ;;
            "Push"*)     github_push ;;
            "Pull"*)     github_pull ;;
            "Branches"*) github_branches_menu ;;
            "Issues"*)   github_issues_menu ;;
            "PRs"*)      github_pr_menu ;;
            "Workflows"*) github_workflows_menu ;;
            "Auth"*)     github_auth_menu ;;
            "Back"|"")   break ;;
        esac
        echo ""
    done
}

# Clone interactive
github_clone_interactive() {
    local repo dest
    repo=$(ui_input "Repository (owner/repo)" "" "e.g., octocat/Hello-World")
    [[ -z "$repo" ]] && return

    dest=$(ui_input "Destination directory" "${repo##*/}" "Press Enter for default")

    github_clone "$repo" "$dest"
}

# Commit interactive
github_commit_interactive() {
    github_status
    echo ""

    local message
    message=$(ui_input "Commit message" "" "Enter commit message")
    [[ -z "$message" ]] && return

    if ui_confirm "Stage all changes?"; then
        github_add
    fi

    github_commit "$message"
}

# Branches menu
github_branches_menu() {
    while true; do
        local choice
        choice=$(ui_choose "Branch Operations" \
            "List - Show branches" \
            "Create - Create new branch" \
            "Switch - Switch branch" \
            "Delete - Delete branch" \
            "Back")

        case "$choice" in
            "List"*)
                github_branches true
                ;;
            "Create"*)
                local name base
                name=$(ui_input "Branch name" "" "Enter new branch name")
                [[ -z "$name" ]] && continue
                base=$(ui_input "Base branch" "" "Press Enter for current branch")
                github_branch_create "$name" "$base"
                ;;
            "Switch"*)
                local branches name
                branches=$(git branch --list | tr -d ' *')
                name=$(ui_filter "Select branch" $branches)
                [[ -n "$name" ]] && github_branch_switch "$name"
                ;;
            "Delete"*)
                local branches name
                branches=$(git branch --list | tr -d ' *' | grep -v "$(git branch --show-current)")
                name=$(ui_filter "Select branch to delete" $branches)
                [[ -n "$name" ]] && github_branch_delete "$name"
                ;;
            "Back"|"") break ;;
        esac
        echo ""
    done
}

# Issues menu
github_issues_menu() {
    while true; do
        local choice
        choice=$(ui_choose "Issue Operations" \
            "List - List issues" \
            "View - View issue details" \
            "Create - Create new issue" \
            "Close - Close an issue" \
            "Comment - Add comment" \
            "Back")

        case "$choice" in
            "List"*)
                github_issues_list
                ;;
            "View"*)
                local number
                number=$(ui_input "Issue number" "" "Enter issue number")
                [[ -n "$number" ]] && github_issue_view "" "$number"
                ;;
            "Create"*)
                local title body
                title=$(ui_input "Issue title" "" "Enter title")
                [[ -z "$title" ]] && continue
                body=$(ui_write "Issue description (Ctrl+D when done):")
                github_issue_create "" "$title" "$body"
                ;;
            "Close"*)
                local number
                number=$(ui_input "Issue number to close" "" "Enter issue number")
                [[ -n "$number" ]] && github_issue_close "" "$number"
                ;;
            "Comment"*)
                local number body
                number=$(ui_input "Issue number" "" "Enter issue number")
                [[ -z "$number" ]] && continue
                body=$(ui_write "Comment (Ctrl+D when done):")
                [[ -n "$body" ]] && github_issue_comment "" "$number" "$body"
                ;;
            "Back"|"") break ;;
        esac
        echo ""
    done
}

# PR menu
github_pr_menu() {
    while true; do
        local choice
        choice=$(ui_choose "Pull Request Operations" \
            "List - List pull requests" \
            "View - View PR details" \
            "Create - Create new PR" \
            "Files - View changed files" \
            "Merge - Merge a PR" \
            "Close - Close a PR" \
            "Back")

        case "$choice" in
            "List"*)
                github_pr_list
                ;;
            "View"*)
                local number
                number=$(ui_input "PR number" "" "Enter PR number")
                [[ -n "$number" ]] && github_pr_view "" "$number"
                ;;
            "Create"*)
                local title body base
                title=$(ui_input "PR title" "" "Enter title")
                [[ -z "$title" ]] && continue
                base=$(ui_input "Base branch" "main" "Target branch")
                body=$(ui_write "PR description (Ctrl+D when done):")
                github_pr_create "" "$title" "$body" "" "$base"
                ;;
            "Files"*)
                local number
                number=$(ui_input "PR number" "" "Enter PR number")
                [[ -n "$number" ]] && github_pr_files "" "$number"
                ;;
            "Merge"*)
                local number method
                number=$(ui_input "PR number to merge" "" "Enter PR number")
                [[ -z "$number" ]] && continue
                method=$(ui_choose "Merge method" "merge" "squash" "rebase")
                github_pr_merge "" "$number" "$method"
                ;;
            "Close"*)
                local number
                number=$(ui_input "PR number to close" "" "Enter PR number")
                [[ -n "$number" ]] && github_pr_close "" "$number"
                ;;
            "Back"|"") break ;;
        esac
        echo ""
    done
}

# Workflows menu
github_workflows_menu() {
    github_workflows_list
    echo ""

    local choice
    choice=$(ui_choose "Workflow Actions" \
        "View - View run details" \
        "Rerun - Re-run workflow" \
        "Back")

    case "$choice" in
        "View"*)
            local run_id
            run_id=$(ui_input "Run ID" "" "Enter workflow run ID")
            [[ -n "$run_id" ]] && github_workflow_view "" "$run_id"
            ;;
        "Rerun"*)
            local run_id
            run_id=$(ui_input "Run ID to re-run" "" "Enter workflow run ID")
            [[ -n "$run_id" ]] && github_workflow_rerun "" "$run_id"
            ;;
    esac
}

# Auth menu
github_auth_menu() {
    if has_github_token; then
        github_whoami
        echo ""
        if ui_confirm "Update GitHub token?"; then
            github_auth_setup
        fi
    else
        github_auth_setup
    fi
}

# Setup GitHub authentication
github_auth_setup() {
    echo ""
    echo "To authenticate with GitHub, you need a Personal Access Token (PAT)."
    echo ""
    echo "Create one at: https://github.com/settings/tokens/new"
    echo ""
    echo "Required scopes:"
    echo "  - repo (Full control of private repositories)"
    echo "  - workflow (Update GitHub Action workflows)"
    echo ""

    local token
    token=$(ui_password "Enter GitHub Personal Access Token")

    if [[ -z "$token" ]]; then
        warn "No token provided"
        return 1
    fi

    # Validate token by making a test API call
    export GITHUB_TOKEN="$token"
    local test_response
    test_response=$(github_api GET "/user" 2>/dev/null)

    if [[ $? -eq 0 ]]; then
        local username
        username=$(echo "$test_response" | jq -r '.login // "unknown"')
        success "Authenticated as @$username"
        set_github_token "$token"
    else
        err "Invalid token or authentication failed"
        unset GITHUB_TOKEN
        return 1
    fi
}

# ============================================================================
# EXPORTS
# ============================================================================

export AIWB_LIB_GITHUB_LOADED=1
