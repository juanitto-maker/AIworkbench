#!/usr/bin/env bash
# security.sh - Security and API key management for AIWB

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[[ -z "${AIWB_LIB_CONFIG_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# ============================================================================
# KEY STORAGE
# ============================================================================

# Set API key securely
set_api_key() {
    local provider="$1"
    local key="$2"
    local env_file
    env_file="$(get_env_file)"

    # Validate key format (basic check)
    if [[ -z "$key" ]]; then
        err "API key cannot be empty"
        return 1
    fi

    # Determine environment variable name
    local var_name
    case "$provider" in
        gemini)  var_name="GEMINI_API_KEY" ;;
        claude)  var_name="ANTHROPIC_API_KEY" ;;
        openai)  var_name="OPENAI_API_KEY" ;;
        groq)    var_name="GROQ_API_KEY" ;;
        xai)     var_name="XAI_API_KEY" ;;
        github)  var_name="GITHUB_TOKEN" ;;
        *)
            err "Unknown provider: $provider"
            return 1
            ;;
    esac

    # Create or update env file
    ensure_dir "$(dirname "$env_file")"
    touch "$env_file"
    chmod 600 "$env_file"  # Owner read/write only

    # Update or append key
    if grep -q "^export ${var_name}=" "$env_file" 2>/dev/null; then
        # Update existing
        if is_macos; then
            sed -i '' "s|^export ${var_name}=.*|export ${var_name}=\"${key}\"|" "$env_file"
        else
            sed -i "s|^export ${var_name}=.*|export ${var_name}=\"${key}\"|" "$env_file"
        fi
    else
        # Append new
        echo "export ${var_name}=\"${key}\"" >> "$env_file"
    fi

    # Export to current session
    export "${var_name}=${key}"

    success "API key for $provider saved"

    # Enable encryption by default if age is available (SECURITY FIX)
    if have age; then
        local encrypt_choice="$(config_get security.encrypt_keys)"

        # Encryption is now MANDATORY by default for security
        if [[ "$encrypt_choice" == "false" ]]; then
            # User explicitly disabled encryption - show warning but respect choice
            warn "⚠️  SECURITY WARNING: API keys are stored in plaintext!"
            warn "   File: $env_file (chmod 600)"
            warn "   Enable encryption with: aiwb /keys --encrypt"
        else
            # First time or encryption enabled - encrypt automatically
            if [[ "$encrypt_choice" != "true" ]]; then
                echo ""
                echo "🔒 Encrypting API keys for security (using age encryption)..."
                echo "   You'll be prompted for a passphrase to protect your keys."
                config_set security.encrypt_keys true
            fi
            encrypt_keys
        fi
    else
        # age not installed - show strong warning
        echo ""
        warn "⚠️  SECURITY WARNING: 'age' encryption tool not installed!"
        warn "   Your API keys are stored in PLAINTEXT at: $env_file"
        warn ""
        warn "   Install 'age' for encrypted key storage:"
        if is_termux; then
            warn "     pkg install age"
        elif is_macos; then
            warn "     brew install age"
        else
            warn "     See: https://github.com/FiloSottile/age"
        fi
        warn ""
        warn "   After installing age, run: aiwb /keys --encrypt"
    fi
}

