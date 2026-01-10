# Swarm Mode Quick Start Guide

## What is Swarm Mode?

Swarm mode is a multi-agent AI orchestration feature that splits large codebases/prompts into chunks, processes them in parallel with multiple AI workers, and then aggregates the results.

**Benefits:**
- ✅ Handle large codebases that exceed single model context limits
- ✅ Cost-effective (uses cheaper models for workers, premium model for aggregation)
- ✅ Faster processing through parallelization
- ✅ Example: 100K lines (~125K tokens) costs ~$0.03 with swarm vs. would fail with standard mode

## How to Enable Swarm Mode

### Method 1: Interactive Menu

```bash
# In AIWB chat:
/swarm

# Then select "Enable swarm"
```

### Method 2: Force Enable for Testing

```bash
# In AIWB chat:
/swarm

# Navigate to "Min tokens" and enable force mode
# This allows testing swarm with small prompts
```

## Default Configuration

```
Swarm Mode: OFF (must be manually enabled)
Strategy: auto (automatically chooses best approach)
Worker Model: gemini/2.5-flash (cost-effective)
Aggregator Model: claude/sonnet-4-5-20250929 (high quality)
Worker Count: 5 workers
Min Tokens: 100 (threshold for activation)
```

## When Does Swarm Activate?

Swarm mode only activates when **BOTH** conditions are met:

1. ✅ **Swarm is enabled** via `/swarm` menu
2. ✅ **Prompt exceeds token threshold** (100 tokens by default)

If your prompt is small (<100 tokens), swarm will automatically fall back to standard mode with a message:
```
⚠ Prompt too small for swarm mode (1 chunks)
Falling back to standard mode
```

## How to See Swarm in Action

### Step 1: Enable Swarm
```
/swarm
→ Select "Enable swarm"
→ Back to main menu
```

### Step 2: Create a Large Context
```
/scanrepo
```
This will scan your repository and add files to context.

### Step 3: Use a Mode with Large Prompt
```
/make
> prompt: "Analyze this codebase and suggest improvements"
> run
```

### Expected Swarm Output

When swarm activates, you'll see:

```
🐝 Swarm Mode Execution

━━━ Phase 1: Parallel Processing ━━━
Processing 3 chunks with 5 parallel workers

  → Launched worker 1/3
  🤖 Worker 1: Processing...
  → Launched worker 2/3
  🤖 Worker 2: Processing...
  → Launched worker 3/3
  🤖 Worker 3: Processing...

⏳ Waiting for all workers to complete...
  ✓ Worker 1: Complete
  ✓ Worker 2: Complete
  ✓ Worker 3: Complete
✓ All workers finished!

✓ Phase 1 complete: 3 chunks processed

━━━ Phase 2: Aggregation ━━━
Synthesizing results with claude/sonnet-4-5-20250929

[Aggregated result...]
```

## Troubleshooting

### "No agent working showed"

**Cause:** Swarm mode is **disabled by default**

**Solution:**
1. Run `/swarm`
2. Select "Enable swarm"
3. Run your task again

### "Prompt too small for swarm mode"

**Cause:** Your prompt is under 100 tokens

**Solutions:**
1. Add more files to context (`/context` or `/scanrepo`)
2. Write a longer prompt
3. Enable force mode in `/swarm` → "Min tokens" (for testing only)

### Swarm Enabled But Not Activating

**Check:**
```bash
# In AIWB:
/status

# Should show:
Swarm: 🐝 ON (auto, 5 workers)
```

If it shows "OFF", swarm is not enabled. Use `/swarm` to enable it.

### Testing Swarm with Small Prompts

```bash
/swarm
→ Select "Min tokens: 100"
→ Enable force mode
→ Back
→ Enable swarm
→ Back

# Now even small prompts will use swarm
/make
> prompt: "test"
> run

# You should see swarm workers activate
```

## Cost Optimization

Swarm is designed to be cost-effective:

- **Workers:** Use cheap, fast models (Gemini 2.5-flash: ~$0.15 per 1M tokens)
- **Aggregator:** Uses premium model only once (Claude Sonnet: ~$3 per 1M tokens)

**Example Cost Breakdown:**
```
100K line codebase = ~125K tokens
Workers (5 chunks × 25K tokens × $0.15/1M) = $0.019
Aggregator (5K output × $3/1M) = $0.015
Total: ~$0.03
```

Compare to standard mode:
```
125K tokens × $3/1M = $0.375 (12× more expensive)
AND likely to exceed context limits!
```

## Advanced Configuration

### Change Worker Model
```
/swarm → Worker model
Select a different model (e.g., groq/llama-3.3-70b for speed)
```

### Change Aggregator Model
```
/swarm → Aggregator model
Select a different model (e.g., openai/gpt-4o for different quality)
```

### Adjust Worker Count
```
/swarm → Worker count
Enter desired number (2-10 recommended)

Note: More workers = faster but more API costs
```

### Change Strategy
```
/swarm → Strategy
- auto: Automatically selects best approach (recommended)
- mapreduce: Parallel processing + aggregation
- hierarchical: Not yet implemented
```

## Key Differences from Docker Swarm

⚠️ **IMPORTANT:** This is NOT Docker Swarm!

- ❌ Not container orchestration
- ❌ Not Docker-related
- ✅ Multi-agent AI orchestration
- ✅ Splits prompts into chunks for AI workers
- ✅ Pure shell script implementation

The term "swarm" refers to multiple AI agents working together, similar to a bee swarm working in parallel.

## Summary

1. **Enable swarm:** `/swarm` → "Enable swarm"
2. **Add context:** `/scanrepo` or `/context`
3. **Run task:** `/make`, `/tweak`, or `/debug`
4. **Watch swarm work:** You'll see workers processing in parallel

**Remember:** Swarm is **OFF by default**. You must enable it explicitly!

---

*For more information, see the main documentation or run `/help` in AIWB.*
