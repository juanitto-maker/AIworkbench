# Swarm Mode Testing Guide

## Quick Start - Now Available! 🎉

The `/swarm` command is now integrated into AIWB! You can test it directly from the interactive chat.

## Testing the Swarm Feature

### 1. Update Your AIWB Installation

Pull the latest changes:

```bash
cd ~/AIworkbench
git fetch origin
git checkout claude/test-swarm-feature-fck5n
git pull
```

### 2. Interactive Testing (Easiest Method)

Start AIWB and use the `/swarm` command:

```bash
./aiwb
```

Once in the chat interface, try these commands:

#### Open Swarm Configuration Menu
```
/swarm
```

Simply typing `/swarm` opens an interactive menu where you can:
- **Toggle swarm on/off** - Enable or disable swarm mode
- **Select strategy** - Choose auto, mapreduce, or hierarchical
- **Configure worker model** - Select the model for parallel processing
- **Configure aggregator model** - Select the model for final synthesis
- **Set worker count** - Choose how many parallel workers (1-20)

The menu looks like this:
```
🐝 Swarm Mode (✗ DISABLED)

1) Strategy: auto
2) Worker model: gemini/2.5-flash
3) Aggregator model: claude/sonnet-4-5-20250929
4) Worker count: 5
5) Enable swarm
6) Back
```

#### Quick Commands (Alternative)

You can also use direct commands:

**Check Status:**
```
/swarm status
```

**Enable/Disable:**
```
/swarm on
/swarm off
```

**Toggle:**
```
/swarm toggle
```

#### View Help
```
/help
```

Shows all available commands, including `/swarm`.

### 3. What You Should See

#### Opening the Swarm Menu
```
/swarm
```

You'll see an interactive menu:
```
🐝 Swarm Mode (✗ DISABLED)

1) Strategy: auto
2) Worker model: gemini/2.5-flash
3) Aggregator model: claude/sonnet-4-5-20250929
4) Worker count: 5
5) Enable swarm
6) Back

?
```

#### Navigating the Menu

**Enable Swarm:**
- Select option "5) Enable swarm"
- You'll see: `✓ Swarm mode ENABLED 🐝`
- The menu updates to show `(✓ ENABLED)` and option 5 changes to "Disable swarm"

**Configure Strategy:**
- Select option "1) Strategy: auto"
- Choose from:
  - `auto - Let AIWB choose (Recommended)`
  - `mapreduce - Parallel processing`
  - `hierarchical - Battery-friendly (mobile)`

**Configure Worker Model:**
- Select option "2) Worker model"
- Choose from fast/cheap options like:
  - `gemini/2.5-flash ($0.10/1M) ⭐`
  - `gemini/2.0-flash-lite ($0.05/1M) ⭐⭐`
  - `groq/llama-3.3-70b ($0.59/1M)`
  - `claude/3.5-haiku ($1.00/1M)`

**Configure Aggregator Model:**
- Select option "3) Aggregator model"
- Choose from smart models for synthesis:
  - `claude/sonnet-4.5 ($3.00/1M) ⭐⭐ NEW`
  - `claude/3.5-sonnet ($3.00/1M) ⭐⭐`
  - `gemini/2.5-flash ($0.10/1M)`

**Set Worker Count:**
- Select option "4) Worker count"
- Enter a number between 1-20
- More workers = faster but more costly

#### Using Quick Commands

**Check Status:**
```
/swarm status

╔════════════════════════════════════════════════════════════╗
║ Swarm Mode Status                                            ║
╚════════════════════════════════════════════════════════════╝

Enabled: false
Strategy: auto
Workers: 5
Worker Provider: gemini
Worker Model: 2.5-flash
Aggregator Provider: claude
Aggregator Model: sonnet-4-5-20250929

Display: OFF
```

**Quick Toggle:**
```
/swarm toggle

✓  Swarm mode ENABLED 🐝
```

### 4. Testing with Real Queries

Once swarm mode is enabled, test with different query sizes:

#### Small Query (Won't Trigger Swarm)
```
Write a hello world function in Python
```

Expected: Processes normally without swarm (too small).

#### Large Query (Will Trigger Swarm)
```
/contextload
Analyze the entire codebase in lib/ and provide:
1. Architecture overview
2. Component relationships
3. Potential improvements
4. Code quality assessment
5. Testing coverage gaps
```

Expected: If context > 10K tokens, swarm mode activates automatically (when enabled).

### 5. Automated Test Suite

Run the comprehensive test suite:

```bash
# Unit tests (19 tests)
bats tests/test_swarm.bats

# Integration tests (15 tests)
./scripts/test_swarm_integration.sh

# All tests (80+ tests)
bats tests/*.bats
```