# Interactive key setup
setup_keys_interactive() {
    ui_header "API Key Setup"

    echo "AIWB supports multiple AI providers. Set up the ones you want to use."
    echo ""

    # Check which keys are already set
    local env_file
    env_file="$(get_env_file)"
    [[ -f "$env_file" ]] && source "$env_file"

    local choice

    while true; do
        local status_gemini="${GEMINI_API_KEY:+✓ Set}"
        local status_claude="${ANTHROPIC_API_KEY:+✓ Set}"
        local status_openai="${OPENAI_API_KEY:+✓ Set}"
        local status_groq="${GROQ_API_KEY:+✓ Set}"
        local status_xai="${XAI_API_KEY:+✓ Set}"
        local status_github="${GITHUB_TOKEN:+✓ Set}"

        choice=$(ui_choose "Which API key would you like to configure?" \
            "Gemini ${status_gemini:-○ Not set}" \
            "Claude ${status_claude:-○ Not set}" \
            "OpenAI ${status_openai:-○ Not set}" \
            "Groq ${status_groq:-○ Not set}" \
            "xAI (Grok) ${status_xai:-○ Not set}" \
            "GitHub ${status_github:-○ Not set}" \
            "Done")

        case "$choice" in
            "Gemini"*)
                echo ""
                echo "Get your Gemini API key from: https://makersuite.google.com/app/apikey"
                local key
                key=$(ui_password "Enter Gemini API key")
                [[ -n "$key" ]] && set_api_key "gemini" "$key"
                ;;
            "Claude"*)
                echo ""
                echo "Get your Claude API key from: https://console.anthropic.com/"
                local key
                key=$(ui_password "Enter Claude API key")
                [[ -n "$key" ]] && set_api_key "claude" "$key"
                ;;
            "OpenAI"*)
                echo ""
                echo "Get your OpenAI API key from: https://platform.openai.com/api-keys"
                local key
                key=$(ui_password "Enter OpenAI API key")
                [[ -n "$key" ]] && set_api_key "openai" "$key"
                ;;
            "Groq"*)
                echo ""
                echo "Get your Groq API key from: https://console.groq.com/keys"
                echo "Groq offers FREE ultra-fast inference with Llama 3.1 70B!"
                local key
                key=$(ui_password "Enter Groq API key")
                [[ -n "$key" ]] && set_api_key "groq" "$key"
                ;;
            "xAI"*)
                echo ""
                echo "Get your xAI API key from: https://console.x.ai/"
                echo "xAI Grok offers \$25 FREE monthly credits during beta!"
                local key
                key=$(ui_password "Enter xAI API key")
                [[ -n "$key" ]] && set_api_key "xai" "$key"
                ;;
            "GitHub"*)
                echo ""
                echo "Get your GitHub Personal Access Token from:"
                echo "  https://github.com/settings/tokens/new"
                echo ""
                echo "Required scopes: repo, workflow"
                local key
                key=$(ui_password "Enter GitHub Personal Access Token")
                [[ -n "$key" ]] && set_api_key "github" "$key"
                ;;
            "Done"|"Skip"|"")
                break
                ;;
        esac
        echo ""
    done

    # Offer encryption
    if have age && ! [[ "$(config_get security.encrypt_keys)" == "true" ]]; then
        echo ""
        if ui_confirm "Encrypt your API keys for extra security?"; then
            config_set security.encrypt_keys true
            encrypt_keys
        fi
    fi
}

# ============================================================================
# KEY ENCRYPTION (using age)
# ============================================================================

# Encrypt keys file
encrypt_keys() {
    if ! have age; then
        warn "age not installed. Encryption skipped."
        return 1
    fi

    local env_file keys_file passphrase
    env_file="$(get_env_file)"
    keys_file="$(get_keys_file)"

    [[ ! -f "$env_file" ]] && { warn "No keys to encrypt"; return 1; }

    echo "Encrypting API keys..."
    passphrase=$(ui_password "Enter encryption passphrase")

    if [[ -z "$passphrase" ]]; then
        warn "Empty passphrase. Encryption cancelled."
        return 1
    fi

    # Encrypt using age with passphrase
    age -p -o "$keys_file" "$env_file" <<< "$passphrase" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        # Remove unencrypted file
        shred -u "$env_file" 2>/dev/null || rm -f "$env_file"
        success "Keys encrypted successfully"
        config_set security.encrypt_keys true
    else
        err "Encryption failed"
        return 1
    fi
}

