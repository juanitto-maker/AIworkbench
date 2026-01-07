#!/data/data/com.termux/files/usr/bin/bash
# Run this script in Termux to debug aiwb issues

echo "=================================="
echo "AIWB TERMUX DEBUG SCRIPT"
echo "=================================="
echo

echo "1. Checking installed aiwb..."
if which aiwb >/dev/null 2>&1; then
    echo "  ✓ aiwb found at: $(which aiwb)"
else
    echo "  ✗ aiwb NOT in PATH"
    exit 1
fi
echo

echo "2. Checking aiwb file..."
AIWB_PATH="$(which aiwb)"
echo "  File size: $(wc -c < "$AIWB_PATH") bytes"
echo "  First line (shebang): $(head -1 "$AIWB_PATH")"
echo "  Set command: $(grep "^set -" "$AIWB_PATH" | head -1)"
echo

echo "3. Checking lib directory..."
LIB_DIR="$(dirname "$AIWB_PATH")/lib"
if [ -d "$LIB_DIR" ]; then
    echo "  ✓ lib directory exists: $LIB_DIR"
    echo "  Files: $(ls "$LIB_DIR" | wc -l)"
else
    echo "  ✗ lib directory NOT found"
fi
echo

echo "4. Running aiwb with debug trace..."
echo "  (This will show WHERE it stops)"
echo
bash -x "$AIWB_PATH" 2>&1 | tail -50 &
AIWB_PID=$!
sleep 2
if kill -0 $AIWB_PID 2>/dev/null; then
    echo "  ✓ aiwb is running (waiting for input)"
    kill $AIWB_PID 2>/dev/null
else
    echo "  ✗ aiwb exited immediately"
fi
echo

echo "5. Testing with --version..."
timeout 2 "$AIWB_PATH" --version 2>&1 || echo "  ✗ --version failed"
echo

echo "=================================="
echo "DEBUG COMPLETE"
echo "=================================="
