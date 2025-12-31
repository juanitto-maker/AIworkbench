#!/data/data/com.termux/files/usr/bin/bash
# Complete AIWB Clean Installation for Termux
# This script completely removes all AIWB installations and does a fresh install

set -e

echo "🧹 AIWB Complete Clean Install for Termux"
echo "=========================================="
echo ""

# Step 1: Stop any running aiwb processes
echo "1️⃣  Stopping any running aiwb processes..."
pkill -f aiwb 2>/dev/null || true
echo "   ✓ Done"
echo ""

# Step 2: Remove all aiwb binaries
echo "2️⃣  Removing all aiwb binaries..."
rm -f ~/.local/bin/aiwb 2>/dev/null || true
rm -rf ~/.local/bin/lib 2>/dev/null || true
rm -f $PREFIX/bin/aiwb 2>/dev/null || true
rm -rf $PREFIX/bin/lib 2>/dev/null || true
rm -f /data/data/com.termux/files/usr/bin/aiwb 2>/dev/null || true
rm -rf /data/data/com.termux/files/usr/bin/lib 2>/dev/null || true
echo "   ✓ All binaries removed"
echo ""

# Step 3: Remove workspace and config (optional - keeps your API keys)
echo "3️⃣  Removing workspace and repo..."
read -p "   Remove ~/.aiwb directory? (keeps workspace, removes repo) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Backup config and keys if they exist
    if [ -f ~/.aiwb/config.json ]; then
        cp ~/.aiwb/config.json /tmp/aiwb-config-backup.json
        echo "   ✓ Backed up config to /tmp/aiwb-config-backup.json"
    fi
    if [ -f ~/.aiwb/keys.env ]; then
        cp ~/.aiwb/keys.env /tmp/aiwb-keys-backup.env
        echo "   ✓ Backed up keys to /tmp/aiwb-keys-backup.env"
    fi

    rm -rf ~/.aiwb
    echo "   ✓ Removed ~/.aiwb"
else
    # Just remove the repo
    rm -rf ~/.aiwb/aiworkbench 2>/dev/null || true
    echo "   ✓ Kept ~/.aiwb, removed repo only"
fi
echo ""

# Step 4: Install dependencies
echo "4️⃣  Installing dependencies..."
pkg update -y
pkg install -y git curl jq gum age termux-api
echo "   ✓ Dependencies installed"
echo ""

# Step 5: Fresh install
echo "5️⃣  Installing AIWB..."
curl -fsSL https://raw.githubusercontent.com/juanitto-maker/AIworkbench/main/install.sh | bash
echo ""

# Step 6: Restore backups if they exist
if [ -f /tmp/aiwb-config-backup.json ]; then
    cp /tmp/aiwb-config-backup.json ~/.aiwb/config.json
    echo "   ✓ Restored config from backup"
fi
if [ -f /tmp/aiwb-keys-backup.env ]; then
    cp /tmp/aiwb-keys-backup.env ~/.aiwb/keys.env
    echo "   ✓ Restored keys from backup"
fi
echo ""

# Step 7: Verify installation
echo "6️⃣  Verifying installation..."
if command -v aiwb >/dev/null 2>&1; then
    AIWB_LOCATION=$(which aiwb)
    echo "   ✓ aiwb found at: $AIWB_LOCATION"

    # Check if it has the latest code
    if grep -q "Input text check" "$AIWB_LOCATION"; then
        echo "   ✓ Latest code verified"
    else
        echo "   ⚠️  Warning: May not have latest code"
    fi
else
    echo "   ✗ aiwb command not found!"
    echo "   Please add to PATH: export PATH=\"\$PREFIX/bin:\$PATH\""
fi
echo ""

# Step 8: Success message
echo "✅ Installation complete!"
echo ""
echo "📍 Installation location: $(which aiwb 2>/dev/null || echo 'Not in PATH')"
echo "🏠 Workspace: ~/.aiwb/workspace"
echo "⚙️  Config: ~/.aiwb/config.json"
echo ""
echo "Try it now:"
echo "  aiwb"
echo ""
echo "Or from any directory:"
echo "  cd ~/SpellChecker"
echo "  aiwb"