# Decrypt keys file
decrypt_keys() {
    if ! have age; then
        warn "age not installed. Cannot decrypt keys."
        return 1
    fi

    local env_file keys_file passphrase
    env_file="$(get_env_file)"
    keys_file="$(get_keys_file)"

    [[ ! -f "$keys_file" ]] && { err "No encrypted keys found"; return 1; }

    passphrase=$(ui_password "Enter decryption passphrase")

    if [[ -z "$passphrase" ]]; then
        warn "Empty passphrase. Decryption cancelled."
        return 1
    fi

    # Decrypt
    age -d "$keys_file" <<< "$passphrase" > "$env_file" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        chmod 600 "$env_file"
        success "Keys decrypted successfully"
        source "$env_file"
    else
        err "Decryption failed. Wrong passphrase?"
        rm -f "$env_file"
        return 1
    fi
}

# Rotate encryption passphrase (re-encrypt with new password)
rotate_keys() {
    if ! have age; then
        err "age not installed. Cannot rotate keys."
        echo "Install age from: https://github.com/FiloSottile/age"
        return 1
    fi

    local env_file keys_file
    env_file="$(get_env_file)"
    keys_file="$(get_keys_file)"

    # Check if keys are encrypted
    if [[ ! -f "$keys_file" ]]; then
        warn "No encrypted keys found. Keys might be in plaintext."
        if [[ -f "$env_file" ]]; then
            echo "Would you like to encrypt them now?"
            encrypt_keys
        else
            err "No keys found to rotate"
            return 1
        fi
        return $?
    fi

    msg "Rotating encryption passphrase..."
    echo ""

    # Decrypt with old passphrase
    local old_passphrase new_passphrase
    old_passphrase=$(ui_password "Enter CURRENT passphrase")
    if [[ -z "$old_passphrase" ]]; then
        warn "Empty passphrase. Rotation cancelled."
        return 1
    fi

    # Decrypt to temp file
    local temp_env="/tmp/aiwb_rotate_$$"
    age -d "$keys_file" <<< "$old_passphrase" > "$temp_env" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        err "Decryption failed. Wrong passphrase?"
        rm -f "$temp_env"
        return 1
    fi

    # Get new passphrase
    echo ""
    new_passphrase=$(ui_password "Enter NEW passphrase")
    if [[ -z "$new_passphrase" ]]; then
        warn "Empty passphrase. Rotation cancelled."
        rm -f "$temp_env"
        return 1
    fi

    # Confirm new passphrase
    local confirm_passphrase
    confirm_passphrase=$(ui_password "Confirm NEW passphrase")
    if [[ "$new_passphrase" != "$confirm_passphrase" ]]; then
        err "Passphrases don't match. Rotation cancelled."
        rm -f "$temp_env"
        return 1
    fi

    # Re-encrypt with new passphrase
    age -p -o "$keys_file.new" "$temp_env" <<< "$new_passphrase" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        # Replace old encrypted file
        mv "$keys_file.new" "$keys_file"
        # Clean up temp file securely
        shred -u "$temp_env" 2>/dev/null || rm -f "$temp_env"
        success "Encryption passphrase rotated successfully"
        return 0
    else
        err "Re-encryption failed"
        rm -f "$temp_env" "$keys_file.new"
        return 1
    fi
}

# Load keys (decrypt if needed)
load_keys() {
    local env_file keys_file
    env_file="$(get_env_file)"
    keys_file="$(get_keys_file)"

    # If plaintext exists, use it
    if [[ -f "$env_file" ]]; then
        source "$env_file"
        return 0
    fi

    # If encrypted exists, decrypt it
    if [[ -f "$keys_file" ]]; then
        decrypt_keys
        return $?
    fi

    # No keys found
    return 1
}

# ============================================================================
# KEY VALIDATION
# ============================================================================

