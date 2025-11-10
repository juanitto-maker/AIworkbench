# AIWB Functionality Testing Guide

## Quick Start

This test script will automatically test all providers and models you have API keys for.

### Step 1: Set Your API Keys

```bash
# Set at least ONE of these (test what you have keys for)
export GEMINI_API_KEY="your-gemini-key-here"
export ANTHROPIC_API_KEY="your-claude-key-here"
export OPENAI_API_KEY="your-openai-key-here"
export GROQ_API_KEY="your-groq-key-here"
export XAI_API_KEY="your-xai-key-here"
```

**Note:** The script will automatically skip providers where no API key is set.

### Step 2: Run the Test

```bash
cd /home/user/AIworkbench
./test_aiwb_functionality.sh
```

### Step 3: Wait for Results

The script will:
- Test chat mode with "hi" message for each model
- Test /make mode with a simple task for each model
- Generate detailed logs
- Show you a summary at the end

**Expected time:** ~2-5 minutes per model tested

### Step 4: Share Results with Claude

After completion, you'll see:
```
Log file: aiwb_test_results_TIMESTAMP.log
Summary file: aiwb_test_summary_TIMESTAMP.txt
```

**To share with Claude:**

```bash
# View the summary first
cat aiwb_test_summary_*.txt

# Then copy the full log
cat aiwb_test_results_*.log
```

Copy/paste the log contents to Claude for analysis.

---

## What Gets Tested

### For Each Provider + Model Combination:

1. **Chat Mode Test**
   - Sends message: "hi"
   - Waits for response
   - Checks for errors
   - Exits cleanly

2. **Make Mode Test**
   - Enters /make mode
   - Sets simple prompt: "Create a bash function that prints hello world"
   - Runs generation
   - Checks for errors
   - Exits cleanly

### Providers Tested (if API keys present):

- **Gemini**: 2.5-flash, 2.0-flash
- **Claude**: 3-haiku-20240307, 3-5-sonnet-20241022
- **OpenAI**: gpt-4o-mini, gpt-4o
- **Groq**: llama-3.3-70b-versatile, llama-3.2-3b-preview
- **xAI**: grok-beta, grok-2
- **Ollama**: llama3.2:latest (if running locally)

---

## Understanding Results

### ✓ PASSED
- API responded successfully
- No errors detected
- Clean exit

### ✗ FAILED
Common failure reasons:
- **TIMEOUT**: Test took >60 seconds
- **API Error**: 404, 401, 403, 500 errors
- **Model Not Found**: Invalid model name
- **Rate Limit**: Too many requests
- **Exit Code**: Non-zero exit code

### ○ SKIPPED
- No API key configured for that provider

---

## Troubleshooting

### "No API keys found"
```bash
# Make sure you exported the keys in your current shell
echo $GEMINI_API_KEY
# Should show your key, not empty
```

### "Permission denied"
```bash
chmod +x test_aiwb_functionality.sh
```

### Script hangs
- Press Ctrl+C to stop
- Each test has 60-second timeout
- Check your internet connection

### All tests fail
This is the useful data! Share the logs with Claude to diagnose.

---

## Example Session

```bash
# 1. Set API key
export GEMINI_API_KEY="AIzaSy..."

# 2. Run test
./test_aiwb_functionality.sh

# Output:
# Testing provider: gemini
#   Testing model: 2.5-flash
#     ✓ Chat: gemini/2.5-flash PASSED
#     ✗ Make: gemini/2.5-flash FAILED (API Error)
#   ...
#
# Summary written to: aiwb_test_summary_20251110_123456.txt
# Full log: aiwb_test_results_20251110_123456.log

# 3. View results
cat aiwb_test_summary_*.txt

# 4. Copy full log to share
cat aiwb_test_results_*.log
# Then copy/paste to Claude
```

---

## What to Share with Claude

**Minimum:** The summary file
**Better:** The full log file
**Best:** Both files + your observations

Example observations to add:
- "All Gemini tests failed with 404"
- "Make mode exits immediately after run"
- "Chat works but make mode doesn't"
- etc.

---

## Safety Notes

✅ **Safe:**
- Keys stay in your environment (not saved to files)
- Only makes test API calls
- Logs don't include your API keys

⚠️ **Be Aware:**
- Makes real API calls (costs money, but minimal)
- Each test is 1-2 API calls per model
- Total: ~4-10 API calls per provider tested

💡 **Recommendation:**
- Test with providers you have free/trial credits for
- Or use low-cost models (Gemini 2.5-flash, Claude Haiku)

---

## Quick Reference

```bash
# Set keys (pick what you have)
export GEMINI_API_KEY="..."
export ANTHROPIC_API_KEY="..."

# Run test
./test_aiwb_functionality.sh

# View summary
cat aiwb_test_summary_*.txt

# Share full log with Claude
cat aiwb_test_results_*.log
```

That's it! 🚀
