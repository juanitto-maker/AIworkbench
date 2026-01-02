#!/usr/bin/env bash
# Test script for preflight cost feature
# This demonstrates how to test preflight cost estimation

set -e

echo "========================================="
echo "Testing Preflight Cost Feature"
echo "========================================="
echo ""

# Test 1: Simple text-only prompt (small cost)
echo "TEST 1: Small text prompt (should show low cost)"
echo "---------------------------------------"
echo "Steps to test manually:"
echo "1. Run: ./aiwb"
echo "2. Enter: /make"
echo "3. Enter: prompt Write a hello world function in Python"
echo "4. Enter: run"
echo ""
echo "Expected output:"
echo "  - Cost Estimation header"
echo "  - Generation section showing:"
echo "    - Provider and model"
echo "    - Input tokens (should be ~50-100)"
echo "    - Output tokens estimate (~100-200)"
echo "    - Estimated cost (should be < \$0.01)"
echo "  - 'Proceed with execution?' prompt"
echo ""

# Test 2: Large prompt with context (higher cost)
echo "TEST 2: Large prompt with file context (should show higher cost)"
echo "---------------------------------------"
echo "Steps to test manually:"
echo "1. Run: ./aiwb"
echo "2. Enter: /make"
echo "3. Enter: prompt Analyze this entire codebase and create documentation"
echo "4. Enter: uploads lib/*.sh"
echo "5. Enter: run"
echo ""
echo "Expected output:"
echo "  - Cost Estimation header"
echo "  - Generation section showing:"
echo "    - Input tokens (should be 10,000+)"
echo "    - Output tokens estimate (should be 20,000+)"
echo "    - Estimated cost (should be \$0.05 - \$0.50)"
echo "  - 'Proceed with execution?' prompt"
echo ""

# Test 3: With verification enabled (dual cost)
echo "TEST 3: With verification enabled (should show dual cost)"
echo "---------------------------------------"
echo "Steps to test manually:"
echo "1. Run: ./aiwb"
echo "2. Enter: /make"
echo "3. Enter: prompt Create a REST API"
echo "4. Enter: check   (enable verification)"
echo "5. Select a checker provider (e.g., claude or gemini)"
echo "6. Enter: run"
echo ""
echo "Expected output:"
echo "  - Cost Estimation header"
echo "  - Generation section (as before)"
echo "  - Verification section showing:"
echo "    - Provider and model for checker"
echo "    - Estimated verification cost"
echo "  - Total estimated cost (sum of both)"
echo "  - 'Proceed with execution?' prompt"
echo ""

# Test 4: Swarm mode cost
echo "TEST 4: Swarm mode cost estimation (large codebase)"
echo "---------------------------------------"
echo "Steps to test manually:"
echo "1. Run: ./aiwb"
echo "2. Enter: /make"
echo "3. Enter: swarm   (configure swarm mode)"
echo "4. Enable swarm mode"
echo "5. Set strategy to 'mapreduce'"
echo "6. Enter: prompt Analyze and document entire codebase"
echo "7. Enter: uploads lib/*.sh docs/*.md"
echo "8. Enter: run"
echo ""
echo "Expected output:"
echo "  - Cost Estimation header"
echo "  - Swarm cost breakdown showing:"
echo "    - Phase 1 (Workers): token count and cost"
echo "    - Phase 2 (Aggregator): token count and cost"
echo "    - Total swarm cost"
echo "  - OR fallback to standard mode if context too small"
echo "  - 'Proceed with execution?' prompt"
echo ""

# Test 5: Cost tracking after execution
echo "TEST 5: Post-execution cost tracking"
echo "---------------------------------------"
echo "Steps to test manually:"
echo "1. Complete any of the above tests by confirming 'yes'"
echo "2. Wait for execution to complete"
echo "3. Check session footer at bottom of screen"
echo ""
echo "Expected output:"
echo "  - Status footer with 3 lines:"
echo "    Line 1: Model (provider/model)"
echo "    Line 2: Context summary"
echo "    Line 3: Cost: \$X.XXXX this | \$X.XXXX total | Msgs: N"
echo "  - Color coding:"
echo "    - Green: < \$0.01 per response, < \$0.10 total"
echo "    - Yellow: < \$0.10 per response, < \$1.00 total"
echo "    - Red: >= \$0.10 per response, >= \$1.00 total"
echo ""
echo "4. Check usage log:"
echo "   cat ~/.aiwb/workspace/logs/usage.jsonl"
echo ""
echo "Expected output:"
echo "  - JSON entries with actual token counts and costs"
echo ""

# Configuration check
echo "========================================="
echo "Configuration Check"
echo "========================================="
echo ""
echo "Verify these settings in ~/.aiwb/config.json:"
echo ""
cat << 'EOF'
{
  "preferences": {
    "auto_estimate": true,          ← Must be true
    "confirm_before_generate": true, ← Must be true for prompt
    "show_costs": true               ← Must be true
  },
  "cost_tracking": {
    "enabled": true                  ← Must be true for logging
  }
}
EOF
echo ""

# Quick automated test (non-interactive)
echo "========================================="
echo "Quick Automated Test"
echo "========================================="
echo ""
echo "Testing cost calculation functions directly..."
echo ""

# Source the libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/lib/api.sh" ]]; then
    source "$SCRIPT_DIR/lib/common.sh" 2>/dev/null || true
    source "$SCRIPT_DIR/lib/api.sh" 2>/dev/null || true

    echo "Test: estimate_tokens()"
    test_text="This is a test prompt for token estimation."
    if type estimate_tokens &>/dev/null; then
        tokens=$(estimate_tokens "$test_text")
        echo "  Input: '$test_text'"
        echo "  Estimated tokens: $tokens"
        echo "  Expected: ~15 tokens (1 token per ~3 chars)"
        echo "  ✓ Function exists and returns: $tokens"
    else
        echo "  ✗ Function not found (run ./aiwb first to initialize)"
    fi
    echo ""

    echo "Test: calculate_cost()"
    if type calculate_cost &>/dev/null; then
        cost=$(calculate_cost "gemini" "2.5-flash" 1000 2000)
        echo "  Provider: gemini"
        echo "  Model: 2.5-flash"
        echo "  Input tokens: 1000"
        echo "  Output tokens: 2000"
        echo "  Calculated cost: \$$cost"
        echo "  Expected: ~\$0.0003 (very cheap model)"
        echo "  ✓ Function exists and returns: \$$cost"
    else
        echo "  ✗ Function not found (run ./aiwb first to initialize)"
    fi
else
    echo "⚠ Cannot run automated test - lib/api.sh not found"
    echo "  Run ./aiwb first to initialize the environment"
fi

echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo ""
echo "Complete these tests to verify preflight cost:"
echo "  [ ] Test 1: Small prompt (low cost)"
echo "  [ ] Test 2: Large prompt with files (higher cost)"
echo "  [ ] Test 3: With verification (dual cost)"
echo "  [ ] Test 4: Swarm mode (multi-phase cost)"
echo "  [ ] Test 5: Post-execution tracking"
echo ""
echo "All tests should show:"
echo "  ✓ Cost estimation before execution"
echo "  ✓ Confirmation prompt"
echo "  ✓ Cost tracking after execution"
echo "  ✓ Updated session footer"
echo "  ✓ Logged to usage.jsonl"
echo ""