# Check if key looks valid (basic format check)
validate_key_format() {
    local provider="$1"
    local key="$2"

    case "$provider" in
        gemini)
            # Gemini keys are typically 39 chars
            [[ ${#key} -ge 30 ]] && [[ "$key" =~ ^[A-Za-z0-9_-]+$ ]]
            ;;
        claude)
            # Claude keys start with sk-ant-
            [[ "$key" =~ ^sk-ant- ]]
            ;;
        openai)
            # OpenAI keys start with sk-
            [[ "$key" =~ ^sk- ]]
            ;;
        groq)
            # Groq keys start with gsk_
            [[ "$key" =~ ^gsk_ ]]
            ;;
        xai)
            # xAI keys start with xai-
            [[ "$key" =~ ^xai- ]]
            ;;
        github)
            # GitHub PAT tokens start with ghp_ (classic) or github_pat_ (fine-grained)
            [[ "$key" =~ ^ghp_ ]] || [[ "$key" =~ ^github_pat_ ]] || [[ ${#key} -ge 30 ]]
            ;;
        *)
            return 1
            ;;
    esac
}

# Test API key by making a simple call
test_api_key() {
    local provider="$1"

    msg "Testing $provider API key..."

    local test_prompt="Say 'test successful'"
    local response

    case "$provider" in
        gemini)
            response=$(call_gemini "$test_prompt" "gemini-1.5-flash" 10 2>&1)
            ;;
        claude)
            response=$(call_claude "$test_prompt" "claude-3-haiku-20240307" 10 2>&1)
            ;;
        openai)
            response=$(call_openai "$test_prompt" "gpt-4o-mini" 10 2>&1)
            ;;
        groq)
            response=$(call_groq "$test_prompt" "llama-3.1-8b-instant" 10 2>&1)
            ;;
        xai)
            response=$(call_xai "$test_prompt" "grok-beta" 10 2>&1)
            ;;
        *)
            err "Unknown provider: $provider"
            return 1
            ;;
    esac

    if [[ -n "$response" ]] && ! echo "$response" | grep -qi "error"; then
        success "$provider API key is valid and working"
        return 0
    else
        err "$provider API key test failed"
        debug "Response: $response"
        return 1
    fi
}

# ============================================================================
# SECURITY AUDIT
# ============================================================================

# Validate and fix .gitignore for sensitive files
validate_gitignore() {
    if ! have git || ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 0  # Not a git repo
    fi

    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    [[ -z "$repo_root" ]] && return 0

    local gitignore="$repo_root/.gitignore"
    local sensitive_files=(
        ".aiwb.env"
        ".keys.age"
        "*.aiwb.env"
        "*.keys.age"
        ".aiwb/.aiwb.env"
        ".aiwb/.keys.age"
    )

    local missing_entries=()
    local needs_update=false

    # Check if .gitignore exists
    if [[ ! -f "$gitignore" ]]; then
        needs_update=true
        missing_entries=("${sensitive_files[@]}")
    else
        # Check each sensitive file pattern
        for pattern in "${sensitive_files[@]}"; do
            if ! grep -qF "$pattern" "$gitignore"; then
                missing_entries+=("$pattern")
                needs_update=true
            fi
        done
    fi

    if $needs_update; then
        warn ".gitignore missing security-sensitive file patterns"
        echo "  Missing patterns: ${missing_entries[*]}"
        echo ""

        if ui_confirm "Add missing patterns to .gitignore?" "yes"; then
            # Create or append to .gitignore
            {
                echo ""
                echo "# AIWB security files (auto-added by security audit)"
                for pattern in "${missing_entries[@]}"; do
                    echo "$pattern"
                done
            } >> "$gitignore"
            success "Updated .gitignore with security patterns"

            # Check if any of these files are already tracked
            for pattern in "${sensitive_files[@]}"; do
                if git ls-files --error-unmatch "$pattern" &>/dev/null; then
                    warn "File '$pattern' is already tracked in git!"
                    echo "  Run: git rm --cached $pattern"
                fi
            done
        else
            warn "Skipped .gitignore update. Your API keys may be at risk!"
        fi
    else
        debug ".gitignore includes all security patterns"
    fi
}

