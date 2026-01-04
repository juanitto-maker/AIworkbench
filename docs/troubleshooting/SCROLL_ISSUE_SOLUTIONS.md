# Scroll Issue Solutions - Terminal Chat Interface

## Issue Summary

**Problem:** In the AIWB chat interface, users experience scroll locking where they cannot scroll up to read previous messages unless they select text. The scroll viewport immediately jumps back to the bottom when attempting to scroll normally.

**Root Cause:** The `gum input` TUI (Text User Interface) component takes exclusive control of the terminal in raw mode, continuously redrawing the input prompt at the bottom of the screen. This prevents normal terminal scrollback behavior, especially in terminal emulators like Termux on Android.

**Why Text Selection Works:** When selecting text, the terminal enters "selection mode" which temporarily suspends the gum input's redraw loop, allowing free scrolling until selection is released.

---

## Implemented Solution

### ✅ Solution A: "Lazy Gum" - Delayed Input Activation (CURRENT)

**Status:** Implemented and active
**Commits:** `1a8d805`, `86a8d7a`
**Location:** `aiwb:386-409`

**How It Works:**
1. After AI response, shows minimal prompt: `[Scroll freely, or press any key to type...]`
2. Terminal is NOT locked - user can scroll up/down freely
3. When user presses any key, `gum input` activates with that character pre-filled
4. User continues typing with gum's nice UX

**Benefits:**
- ✅ User can scroll and read previous messages without restriction
- ✅ Still keeps gum's beautiful input UX when typing
- ✅ No terminal mode conflict during reading phase
- ✅ Natural flow - user controls when viewport locks

**Code Implementation:**
```bash
# Get input - Lazy Gum: terminal stays scrollable until user starts typing
if [[ -t 0 ]] && [[ "${AIWB_TEST_MODE:-0}" != "1" ]] && $GUM_AVAILABLE; then
    # Show minimal prompt - terminal is free to scroll
    printf "\n${DIM}[Scroll freely, or press any key to type...]${RESET}\n"

    # Wait for first keystroke without locking terminal
    local first_char
    read -n1 -s first_char || continue

    # Clear the prompt line
    echo -ne "\r\033[K\033[1A\r\033[K"

    # Now activate gum with the first character pre-filled
    if [[ -n "$first_char" ]]; then
        input=$(gum input --value "$first_char" --placeholder "Message or /command..." --width 80) || continue
    else
        input=$(gum input --placeholder "Message or /command..." --width 80) || continue
    fi
else
    # Fallback for piped input or test mode
    printf "\033[0m> "
    safe_read input || continue
fi
```

**Gap Reduction:**
- Message gap reduced from 4 lines to 1 line (`aiwb:459`)
- Provides visual separation while minimizing wasted space
- More messages visible on screen

---

## Alternative Solutions Explored

### Solution B: "Alternate Screen Buffer" - Split Reality

**Concept:** Use terminal's alternate screen for input (like vim/less)

**How It Works:**
```bash
# After showing response
printf "\n\n"

# Switch to alternate screen for input
tput smcup  # Enter alternate screen
input=$(gum input --placeholder "Message or /command..." --width 80)
tput rmcup  # Exit alternate screen, return to main screen with messages
```

**Pros:**
- ✅ Messages scrollable in main buffer, clean input in alternate buffer
- ✅ Main screen never loses scroll position
- ✅ Works in most modern terminals including Termux

**Cons:**
- ⚠️ Screen "flips" between modes - might feel jarring
- ⚠️ Unfamiliar pattern for some users

---

### Solution C: "Status Bar Mode" - Fixed Bottom Input

**Concept:** Manually position gum input at fixed bottom line, messages scroll above

**How It Works:**
```bash
# Get terminal height
term_height=$(tput lines)

# Reserve last 2 lines for input
tput cup $((term_height - 2)) 0
printf "${DIM}%*s${RESET}\n" $(tput cols) | tr ' ' '─'

# Run gum input on last line
tput cup $((term_height - 1)) 0
input=$(gum input --placeholder "Message or /command..." --width 80)

# Clear status area after input
tput cup $((term_height - 2)) 0
tput ed
```

**Pros:**
- ✅ Dedicated scroll area for messages
- ✅ Fixed input area at bottom
- ✅ Professional appearance (like IRC clients)

**Cons:**
- ⚠️ Complex cursor positioning logic
- ⚠️ Requires careful terminal size handling
- ⚠️ May not work well in all terminal emulators

---

### Solution D: "Smart Pause" - Detect Intent

**Concept:** Let user choose between scroll mode and fancy input mode

