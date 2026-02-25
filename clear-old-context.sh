#!/usr/bin/env bash
# Clear old AIWB session context that contains false positive security warnings

echo "🧹 Clearing old AIWB session context..."

# Find and remove context state files
WORKSPACE="${HOME}/.aiwb/workspace"
CONTEXT_FILE="${WORKSPACE}/.context_state"
HISTORY_FILE="${WORKSPACE}/.conversation_history.log"

if [[ -f "$CONTEXT_FILE" ]]; then
    echo "  Removing: $CONTEXT_FILE"
    rm -f "$CONTEXT_FILE"
fi

if [[ -f "$HISTORY_FILE" ]]; then
    echo "  Removing: $HISTORY_FILE"
    rm -f "$HISTORY_FILE"
fi

# Also clear any temp context files (respect $TMPDIR for Termux)
find "${TMPDIR:-/tmp}" -name "aiwb_git_audit_*" -delete 2>/dev/null

echo "✅ Old context cleared!"
echo ""
echo "Now when you run 'aiwb', you won't see the old security warning."
echo "The security check has been disabled on startup - you can run it manually with: aiwb security audit"
