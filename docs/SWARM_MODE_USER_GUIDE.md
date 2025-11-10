# 🐝 Swarm Mode User Guide

## What is Swarm Mode?

Swarm Mode enables AIWB to handle **large codebases** (100K+ lines of code) by using **multiple AI agents working in parallel**. Instead of sending everything to a single model (which would exceed context limits), swarm mode:

1. **Splits** your code into manageable chunks
2. **Processes** each chunk in parallel with cheap, fast models (workers)
3. **Aggregates** results with a more capable model
4. **Delivers** a comprehensive final answer

---

## When to Use Swarm Mode

✅ **Use swarm mode when:**
- Your codebase is > 10,000 lines of code
- Context exceeds ~10K tokens
- You're analyzing an entire project directory
- Standard mode says "context window exceeded"

❌ **Don't use swarm mode when:**
- Working with small files (< 10K tokens)
- Context fits in standard model limits
- You need real-time streaming responses

---

## How to Enable Swarm Mode

### From /make, /tweak, or /debug menu:

```
MAKE Mode
──────────────────────────────────────
  Prompt (text)
  Instruct (file)
  Model: gemini 2.5-flash
  Uploads: 5 items
  Check: (not set)
  Swarm: OFF                    ← Select this!
  Status
  Run
  View outputs
  Back
```

### In the Swarm Menu:

```
🐝 Swarm Mode (✗ DISABLED)
──────────────────────────────────────
  Strategy: auto
  Worker model: gemini/2.5-flash
  Aggregator model: claude/3.5-haiku
  Worker count: 5
  Enable swarm               ← Select this first!
  Back
```

---

## Configuration Options

### 1. Strategy

| Strategy | Best For | Speed | Setup |
|----------|----------|-------|-------|
| **auto** ⭐ | Let AIWB choose | Varies | None |
| **mapreduce** | One-time analysis | 2-5 min | None |
| **hierarchical** | Mobile/Termux | 5-10 sec | 30-60 min |

**Recommendation**: Use "auto" - it automatically picks the best strategy based on:
- Context size
- Platform (desktop vs mobile)
- Available indexes

### 2. Worker Model (for parallel processing)

| Model | Cost/1M tokens | Speed | Best For |
|-------|----------------|-------|----------|
| gemini/2.5-flash ⭐ | $0.10 | Fast | Default choice |
| gemini/2.0-flash-lite ⭐⭐ | $0.05 | Very fast | Highest volume |
| groq/llama-3.3-70b | $0.59 | Ultra fast | Speed priority |
| claude/3.5-haiku | $1.00 | Fast | Higher quality |

**Recommendation**: Use Gemini 2.5 Flash for best balance of cost/speed/quality.

### 3. Aggregator Model (for final synthesis)

| Model | Cost/1M tokens | Quality | Best For |
|-------|----------------|---------|----------|
| claude/3.5-sonnet ⭐⭐ | $3.00 | Excellent | Best results |
| claude/3.5-haiku ⭐ | $1.00 | Good | Budget-friendly |
| gemini/2.5-flash | $0.10 | Decent | Max savings |
| openai/gpt-4o | $2.50 | Excellent | OpenAI preference |

**Recommendation**: Use Claude 3.5 Haiku for good balance, or 3.5 Sonnet for best quality.

### 4. Worker Count

| Platform | Recommended | Why |
|----------|-------------|-----|
| **Desktop/Laptop** | 5-10 workers | Fast parallel processing |
| **Mobile/Termux** | 2-3 workers | Battery-friendly |

---

## Cost Comparison

### Example: 100K lines of code (~125K tokens)

**Standard Mode** (would fail):
```
❌ FAILS: Exceeds context window (200K max for most models)
```

**Swarm Mode** (Map-Reduce):
```
✅ SUCCESS:

Phase 1 - Workers: 50 chunks × gemini/2.5-flash
  Input: 125,000 tokens
  Output: 10,000 tokens
  Cost: $0.0155

Phase 2 - Aggregator: claude/3.5-haiku
  Input: 10,000 tokens
  Output: 1,000 tokens
  Cost: $0.015

Total: $0.0305 (~3 cents!)
Time: 2-3 minutes with 5 workers
```

**Savings**: Makes impossible tasks possible for pennies!

---

## Real-World Example

### Scenario: Analyzing a Large Python Project

```bash
# 1. Start AIWB
aiwb

# 2. Enter /make mode
/make

# 3. Set prompt
Prompt (text) → "Analyze this codebase and provide:
1. Overall architecture
2. Main components
3. Potential issues
4. Improvement recommendations"

# 4. Upload context
Uploads → Browse files → Select project directory (200 files, 50K LOC)

# 5. Enable swarm
Swarm: OFF → Enable swarm → Back

# 6. Review cost estimate
Run → Shows:
  Swarm Mode (Map-Reduce):
    Strategy: Split into 40 chunks

    Phase 1 - Workers: $0.012
    Phase 2 - Aggregator: $0.015

    Total swarm cost: $0.027

  Proceed? yes

# 7. Watch execution
🐝 Swarm mode active...
📊 Strategy: mapreduce
🔧 Worker model: gemini/2.5-flash
🎯 Aggregator: claude/3.5-haiku

Phase 1: Processing 40 chunks with 5 workers...
Worker launched for chunk 1/40
Worker launched for chunk 2/40
...
Phase 1 complete: 40 chunks processed

Phase 2: Aggregating results...
Phase 2 complete: Results aggregated

✓ Complete! Total time: 2m 14s
```