### 6. Configuration Testing

Edit your swarm configuration:

```bash
# View current config
cat ~/.aiwb/config.json | grep -A 10 "swarm"

# Edit configuration
nano ~/.aiwb/config.json
```

Example configuration:
```json
{
  "swarm": {
    "enabled": "true",
    "strategy": "auto",
    "worker_provider": "gemini",
    "worker_model": "2.5-flash",
    "aggregator_provider": "claude",
    "aggregator_model": "sonnet-4-5-20250929",
    "workers": "5"
  }
}
```

## Swarm Mode Behavior

### Auto Strategy (Recommended)

When `strategy: "auto"`:
- **Small contexts** (< 10K tokens): Processes normally
- **Large contexts** (> 10K tokens): Activates map-reduce

### Manual Strategies

- **mapreduce**: Explicitly use map-reduce strategy
- **hierarchical**: Not yet implemented (returns error)

## Cost Estimation

Before running expensive queries, check the cost:

```bash
/estimate
```

This will show estimated cost and token usage. If swarm mode would activate, it includes the cost of multiple workers + aggregator.

## Troubleshooting

### "Unknown command: /swarm"

If you see this error:
1. Make sure you pulled the latest changes
2. Restart AIWB
3. Check that you're on the correct branch

```bash
git branch
# Should show: * claude/test-swarm-feature-fck5n
```

### Swarm Mode Not Activating

1. Check if it's enabled:
   ```
   /swarm status
   ```

2. Verify your context is large enough (> 10K tokens):
   ```
   /status
   ```

3. Check configuration:
   ```bash
   cat ~/.aiwb/config.json | grep -A 8 "swarm"
   ```

### Configuration Not Persisting

If swarm settings don't persist:

1. Check file permissions:
   ```bash
   ls -la ~/.aiwb/config.json
   ```

2. Verify JSON syntax:
   ```bash
   jq . ~/.aiwb/config.json
   ```

## Expected Test Results

All tests should pass:

```
Unit Tests:      19/19 ✅
Integration:     15/15 ✅
Total Suite:     80/80 ✅
```

If any tests fail, check:
- BATS is installed: `which bats`
- You're in project root: `pwd` → `/home/user/AIworkbench`
- Scripts are executable: `chmod +x scripts/test_swarm_integration.sh`

## Advanced Testing

### Test Worker Parallelization

1. Enable swarm with multiple workers:
   ```
   /swarm on
   ```

2. Load large context:
   ```
   /contextload
   ```

3. Run analysis task:
   ```
   Provide comprehensive analysis of all files in the context
   ```

4. Monitor (in another terminal):
   ```bash
   # Watch for parallel API calls
   tail -f ~/.aiwb/workspace/logs/api_calls.log
   ```

### Test Different Model Combinations

Edit config to test different worker/aggregator combos:

**Fast workers + Smart aggregator:**
```json
{
  "worker_provider": "gemini",
  "worker_model": "2.5-flash",
  "aggregator_provider": "claude",
  "aggregator_model": "sonnet-4-5-20250929"
}
```

**All Claude:**
```json
{
  "worker_provider": "claude",
  "worker_model": "3-5-haiku-20241022",
  "aggregator_provider": "claude",
  "aggregator_model": "sonnet-4-5-20250929"
}
```

## Performance Metrics

Track swarm performance:

```bash
# View usage logs
cat ~/.aiwb/workspace/logs/usage.jsonl | tail -5

# Calculate total costs
./aiwb
/costs
```

## Next Steps

After testing:

1. ✅ Verify `/swarm` command works
2. ✅ Run all test suites
3. ✅ Test with real workloads
4. ✅ Monitor costs and performance
5. ✅ Report any issues found

## Reporting Issues

If you find bugs or have suggestions:

1. Check existing tests for similar cases
2. Run the test suite to confirm the issue
3. Create a new test case demonstrating the problem
4. Submit a pull request or issue with:
   - Steps to reproduce
   - Expected vs actual behavior
   - Test case (if applicable)

## Documentation

- **Implementation Details**: `docs/SWARM_MODE_IMPLEMENTATION.md`
- **User Guide**: `docs/SWARM_MODE_USER_GUIDE.md`
- **Test Report**: `docs/SWARM_TEST_REPORT.md`
- **Test Suite**: `tests/test_swarm.bats`
- **Integration Tests**: `scripts/test_swarm_integration.sh`

---

Happy testing! 🐝

**Note**: The swarm feature is production-ready for the map-reduce strategy. Hierarchical and RAG strategies are planned for future releases.
