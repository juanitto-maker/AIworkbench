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

    success "API key for $provider saved securely"

    # Check if encryption is enabled
    if [[ "$(config_get security.encrypt_keys)" == "true" ]]; then
        encrypt_keys
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

    local providers=("Gemini (Google)" "Claude (Anthropic)" "OpenAI" "Skip")
    local choice

    while true; do
        local status_gemini="${GEMINI_API_KEY:+✓ Set}"
        local status_claude="${ANTHROPIC_API_KEY:+✓ Set}"
        local status_openai="${OPENAI_API_KEY:+✓ Set}"

        choice=$(ui_choose "Which API key would you like to configure?" \
            "Gemini ${status_gemini:-○ Not set}" \
            "Claude ${status_claude:-○ Not set}" \
            "OpenAI ${status_openai:-○ Not set}" \
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
            response=$(call_claude "$test_prompt" "claude-3-5-haiku-latest" 10 2>&1)
            ;;
        openai)
            response=$(call_openai "$test_prompt" "gpt-4o-mini" 10 2>&1)
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

# Check for exposed keys in git
audit_git_exposure() {
    if ! have git || ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 0  # Not a git repo
    fi

    warn "Checking for exposed API keys in git history..."

    local patterns=(
        "sk-ant-[A-Za-z0-9_-]{30,}"
        "sk-[A-Za-z0-9]{32,}"
        "GEMINI_API_KEY.*=.*[A-Za-z0-9_-]{30,}"
        "ANTHROPIC_API_KEY.*=.*sk-ant-"
        "OPENAI_API_KEY.*=.*sk-"
    )

    local found=false
    for pattern in "${patterns[@]}"; do
        if git log -p -S "$pattern" --all 2>/dev/null | grep -qE "$pattern"; then
            found=true
            err "⚠ Potential API key found in git history!"
            echo "  Pattern: $pattern"
        fi
    done

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

    # Check git exposure
    audit_git_exposure

    echo ""
    success "Security audit complete"
}

# ============================================================================
# EXPORTS
# ============================================================================

export AIWB_LIB_SECURITY_LOADED=1
