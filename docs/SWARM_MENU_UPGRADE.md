# Swarm Command Unified Menu Interface

## Overview

The `/swarm` command has been upgraded from a simple toggle/status command to a full interactive menu interface, providing a unified way to configure all swarm mode settings.

## What Changed

### Before (Simple Commands)

Previously, swarm configuration required multiple commands:

```bash
# Check status
/swarm status

# Toggle on/off
/swarm

# Enable explicitly
/swarm on

# Disable explicitly
/swarm off
```

To change settings, you had to manually edit `~/.aiwb/config.json`:

```json
{
  "swarm": {
    "enabled": "true",
    "strategy": "mapreduce",
    "worker_provider": "gemini",
    "worker_model": "2.5-flash",
    "workers": "10"
  }
}
```

### After (Unified Menu)

Now, `/swarm` opens an interactive menu with all options:

```bash
/swarm
```

**Interactive Menu:**
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

## Menu Features

### 1. Toggle Swarm Mode
- **Location**: Option 5 in main menu
- **Function**: Enable/disable swarm mode
- **Visual Feedback**:
  - Header shows `(✗ DISABLED)` or `(✓ ENABLED)`
  - Option text changes between "Enable swarm" and "Disable swarm"

### 2. Select Strategy
- **Location**: Option 1 in main menu
- **Options**:
  - `auto` - Let AIWB choose based on context size (Recommended)
  - `mapreduce` - Parallel processing with multiple workers
  - `hierarchical` - Battery-friendly for mobile (Not yet implemented)
- **Default**: auto

### 3. Configure Worker Model
- **Location**: Option 2 in main menu
- **Purpose**: Model used for parallel chunk processing
- **Options**:
  - `gemini/2.5-flash` ($0.10/1M tokens) ⭐ Recommended
  - `gemini/2.0-flash-lite` ($0.05/1M tokens) ⭐⭐ Most economical
  - `groq/llama-3.3-70b` ($0.59/1M tokens)
  - `claude/3.5-haiku` ($1.00/1M tokens)

### 4. Configure Aggregator Model
- **Location**: Option 3 in main menu
- **Purpose**: Model used to synthesize worker outputs
- **Options**:
  - `claude/sonnet-4.5` ($3.00/1M tokens) ⭐⭐ NEW - Best quality
  - `claude/3.5-sonnet` ($3.00/1M tokens) ⭐⭐ Proven quality
  - `claude/3.5-haiku` ($1.00/1M tokens) ⭐ Balanced
  - `gemini/2.5-flash` ($0.10/1M tokens) Most economical
  - `openai/gpt-4o` ($2.50/1M tokens)

### 5. Set Worker Count
- **Location**: Option 4 in main menu
- **Function**: Enter number of parallel workers
- **Range**: 1-20
- **Trade-off**:
  - More workers = faster processing
  - More workers = higher cost
  - Recommended: 3-5 for most tasks

## Benefits

### User Experience
✅ **Unified Interface**: All swarm settings in one place
✅ **Easy Discovery**: No need to remember command syntax
✅ **Visual Feedback**: Clear indication of current state
✅ **Cost Transparency**: See pricing for each model option
✅ **Consistent**: Matches other AIWB menus (/github, /models)

### Development
✅ **Maintainable**: Centralized menu logic in lib/swarm.sh
✅ **Extensible**: Easy to add new options
✅ **Testable**: Menu functions are isolated and testable

## Quick Commands Still Available

For scripts or quick operations, the original commands still work:

```bash
# Show detailed status
/swarm status

# Enable/disable directly
/swarm on
/swarm off

# Toggle
/swarm toggle
```

## Usage Examples

### Example 1: Enable Swarm with Custom Settings

```bash
# Open menu
/swarm

# Select option 5 to enable
5

# Configure strategy
# Select option 1
1
# Choose mapreduce
2

# Set worker count
# Select option 4
4
# Enter 10
10

# Done! Press 6 to go back
6
```

### Example 2: Quick Toggle

```bash
# Just toggle on/off
/swarm toggle
```

### Example 3: Check Current Configuration

```bash
# View full status
/swarm status
```

## Configuration Storage

All menu selections are automatically saved to `~/.aiwb/config.json`:

```json
{
  "swarm": {
    "enabled": "true",
    "strategy": "mapreduce",
    "worker_provider": "gemini",
    "worker_model": "2.5-flash",
    "aggregator_provider": "claude",
    "aggregator_model": "sonnet-4-5-20250929",
    "workers": "10"
  }
}
```

Settings persist across AIWB sessions.

## Migration Guide

### For Users

No migration needed! Your existing configuration will continue to work.

**If you were using:**
```bash
/swarm          # This now opens the menu instead of toggling
```

**To get the old behavior:**
```bash
/swarm toggle   # Explicit toggle command
```

### For Scripts

If you have scripts that use `/swarm`, update them to use explicit commands:

```bash
# Old script
echo "/swarm" | aiwb chat

# New script (recommended)
echo "/swarm toggle" | aiwb chat
# Or
echo "/swarm on" | aiwb chat
```

## Implementation Details

### Code Changes

**aiwb (Main Script)**
```bash
cmd_swarm() {
    local action="${1:-menu}"  # Default to menu

    case "$action" in
        menu|"")
            menu_swarm  # Call menu function
            ;;
        # ... other commands
    esac
}
```

**lib/swarm.sh (Menu Implementation)**
- `menu_swarm()` - Main menu loop
- `menu_swarm_strategy()` - Strategy selection submenu
- `menu_swarm_worker_model()` - Worker model selection
- `menu_swarm_aggregator_model()` - Aggregator model selection
- `menu_swarm_workers()` - Worker count input

### Testing

All existing tests continue to pass:
- Unit tests: 19/19 ✅
- Integration tests: 15/15 ✅
- Total: 80+ tests ✅

## Troubleshooting

### Menu Doesn't Appear

**Issue**: `/swarm` shows "Unknown command"

**Solution**: Pull latest changes:
```bash
cd ~/AIworkbench
git pull origin claude/test-swarm-feature-fck5n
```

### Menu Looks Broken

**Issue**: Menu text is garbled or not formatted correctly

**Solution**: Check if `gum` or `fzf` is installed:
```bash
pkg install fzf gum  # Termux
brew install fzf gum # macOS
apt install fzf      # Linux (gum not in repos)
```

### Configuration Not Saving

**Issue**: Changes don't persist after closing AIWB

**Solution**: Check config file permissions:
```bash
ls -la ~/.aiwb/config.json
# Should be writable by your user
chmod 644 ~/.aiwb/config.json
```

## Future Enhancements

Planned additions to the swarm menu:

- [ ] **Cost Estimation**: Show estimated cost before enabling
- [ ] **Performance Metrics**: Display historical swarm performance
- [ ] **Presets**: Save/load custom swarm configurations
- [ ] **Auto-tune**: Suggest optimal settings based on task
- [ ] **Real-time Monitoring**: View active worker progress

## Conclusion

The unified menu interface makes swarm mode more accessible and easier to configure. All settings are now in one place with clear descriptions and cost information.

**Try it out:**
```bash
./aiwb
/swarm
```

Enjoy the simplified swarm configuration! 🐝

---

**Related Documentation**:
- [Swarm Mode Implementation](SWARM_MODE_IMPLEMENTATION.md)
- [Swarm Testing Guide](SWARM_TESTING_GUIDE.md)
- [Swarm Test Report](SWARM_TEST_REPORT.md)
