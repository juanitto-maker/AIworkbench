# Swarm Mode Visual Indicators

## What You'll See When Swarm Activates

When you enable swarm mode and ask a question with large context (>10K tokens), you'll now see clear visual feedback:

### 1. Swarm Activation Notice

```
🐝 Activating Swarm Mode
Strategy: auto | Workers: 5 | Context: 15,234 tokens
```

### 2. Phase 1: Parallel Processing

```
━━━ Phase 1: Parallel Processing ━━━
Processing 6 chunks with 5 parallel workers

  → Launched worker 1/6
  → Launched worker 2/6
  → Launched worker 3/6
  → Launched worker 4/6
  → Launched worker 5/6
  🤖 Worker 1: Processing...
  🤖 Worker 2: Processing...
  🤖 Worker 3: Processing...
  🤖 Worker 4: Processing...
  🤖 Worker 5: Processing...
  ✓ Worker 1: Complete
  → Launched worker 6/6
  ✓ Worker 2: Complete
  🤖 Worker 6: Processing...
  ✓ Worker 3: Complete
  ✓ Worker 4: Complete
  ✓ Worker 5: Complete
  ✓ Worker 6: Complete

⏳ Waiting for all workers to complete...
✓ All workers finished!

✓ Phase 1 complete: 6 chunks processed
```

### 3. Phase 2: Aggregation

```
━━━ Phase 2: Aggregation ━━━
Synthesizing results with claude/sonnet-4-5-20250929

  → Collected chunk 1/6
  → Collected chunk 2/6
  → Collected chunk 3/6
  → Collected chunk 4/6
  → Collected chunk 5/6
  → Collected chunk 6/6

🧠 Aggregating with claude...

✓ Phase 2 complete: Results aggregated
```

### 4. Final Response

```
AI:
[Your comprehensive analysis from the swarm...]
```

## When Swarm Doesn't Activate

### Context Too Small

If your query context is < 10K tokens:

```
📝 Using standard mode (context: 2,145 tokens)
Thinking...
```

### Swarm Disabled

If swarm mode is disabled:

```
Thinking...
```

No special message - just normal processing.

## How to Enable Swarm

### Method 1: Interactive Menu

```bash
./aiwb
/swarm
# Select "Enable swarm"
```

### Method 2: Quick Command

```bash
./aiwb
/swarm on
```

### Method 3: Edit Config

Edit `~/.aiwb/config.json`:

```json
{
  "swarm": {
    "enabled": "true"
  }
}
```

## Testing Swarm Mode

### Create Large Context

```bash
./aiwb
/contextload
```

This loads your entire codebase (if available).

### Ask a Complex Question

```
Analyze all the code in lib/ and suggest improvements
```

If context > 10K tokens, you'll see swarm activate!

### Monitor the Progress

You'll see:
- ✅ Workers launching
- ✅ Workers processing in parallel
- ✅ Workers completing
- ✅ Aggregation phase
- ✅ Final synthesis

## Color Guide

- 🔵 **Cyan**: Informational messages, phase headers
- 🟢 **Green**: Success messages, completed workers
- 🟡 **Yellow**: Warnings, waiting states
- ⚪ **Dim**: Less important details

## Troubleshooting

### No Visual Indicators

**Issue**: You don't see the swarm activation message

**Check**:
1. Is swarm enabled? `/swarm status`
2. Is context large enough? Need >10K tokens
3. Are you using the latest version? `git pull`

### Workers Don't Show Progress

**Issue**: You see "Activating Swarm Mode" but no worker messages

**Possible Causes**:
1. API errors - check your API keys
2. Network issues - check connection
3. Model not available - check provider status

### Falls Back to Standard Mode

```
⚠ Swarm mode unavailable, falling back to standard mode
```

This happens when:
- Swarm function isn't loaded properly
- API calls fail during swarm execution
- Context is borderline (slightly > 10K tokens)

## Performance Notes

### Speed

With swarm mode (5 workers):
- **Phase 1**: ~2-3 minutes (parallel processing)
- **Phase 2**: ~1-2 minutes (aggregation)
- **Total**: ~3-5 minutes for large codebases

Without swarm mode:
- **Single request**: 5-10 minutes (sequential processing)
- May timeout on very large contexts

### Cost

Swarm mode uses:
- Multiple worker API calls (cheap models recommended)
- One aggregator call (smart model recommended)

**Example**:
- 6 chunks × Gemini 2.5 Flash ($0.10/1M) = ~$0.002
- 1 aggregation × Claude Sonnet 4.5 ($3.00/1M) = ~$0.005
- **Total**: ~$0.007 per query

vs Single large query:
- 1 request × Claude Sonnet 4.5 = ~$0.008
- May fail or timeout

**Swarm is faster AND cheaper!**

## Advanced: Customize Worker Count

More workers = faster (but more concurrent API calls):

```bash
/swarm
# Select "Worker count"
# Enter: 10
```

Recommended:
- **3-5 workers**: Balanced
- **5-10 workers**: Fast (requires good API rate limits)
- **10-20 workers**: Maximum speed (may hit rate limits)

## Next Steps

1. Enable swarm mode: `/swarm on`
2. Load large context: `/contextload`
3. Ask a complex question
4. Watch the workers go! 🐝

---

**Related Docs**:
- [Swarm Testing Guide](SWARM_TESTING_GUIDE.md)
- [Swarm Implementation](SWARM_MODE_IMPLEMENTATION.md)
- [Test Report](SWARM_TEST_REPORT.md)
