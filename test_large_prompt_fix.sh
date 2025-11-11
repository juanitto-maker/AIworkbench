#!/usr/bin/env bash
# Test script to verify large prompt handling fix

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Testing Large Prompt Fix ===" echo ""

# Load API keys
if [[ -f "$HOME/.aiwb/.aiwb.env" ]]; then
    source "$HOME/.aiwb/.aiwb.env"
fi

# Test with progressively larger prompts
echo "Testing with MEDIUM prompt (50000 chars)..."
MEDIUM_PROMPT=$(printf 'A%.0s' {1..50000})
if "$SCRIPT_DIR/aiwb" --provider gemini --model 2.0-flash-exp quick "Count the letters in this text: $MEDIUM_PROMPT" >/dev/null 2>&1; then
    echo "✓ MEDIUM prompt (50000 chars) - PASSED"
else
    echo "✗ MEDIUM prompt (50000 chars) - FAILED"
    exit 1
fi

echo ""
echo "Testing with LARGE prompt (200000 chars)..."
LARGE_PROMPT=$(printf 'B%.0s' {1..200000})
if "$SCRIPT_DIR/aiwb" --provider gemini --model 2.0-flash-exp quick "Count the letters in this text: $LARGE_PROMPT" >/dev/null 2>&1; then
    echo "✓ LARGE prompt (200000 chars) - PASSED"
else
    echo "✗ LARGE prompt (200000 chars) - FAILED"
    exit 1
fi

echo ""
echo "Testing with EXTRA LARGE prompt (400000 chars)..."
EXTRA_LARGE_PROMPT=$(printf 'C%.0s' {1..400000})
if "$SCRIPT_DIR/aiwb" --provider gemini --model 2.0-flash-exp quick "Count the letters in this text: $EXTRA_LARGE_PROMPT" >/dev/null 2>&1; then
    echo "✓ EXTRA LARGE prompt (400000 chars) - PASSED"
else
    echo "✗ EXTRA LARGE prompt (400000 chars) - FAILED"
    exit 1
fi

echo ""
echo "=== All large prompt tests PASSED! ==="
