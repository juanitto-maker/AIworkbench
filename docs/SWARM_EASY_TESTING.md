# Quick Swarm Testing Guide

## Easy Testing Mode (100 Token Threshold)

You can now test swarm mode with ANY query - even just "hi"!

### Step 1: Update AIWB

```bash
cd ~/AIworkbench
git pull origin claude/test-swarm-feature-fck5n
```

### Step 2: Configure for Easy Testing

```bash
./aiwb
/swarm
```

In the menu:
1. Select "Min tokens: 1000"
2. Choose "100 tokens - Always activate (for testing)" ⭐
3. Go back
4. Select "Enable swarm"

### Step 3: Test with Anything!

```
hi
```

You'll see:
```
🐝 Activating Swarm Mode
Strategy: auto | Workers: 5 | Context: 150 tokens (min: 100)

━━━ Phase 1: Parallel Processing ━━━
...workers running...

━━━ Phase 2: Aggregation ━━━
...
```

## Force Mode (Ultimate Testing)

Want swarm to ALWAYS activate, no matter what?

### Enable Force Mode

```bash
/swarm
# Select "Min tokens: 1000 (FORCED)"
# Choose "Force swarm mode (ignore token count)"
```

Now swarm will activate for EVERY query, even single-word queries!

## Threshold Options

| Option | When to Use |
|--------|-------------|
| **100 tokens** | Easy testing - triggers on any normal question |
| **1000 tokens** | Balanced - good for real use with small-medium contexts |
| **5000 tokens** | Conservative - only large contexts |
| **10000 tokens** | Original behavior - very large contexts only |
| **Force mode** | Testing - ignores token count completely |

## Testing Scenarios

### Test 1: Simple Question (100 token threshold)

```bash
/swarm
# Set: 100 tokens
# Enable swarm

User: What is bash scripting?
```

**Expected**: Swarm activates, shows workers

### Test 2: Medium Question (1000 token threshold)

```bash
/swarm
# Set: 1000 tokens
# Enable swarm

User: Explain all the functions in lib/swarm.sh
```

**Expected**: Swarm activates if >1000 tokens

### Test 3: Force Mode

```bash
/swarm
# Set: Force mode
# Enable swarm

User: hi
```

**Expected**: Swarm activates even for "hi"!

## What You'll See

### Activation Message
```
🐝 Activating Swarm Mode
Strategy: auto | Workers: 5 | Context: 342 tokens (min: 100)
```

### Worker Progress
```
━━━ Phase 1: Parallel Processing ━━━
Processing 2 chunks with 5 parallel workers

  → Launched worker 1/2
  → Launched worker 2/2
  🤖 Worker 1: Processing...
  🤖 Worker 2: Processing...
  ✓ Worker 1: Complete
  ✓ Worker 2: Complete

⏳ Waiting for all workers to complete...
✓ All workers finished!

✓ Phase 1 complete: 2 chunks processed
```

### Aggregation Phase
```
━━━ Phase 2: Aggregation ━━━
Synthesizing results with claude/sonnet-4-5-20250929

  → Collected chunk 1/2
  → Collected chunk 2/2

🧠 Aggregating with claude...

✓ Phase 2 complete: Results aggregated
```

## Troubleshooting

### "Using standard mode" Message

If you see:
```
📝 Using standard mode (context: 50 tokens, need 100+ for swarm)
```

**Solution**: Lower the threshold or use force mode

### Workers Don't Show

If swarm activates but no workers appear:

1. Check API keys are configured
2. Check network connection
3. Look for error messages in output
4. Try with force mode to rule out threshold issues

### Still Not Working?

Enable debug mode to see what's happening:

```bash
export AIWB_DEBUG=1
./aiwb
```

Then try a query and watch for DEBUG messages.

## Recommended Settings for Testing

**Quick Testing:**
- Threshold: 100 tokens
- Workers: 3 (faster to see results)
- Worker model: gemini/2.5-flash (cheap)
- Aggregator: claude/sonnet-4-5 (good quality)

**Realistic Testing:**
- Threshold: 1000 tokens
- Workers: 5
- Worker model: gemini/2.5-flash
- Aggregator: claude/sonnet-4-5

**Stress Testing:**
- Force mode: enabled
- Workers: 10
- Any models you want to test

## Configuration Files

Your settings are saved in `~/.aiwb/config.json`:

```json
{
  "swarm": {
    "enabled": "true",
    "strategy": "auto",
    "workers": "5",
    "min_tokens": "100",
    "force": "false"
  }
}
```

You can edit this directly if needed.

## Cost Warning

⚠️ **Force mode with many workers can get expensive!**

If you enable force mode, EVERY query will use multiple API calls:
- N worker calls (where N = number of workers)
- 1 aggregator call

For testing, use:
- Low worker count (3-5)
- Cheap worker model (gemini/2.5-flash)
- Disable force mode when not testing

## Next Steps

1. ✅ Set threshold to 100 tokens
2. ✅ Enable swarm mode
3. ✅ Ask a simple question
4. ✅ Watch the workers in action!
5. ✅ Increase threshold for real use

Now you can easily see swarm mode working! 🐝
