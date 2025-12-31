#!/data/data/com.termux/files/usr/bin/bash
# AIworkbench Simple Installation for Termux
# Works from scratch - no prior installation needed

set -e

echo "🚀 AIworkbench Installation for Termux"
echo "======================================"
echo ""

# 1. Install dependencies
echo "📦 Installing dependencies..."
pkg update -y
pkg install -y git curl jq gum age
echo "✓ Dependencies installed"
echo ""

# 2. NUCLEAR CLEANUP - Remove ALL old installations and cached files
echo "🧹 NUCLEAR CLEANUP - Removing all old installations..."
rm -rf ~/.aiwb/aiworkbench 2>/dev/null || true
rm -rf ~/.aiwb/.cache 2>/dev/null || true
rm -rf $PREFIX/bin/aiwb 2>/dev/null || true
rm -rf $PREFIX/bin/lib 2>/dev/null || true
rm -rf ~/.local/bin/aiwb 2>/dev/null || true
rm -rf ~/.local/bin/lib 2>/dev/null || true
rm -rf /data/data/com.termux/files/usr/bin/aiwb 2>/dev/null || true
rm -rf /data/data/com.termux/files/usr/bin/lib 2>/dev/null || true
# Clear any cached binaries
hash -r 2>/dev/null || true
echo "✓ Complete cleanup done"
echo ""

# 3. Create directories
echo "📁 Creating directories..."
mkdir -p ~/.aiwb
mkdir -p $PREFIX/bin
echo "✓ Directories created"
echo ""

# 4. Clone repo
echo "📥 Downloading AIworkbench..."
git clone --depth 1 https://github.com/juanitto-maker/AIworkbench.git ~/.aiwb/aiworkbench
echo "✓ Repository cloned"
echo ""

# 5. Install to PREFIX/bin (the correct location for Termux)
echo "⚙️  Installing..."
cd ~/.aiwb/aiworkbench

# Copy main script
cp -f aiwb $PREFIX/bin/aiwb
chmod +x $PREFIX/bin/aiwb

# Copy libraries
mkdir -p $PREFIX/bin/lib
cp -f lib/*.sh $PREFIX/bin/lib/
chmod +x $PREFIX/bin/lib/*.sh

echo "✓ Installation complete"
echo ""

# 6. Verify
echo "🔍 Verifying installation..."
AIWB_PATH=$(which aiwb 2>/dev/null || echo "")

if [ -z "$AIWB_PATH" ]; then
    echo "❌ ERROR: aiwb not found in PATH"
    echo ""
    echo "Add this to ~/.bashrc:"
    echo "  export PATH=\"\$PREFIX/bin:\$PATH\""
    exit 1
fi

echo "✓ aiwb found at: $AIWB_PATH"

# Check for latest code
if grep -q "Input text check" "$AIWB_PATH" 2>/dev/null; then
    echo "✓ Latest code verified"
else
    echo "⚠️  Warning: Code may be outdated"
fi
echo ""

# 7. Create default config
if [ ! -f ~/.aiwb/config.json ]; then
    echo "📝 Creating default config..."
    cat > ~/.aiwb/config.json <<'JSON'
{
  "version": "2.0.0",
  "workspace": "/storage/emulated/0/aiwb",
  "model_provider": "gemini",
  "model_name": "gemini-2.0-flash-exp"
}
JSON
    echo "✓ Config created"
    echo ""
fi

# 8. Success
echo "✅ Installation successful!"
echo ""
echo "📍 Installed at: $AIWB_PATH"
echo "🏠 Workspace: /storage/emulated/0/aiwb"
echo "⚙️  Config: ~/.aiwb/config.json"
echo ""
echo "🎯 Next steps:"
echo ""
echo "1. Set up API keys:"
echo "   aiwb keys"
echo ""
echo "2. Start chatting:"
echo "   aiwb"
echo ""
echo "3. Works from ANY directory:"
echo "   cd ~/SpellChecker"
echo "   aiwb"
echo ""
echo "📚 For help: aiwb help"