**How It Works:**
```bash
# Show choice prompt
cat << EOF >&2
${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}
${GREEN}Ready for input${RESET} - Choose:
  ${BOLD}[ENTER]${RESET} - Start typing (fancy input)
  ${BOLD}[↑]${RESET} - Scroll up (simple mode)
${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}
EOF

# Read intent
read -n1 -s intent_key

if [[ "$intent_key" == "" ]]; then
    input=$(gum input --placeholder "Message or /command..." --width 80)
else
    printf "\033[0m> "
    safe_read input
fi
```

**Pros:**
- ✅ User chooses which mode each time
- ✅ Educational - shows trade-off explicitly
- ✅ Flexible based on user needs

**Cons:**
- ⚠️ Extra keystroke required every time
- ⚠️ More verbose UI
- ⚠️ Interrupts workflow

---

### Solution E: "Tmux Integration" - Proper Panes

**Concept:** If tmux is available, use real panes for separation

**How It Works:**
```bash
if command -v tmux &>/dev/null && [[ -n "$TMUX" ]]; then
    # Use split panes
    # Top pane: scrollable messages
    # Bottom pane: fixed input (3 lines high)
    tmux split-window -l 3 "bash -c 'gum input ...'"
    input=$(tmux capture-pane -p)
    tmux kill-pane -t bottom
else
    # Fallback to regular mode
    ...
fi
```

**Pros:**
- ✅ Professional multi-pane interface
- ✅ True separation of concerns
- ✅ Tmux handles scroll perfectly

**Cons:**
- ⚠️ Only works if tmux is installed and running
- ⚠️ Complex setup and teardown
- ⚠️ Not all users use tmux

---

### Solution F: "Hybrid readline" - Enhanced Simple Input

**Concept:** Make simple prompt almost as nice as gum using bash readline

**How It Works:**
```bash
# Use bash's readline with custom styling
printf "${CYAN}┌─[${RESET} ${GREEN}AIworkbench${RESET} ${CYAN}]${RESET}\n"
printf "${CYAN}└─>${RESET} "

# Enable readline features
read -e -p "" input  # -e enables editing, history, etc

if [[ -n "$input" ]]; then
    printf "${DIM}✓ Sending...${RESET}\n"
fi
```

**Pros:**
- ✅ Still looks decent with box drawing
- ✅ Readline provides history (↑/↓), editing, tab completion
- ✅ No scroll locking at all
- ✅ Built-in bash - no dependencies

**Cons:**
- ⚠️ Not as polished as gum
- ⚠️ Loses gum's placeholder and styling features

---

### Solution G: "Gap Reduction Only" - Minimal Change

**Concept:** Just reduce message gap to make scrolling easier

**Implementation:**
```bash
# Reduce from 4 lines to 1-2 lines
printf "\n"  # or printf "\n\n"
```

**Pros:**
- ✅ Less wasted space
- ✅ Easier to scroll to previous messages
- ✅ Minimal code change

**Cons:**
- ⚠️ Doesn't fix root cause (gum still locks)
- ⚠️ Only partial improvement

---

### Solution H: "Conditional Termux Disable" - Platform-Specific

**Concept:** Disable gum only on Termux where scroll is critical

**How It Works:**
```bash
if [[ -t 0 ]] && [[ "${AIWB_TEST_MODE:-0}" != "1" ]] && $GUM_AVAILABLE && ! is_termux; then
    input=$(gum input --placeholder "Message or /command..." --width 80) || continue
else
    printf "\033[0m> "
    safe_read input || continue
fi
```

**Pros:**
- ✅ Desktop terminals keep gum
- ✅ Termux gets scroll-friendly simple prompt
- ✅ Uses existing `is_termux` detection

**Cons:**
- ⚠️ Different UX on mobile vs desktop
- ⚠️ Termux users lose gum aesthetics

---

### Solution I: "Pager Integration" - Professional Approach

**Concept:** Open long responses in a pager (like `less`)

**How It Works:**
```bash
# After long responses, offer to page
if [[ $(echo "$response" | wc -l) -gt 20 ]]; then
    echo "$response" | less -R  # Opens in pager
    printf "\n" >&2
else
    printf "%b\n" "${YELLOW}${response}${RESET}" >&2
fi

# Then show gum input normally
```

**Pros:**
- ✅ Long responses get full pager control
- ✅ Short responses display normally
- ✅ Professional UX

**Cons:**
- ⚠️ Mode switching for long responses
- ⚠️ Different interaction model
- ⚠️ Requires `less` or similar pager

---

## Solution Comparison Table