# Check for exposed keys in git
audit_git_exposure() {
    if ! have git || ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 0  # Not a git repo
    fi

    warn "Checking for exposed API keys in git history..."

    # Actual key patterns with specific lengths (more precise)
    local key_patterns=(
        "sk-ant-api03[_A-Za-z0-9-]{95,}"     # Anthropic API keys (actual format)
        "sk-proj-[A-Za-z0-9]{48,}"            # OpenAI project keys
        "sk-[A-Za-z0-9]{48,}"                 # OpenAI standard keys (48+ chars)
        "gsk_[A-Za-z0-9]{52,}"                # Groq keys (52+ chars)
        "xai-[A-Za-z0-9]{48,}"                # xAI keys (48+ chars)
        "ghp_[A-Za-z0-9]{36,}"                # GitHub PAT classic (36+ chars)
        "github_pat_[A-Za-z0-9_]{82,}"        # GitHub PAT fine-grained (82+ chars)
    )

    local found=false
    local temp_results="/tmp/aiwb_git_audit_$$"

    for pattern in "${key_patterns[@]}"; do
        # Search git history for the pattern
        git log -p --all 2>/dev/null | grep -E "$pattern" > "$temp_results" 2>/dev/null || true

        # Filter out false positives
        if [[ -s "$temp_results" ]]; then
            # Remove lines that are clearly not real keys:
            # - Pattern definitions (contain regex chars: [, ], {, }, +, etc.)
            # - Comments (start with # or //)
            # - Variable declarations without actual values
            # - Documentation examples with placeholders
            local real_keys=$(grep -v -E '(\[|\{|\}|\+|\*|//|^[[:space:]]*#|your.?key|example|test.?key|placeholder|xxx|\.\.\.|\$\{|\$\(|Pattern:|".*".*regex)' "$temp_results" | \
                             grep -v -E '(=.*["'\''].*["'\''].*=|^\+.*\[[A-Za-z0-9_-]+\]|validate_key_format|check.*key.*format)' || true)

            if [[ -n "$real_keys" ]]; then
                found=true
                err "⚠ Potential API key found in git history!"
                echo "  Pattern: $pattern"
                echo "  Matches:"
                echo "$real_keys" | head -3 | sed 's/^/    /'
                if [[ $(echo "$real_keys" | wc -l) -gt 3 ]]; then
                    echo "    ... and $(($(echo "$real_keys" | wc -l) - 3)) more"
                fi
                echo ""
            fi
        fi
    done

    rm -f "$temp_results"

    if $found; then
        echo ""
        ui_info_box "SECURITY WARNING: API keys detected in git history!

To fix:
  1. Rotate your API keys immediately
  2. Remove keys from git history:
     git filter-branch --force --index-filter \
       'git rm --cached --ignore-unmatch .aiwb.env' --prune-empty --tag-name-filter cat -- --all
  3. Force push: git push origin --force --all" "error"
        echo ""
    else
        success "No API keys found in git history"
    fi
}

# Full security audit
security_audit() {
    ui_header "Security Audit"

    local env_file
    env_file="$(get_env_file)"

    # Check file permissions
    if [[ -f "$env_file" ]]; then
        local perms
        perms=$(stat -c %a "$env_file" 2>/dev/null || stat -f %A "$env_file" 2>/dev/null)
        if [[ "$perms" != "600" ]]; then
            warn "⚠ Environment file has insecure permissions: $perms"
            echo "  Fixing permissions..."
            chmod 600 "$env_file"
            success "  Fixed: $env_file now has 600 permissions"
        else
            success "✓ Environment file has correct permissions (600)"
        fi
    fi

    # Check if keys are encrypted
    if [[ "$(config_get security.encrypt_keys)" == "true" ]]; then
        success "✓ Key encryption enabled"
    else
        warn "○ Key encryption not enabled"
        if have age; then
            echo "  Enable with: aiwb /keys --encrypt"
        else
            echo "  Install 'age' to enable encryption"
        fi
    fi

    # Validate .gitignore
    validate_gitignore
    echo ""

    # Check git exposure
    audit_git_exposure

    echo ""
    success "Security audit complete"
}

# ============================================================================
# EXPORTS
# ============================================================================

export AIWB_LIB_SECURITY_LOADED=1
