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

# Step 2: Backup config and keys
echo "2️⃣  Backing up config and keys..."
AIWB_TMP="${TMPDIR:-/tmp}"
mkdir -p "$AIWB_TMP" 2>/dev/null || true
if [ -f ~/.aiwb/config.json ]; then
    cp ~/.aiwb/config.json "$AIWB_TMP/aiwb-config-backup.json"
    echo "   ✓ Backed up config to $AIWB_TMP/aiwb-config-backup.json"
fi
if [ -f ~/.aiwb/keys.env ]; then
    cp ~/.aiwb/keys.env "$AIWB_TMP/aiwb-keys-backup.env"
    echo "   ✓ Backed up keys to $AIWB_TMP/aiwb-keys-backup.env"
fi
echo "   ✓ Backup complete"
echo ""

# Step 3: Remove all aiwb binaries
echo "3️⃣  Removing all aiwb binaries..."
rm -f ~/.local/bin/aiwb 2>/dev/null || true
rm -rf ~/.local/bin/lib 2>/dev/null || true
rm -f $PREFIX/bin/aiwb 2>/dev/null || true
rm -rf $PREFIX/bin/lib 2>/dev/null || true
rm -f /data/data/com.termux/files/usr/bin/aiwb 2>/dev/null || true
rm -rf /data/data/com.termux/files/usr/bin/lib 2>/dev/null || true
echo "   ✓ All binaries removed"
echo ""

# Step 4: Remove old repo (keep workspace)
echo "4️⃣  Removing old repository..."
rm -rf ~/.aiwb/aiworkbench 2>/dev/null || true
echo "   ✓ Old repo removed (workspace preserved)"
echo ""

# Step 5: Install dependencies
echo "5️⃣  Installing dependencies..."
pkg update -y >/dev/null 2>&1 || true
pkg install -y git curl jq gum age >/dev/null 2>&1
echo "   ✓ Dependencies installed"
echo ""

# Step 6: Fresh install
echo "6️⃣  Installing AIWB from GitHub..."
curl -fsSL https://raw.githubusercontent.com/juanitto-maker/AIworkbench/main/install.sh | bash
echo ""

# Step 7: Restore backups if they exist
echo "7️⃣  Restoring config and keys..."
if [ -f "$AIWB_TMP/aiwb-config-backup.json" ]; then
    cp "$AIWB_TMP/aiwb-config-backup.json" ~/.aiwb/config.json
    echo "   ✓ Restored config from backup"
fi
if [ -f "$AIWB_TMP/aiwb-keys-backup.env" ]; then
    cp "$AIWB_TMP/aiwb-keys-backup.env" ~/.aiwb/keys.env
    echo "   ✓ Restored keys from backup"
fi
echo ""

# Step 8: Verify installation
echo "8️⃣  Verifying installation..."
if command -v aiwb >/dev/null 2>&1; then
    AIWB_LOCATION=$(which aiwb)
    echo "   ✓ aiwb found at: $AIWB_LOCATION"

    # Check if it has the latest code
    if grep -q "Input text check" "$AIWB_LOCATION" 2>/dev/null; then
        echo "   ✓ Latest code verified"
    else
        echo "   ⚠️  Warning: May not have latest code"
    fi
else
    echo "   ✗ aiwb command not found!"
    echo "   Run: hash -r"
    echo "   Then: aiwb"
fi
echo ""

# Step 9: Refresh shell hash table
hash -r 2>/dev/null || true

# Step 10: Success message
echo "✅ Installation complete!"
echo ""
echo "📍 Installation location: $(which aiwb 2>/dev/null || echo 'Run: hash -r, then try again')"
echo "🏠 Workspace: ~/.aiwb/workspace"
echo "⚙️  Config: ~/.aiwb/config.json"
echo ""
echo "🔄 If 'aiwb' command not found, run:"
echo "   hash -r"
echo "   source ~/.bashrc"
echo ""
echo "Try it now:"
echo "  aiwb"
echo ""
echo "Or from any directory:"
echo "  cd ~/SpellChecker"
echo "  aiwb"
