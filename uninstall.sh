#!/usr/bin/env bash
# uninstall.sh — Uninstaller for AIworkbench
# Removes all installed components

set -eo pipefail

# Colors
msg()  { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m!! \033[0m%s\n" "$*" >&2; }
err()  { printf "\033[1;31mEE \033[0m%s\n" "$*" >&2; }

# Paths (same as install.sh)
AIWB_HOME="${HOME}/.aiwb"
DEST_BIN_DEFAULT="${HOME}/.local/bin"
DEST_BIN_FALLBACK="${HOME}/bin"

echo "╔════════════════════════════════════════╗"
echo "║     AIworkbench Uninstaller            ║"
echo "╚════════════════════════════════════════╝"
echo

# Confirm
read -p "This will remove AIworkbench and all its data. Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    msg "Uninstall cancelled."
    exit 0
fi

# 1. Remove binaries from ~/.local/bin or ~/bin
msg "Removing binaries..."
for bin_dir in "$DEST_BIN_DEFAULT" "$DEST_BIN_FALLBACK"; do
    if [[ -f "${bin_dir}/aiwb" ]]; then
        rm -f "${bin_dir}/aiwb"
        msg "Removed ${bin_dir}/aiwb"
    fi
    # Remove lib directory
    if [[ -d "${bin_dir}/lib" ]]; then
        rm -rf "${bin_dir}/lib"
        msg "Removed ${bin_dir}/lib/"
    fi
    # Remove any bin-edit scripts
    for script in "${bin_dir}/"*.sh; do
        if [[ -f "$script" ]] && grep -q "AIworkbench\|aiwb" "$script" 2>/dev/null; then
            rm -f "$script"
            msg "Removed $script"
        fi
    done
done

# 2. Remove AIWB home directory
if [[ -d "$AIWB_HOME" ]]; then
    msg "Removing AIWB home directory: ${AIWB_HOME}"
    rm -rf "$AIWB_HOME"
    msg "Removed ${AIWB_HOME}"
else
    warn "AIWB home directory not found: ${AIWB_HOME}"
fi

# 3. Clean PATH export from shell rc files (optional)
clean_rc() {
    local rc_file="$1"
    if [[ -f "$rc_file" ]]; then
        if grep -q "AIworkbench installer" "$rc_file"; then
            msg "Cleaning PATH export from ${rc_file}"
            # Remove the AIworkbench PATH lines
            sed -i.bak '/# AIworkbench installer/d' "$rc_file"
            sed -i.bak '/export PATH=.*\.local\/bin/d' "$rc_file"
            rm -f "${rc_file}.bak"
        fi
    fi
}

clean_rc "${HOME}/.bashrc"
clean_rc "${HOME}/.zshrc"

echo
msg "╔════════════════════════════════════════╗"
msg "║     Uninstall complete!                ║"
msg "╚════════════════════════════════════════╝"
echo
echo "Removed:"
echo "  • AIWB home directory (~/.aiwb/)"
echo "  • Binary files (~/.local/bin/aiwb)"
echo "  • Libraries (~/.local/bin/lib/)"
echo "  • PATH exports from shell rc files"
echo
echo "Note: Dependencies (jq, curl, fzf, gum, etc.) were NOT removed."
echo "Restart your terminal or run: source ~/.bashrc"
