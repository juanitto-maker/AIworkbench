# Termux Session Recovery Guide

## How to End Blocked/Hanging Termux Sessions

**You DO NOT need to reinstall Termux!** Here are several methods to recover from blocked sessions:

### Method 1: Kill the Hung Process (Recommended)

1. **Open a new Termux session** (swipe from left edge → "New Session")

2. **Find the hung process:**
   ```bash
   ps aux | grep aiwb
   ```

3. **Kill the process:**
   ```bash
   kill -9 <PID>
   ```
   Replace `<PID>` with the process ID from step 2.

4. **Alternative - Kill all aiwb processes:**
   ```bash
   pkill -9 aiwb
   ```

### Method 2: Kill All Curl Processes

If the app is stuck on an API call:
```bash
pkill -9 curl
```

### Method 3: Close the Hung Session via Termux UI

1. **Swipe from the left edge** to open the session drawer
2. **Long-press on the hung session**
3. **Select "Kill"** or tap the X icon

### Method 4: Force Stop and Restart Termux

1. **Go to Android Settings** → Apps → Termux
2. **Force Stop** the app
3. **Reopen Termux**
4. All sessions will be fresh

### Method 5: Clean Up Temp Files

Sometimes temp files can accumulate:
```bash
rm -f /tmp/aiwb_curl_* 2>/dev/null
rm -f ~/.aiwb/workspace/logs/chat_*.log.lock 2>/dev/null
```

## Preventing Future Hangs

The latest update includes:

1. **Improved Ctrl+C handling** - Now uses `jobs -p` to reliably kill background processes
2. **Better cleanup** - Automatically removes temp files on interrupt
3. **Forced termination** - Uses `kill -9` as backup if graceful shutdown fails

## Testing the Fix

After updating, test Ctrl+C:

1. **Start a request:**
   ```bash
   ./aiwb
   > Hello AI, write me a very long story
   ```

2. **Press Ctrl+C** immediately during the API call

3. **Verify:**
   - Should see "Interrupted! Cleaning up..."
   - Should exit cleanly with "Goodbye!"
   - Session should not hang

## Common Issues After Hung Sessions

### Background Processes Still Running

Check for lingering processes:
```bash
ps aux | grep -E 'aiwb|curl'
```

Kill them:
```bash
pkill -9 -f aiwb
pkill -9 curl
```

### Temp Files Taking Up Space

Clean up:
```bash
# Check temp file usage
du -sh /tmp/aiwb_curl_* 2>/dev/null

# Remove them
rm -f /tmp/aiwb_curl_*
```

### Session Won't Start After Hang

Reset the workspace lock:
```bash
rm -f ~/.aiwb/workspace/.lock 2>/dev/null
```

## Emergency: Complete Reset

**Only if all else fails:**

```bash
# Save your API keys first!
cp ~/.aiwb/.env ~/aiwb-backup.env

# Kill everything
pkill -9 -f aiwb
pkill -9 curl

# Clean temp files
rm -rf /tmp/aiwb_*

# Clean session locks
rm -f ~/.aiwb/workspace/.lock

# Restart
./aiwb
```

## Still Having Issues?

1. **Check if it's a network issue:**
   ```bash
   ping -c 3 google.com
   ```

2. **Verify curl works:**
   ```bash
   curl -I https://www.google.com
   ```

3. **Check Termux permissions:**
   - Go to Android Settings → Apps → Termux → Permissions
   - Ensure Storage permission is granted

4. **Report the issue:**
   - GitHub: https://github.com/juanitto-maker/AIworkbench/issues
   - Include: Error messages, Termux version, Android version

## Why Sessions Hang

Common causes:

1. **Network timeouts** - API servers not responding
2. **Background processes** - Curl processes not being killed properly
3. **Signal handling** - Ctrl+C not propagating to background jobs
4. **File locks** - Temp files locked by crashed processes

The latest update addresses all of these issues!
