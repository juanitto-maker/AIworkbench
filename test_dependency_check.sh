#!/usr/bin/env bash
# Test script for dependency checking functionality

set -e

echo "Testing dependency checking function..."
echo "========================================"
echo

# Source the functions from aiwb.sh
have() { command -v "$1" >/dev/null 2>&1; }
err()  { printf "\033[1;31mEE\033[0m %s\n" "$*" >&2; }
warn() { printf "\033[1;33m!!\033[0m %s\n" "$*" >&2; }
msg()  { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
is_termux() { [[ "${PREFIX:-}" == *com.termux* ]] || [[ "${OSTYPE:-}" == "linux-android"* ]]; }

# Test 1: Check if all dependencies are present
echo "Test 1: Checking current system dependencies..."
echo "------------------------------------------------"

deps=(bash jq curl git fzf sed tar python3)
missing=()

for cmd in "${deps[@]}"; do
    if have "$cmd"; then
        printf "✓ %-10s found\n" "$cmd"
    else
        printf "✗ %-10s MISSING\n" "$cmd"
        missing+=("$cmd")
    fi
done

# Also check for python (alternative to python3)
if ! have python3 && have python; then
    echo "  Note: 'python' found as alternative to 'python3'"
fi

echo
if [[ ${#missing[@]} -eq 0 ]]; then
    msg "All required dependencies are installed!"
else
    warn "Missing dependencies: ${missing[*]}"
    echo
    echo "The dependency checking in aiwb.sh would prompt to install these."
fi

echo
echo "Test 2: Checking optional dependencies..."
echo "------------------------------------------"

opt_deps=(gum age)
for cmd in "${opt_deps[@]}"; do
    if have "$cmd"; then
        printf "✓ %-10s found\n" "$cmd"
    else
        printf "○ %-10s not installed (optional)\n" "$cmd"
    fi
done

echo
msg "Test complete!"
echo
echo "To test the full interactive dependency installation:"
echo "  1. Temporarily rename a dependency (e.g., mv /usr/bin/jq /usr/bin/jq.bak)"
echo "  2. Run: aiwb"
echo "  3. Follow the prompts to install missing dependencies"
echo "  4. Restore the dependency (e.g., mv /usr/bin/jq.bak /usr/bin/jq)"