| Solution | Scroll Works? | Keeps Gum? | Complexity | UX Impact | Status |
|----------|--------------|------------|------------|-----------|--------|
| **A: Lazy Gum** | ✅ Yes | ✅ Yes | 🟡 Medium | Natural | **✅ ACTIVE** |
| **B: Alt Screen** | ✅ Yes | ✅ Yes | 🟡 Medium | Jarring flip | Considered |
| **C: Status Bar** | ✅ Yes | ✅ Yes | 🔴 High | Professional | Considered |
| **D: Smart Pause** | ✅ Yes | ⚠️ Partial | 🟢 Low | User choice | Considered |
| **E: Tmux** | ✅ Yes | ✅ Yes | 🔴 High | Pro-level | Considered |
| **F: Hybrid readline** | ✅ Yes | ❌ No | 🟢 Low | Decent | Considered |
| **G: Gap Only** | ⚠️ Partial | ✅ Yes | 🟢 Very Low | Same issue | Partial |
| **H: Termux Disable** | ✅ Yes | ⚠️ Desktop only | 🟢 Low | Platform split | Considered |
| **I: Pager** | ✅ Yes | ✅ Yes | 🔴 High | Mode switch | Considered |

---

## Technical Background

### Git History of Scroll Fixes

1. **Commit 35e3b47** - Fixed duplicate output causing scroll jumping
   - Response was displayed twice, causing viewport jumps
   - Fix: Redirect all display to stderr

2. **Commit b84e3b5** - Removed clipboard prompt scroll lock
   - 1-second timeout for copy functionality was locking scroll
   - Removed artificial delay

3. **Commit fe656d9** - Reduced scroll lock time (preliminary)

4. **Commit 0e43b73** - Attempted gum input removal + gap reduction
   - Disabled gum entirely for simple prompt
   - Reduced gap from 4 to 2 lines

5. **Commit 92da6a8** - Reverted gum removal
   - Decision: Prefer gum aesthetics over scroll functionality
   - Kept 4-line gap

6. **Commit 1a8d805** - Gap reduction (current effort)
   - Reduced gap from 4 to 2 lines

7. **Commit 86a8d7a** - Lazy Gum implementation
   - Delayed gum activation for scroll freedom
   - Gap further reduced to 1 line

### Key Files

| File | Purpose | Key Functions |
|------|---------|---------------|
| `/home/user/AIworkbench/aiwb` | Main executable | `chat_loop()`, `handle_chat_message()` |
| `/home/user/AIworkbench/lib/ui.sh` | UI components | `ui_input()`, gum availability check |
| `/home/user/AIworkbench/lib/common.sh` | Utilities | `safe_read()`, platform detection |

### Terminal Behavior Details

**Why Gum Locks Scroll:**
- `gum input` uses **raw terminal mode** for styled input
- Raw mode disables normal terminal scrolling during input
- Terminal continuously redraws input prompt at viewport bottom
- Scroll attempts are immediately cancelled by redraw

**How Lazy Gum Solves This:**
- Uses simple `read -n1` which doesn't lock terminal
- Only activates gum after user signals intent to type
- Preserves scroll freedom during "reading phase"
- Maintains gum UX during "typing phase"

---

## Usage & Testing

### How to Test Current Solution

```bash
# Start chat
./aiwb chat

# After AI responds:
# 1. See prompt: "[Scroll freely, or press any key to type...]"
# 2. Try scrolling up - should work without text selection
# 3. Press any key (e.g., 'h') when ready to type
# 4. Gum activates with first character filled
# 5. Complete your message
```

### How to Revert (If Needed)

```bash
# Revert Lazy Gum only (keep gap reduction)
git revert 86a8d7a

# Revert both (back to original)
git revert HEAD~2..HEAD
```

### How to Implement Alternative Solutions

If Lazy Gum doesn't work well, any of the solutions B-I can be implemented by modifying the input handling section in `aiwb:386-409`.

---

## Future Considerations

1. **User Preference Configuration**
   - Add config option to choose input method
   - `aiwb config set input_method [gum|lazy_gum|readline|simple]`

2. **Terminal Detection**
   - Auto-detect terminal capabilities
   - Use appropriate solution based on terminal type

3. **Hybrid Approach**
   - Combine multiple solutions for best coverage
   - E.g., Lazy Gum + Pager for long responses

4. **Accessibility**
   - Consider screen reader compatibility
   - Ensure keyboard navigation works smoothly

---

## Related Issues

- Original scroll jumping fix: #125, #126, #127
- Termux compatibility: See `docs/TERMUX_MOBILE_STRATEGY.md`
- Context handling: See `docs/troubleshooting/CONTEXT_ZERO_FILES_FIX.md`

---

## Credits

**Research & Implementation:** Claude (Anthropic)
**Testing & Feedback:** User (juanitto-maker)
**Date:** January 2026
**Branch:** `claude/fix-scroll-selection-issue-GvWeb`