---

## Status Indicators

When swarm is enabled, you'll see:

```
Model: gemini 2.5-flash
Uploads: 15 items
Check: (not set)
Swarm: 🐝 ON (mapreduce, 5 workers)   ← Clear indicator!
```

During execution:

```
🐝 Swarm mode active...
📊 Strategy: mapreduce
🔧 Worker model: gemini/2.5-flash
🎯 Aggregator: claude/3.5-haiku
```

---

## Tips & Best Practices

### 1. Start with Auto Strategy
Let AIWB choose the best approach for your use case.

### 2. Use Cheap Workers
Workers process many chunks, so use the cheapest model (Gemini 2.0 Flash Lite).

### 3. Use Good Aggregator
The aggregator synthesizes everything, so use a capable model (Claude 3.5 Haiku/Sonnet).

### 4. Adjust Worker Count
- Desktop: 5-10 workers for speed
- Mobile: 2-3 workers for battery life

### 5. Monitor Costs
Swarm mode shows detailed cost breakdown before execution.

---

## Troubleshooting

### "Context too small for swarm"

**Problem**: Your prompt is < 10K tokens.
**Solution**: Swarm automatically falls back to standard mode. This is normal!

### Swarm seems slow

**Problem**: Too many/too few workers.
**Solution**: Adjust worker count:
- Too slow? Increase workers (up to 10)
- Rate limits? Decrease workers (down to 2-3)

### High costs

**Problem**: Using expensive models for workers.
**Solution**: Switch to cheaper worker model:
- Best: gemini/2.0-flash-lite ($0.05/1M)
- Good: gemini/2.5-flash ($0.10/1M)

---

## Advanced: Strategy Details

### Map-Reduce Strategy

**How it works:**
1. Split code into ~2.5K token chunks
2. Summarize each chunk in parallel
3. Combine all summaries
4. Generate final answer

**Best for:**
- One-time deep analysis
- Code review
- Bug hunting across entire project

**Pros:**
- No setup required
- Works with any codebase size
- Highly parallel (fast)

**Cons:**
- 2-5 minute execution time
- More expensive than hierarchical for repeated queries

### Hierarchical Strategy

**How it works:**
1. One-time: Build summary pyramid (file → package → project)
2. Query: Drill down through levels to find relevant code
3. Send only relevant code to LLM

**Best for:**
- Repeated queries on same codebase
- Mobile/Termux (battery-friendly)
- Interactive exploration

**Pros:**
- Very fast queries (5-10 sec)
- Extremely cheap per query ($0.001)
- Battery-friendly

**Cons:**
- 30-60 min initial setup
- Requires re-indexing after major changes

### Auto Strategy

**Decision tree:**
```
Context < 10K tokens?
  → Standard mode (no swarm)

Context 10K-50K + Already indexed?
  → Hierarchical (fastest)

Context 10K-50K + Not indexed?
  → Map-Reduce (no setup)

Context > 50K?
  → Map-Reduce (handles any size)
```

---

## FAQ

**Q: Does swarm work with all providers?**
A: Yes! Configure any provider/model combination for workers and aggregator.

**Q: Can I use swarm with images?**
A: Not yet. Swarm currently only supports text. Images will fall back to standard mode.

**Q: Does swarm work with verification mode?**
A: Yes! Verification runs after swarm aggregation completes.

**Q: Will swarm work on my old laptop?**
A: Yes! Swarm runs API calls remotely. Local system only orchestrates.

**Q: Can I interrupt swarm execution?**
A: Yes! Ctrl+C works. Already-completed chunks are saved.

**Q: How is swarm different from standard mode?**
A: Standard mode: 1 model, 1 call, limited context
   Swarm mode: Many models, parallel calls, unlimited context

---

## Performance Expectations

### 100K Lines of Code

| Metric | Standard Mode | Swarm Mode |
|--------|---------------|------------|
| **Success rate** | ❌ Fails | ✅ Works |
| **Time** | N/A | 2-3 minutes |
| **Cost** | N/A | $0.03 |
| **Workers** | 1 | 5 |

### 1M Lines of Code

| Metric | Standard Mode | Swarm Mode |
|--------|---------------|------------|
| **Success rate** | ❌ Fails | ✅ Works |
| **Time** | N/A | 20-30 minutes |
| **Cost** | N/A | $0.30 |
| **Workers** | 1 | 10 |

---

## Getting Help

If swarm mode isn't working as expected:

1. Check worker count (try reducing to 2-3)
2. Verify API keys are set for both worker and aggregator providers
3. Review cost estimation - if $0, context might be too small
4. Check logs in `~/.aiwb/workspace/logs/`
5. Report issues at: https://github.com/juanitto-maker/AIworkbench/issues

---

**🐝 Happy swarming!**
