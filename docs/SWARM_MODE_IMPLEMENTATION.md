# Swarm Mode Implementation for AIWB

## Overview

This document describes the implementation of "Swarm Mode" - a multi-agent processing system for handling large codebases in AIWB.

---

## Menu Structure

### Main Mode Menu (Enhanced)

When user selects `/make`, `/tweak`, or `/debug`, they see:

```
┌─────────────────────────────────────────────┐
│        MAKE MODE - Generate Code            │
├─────────────────────────────────────────────┤
│  1. Set prompt                              │
│  2. Set instruction file                    │
│  3. Upload context                          │
│  4. Select model                            │
│  5. Verification (optional)                 │
│  6. 🐝 Enable Swarm Mode        [OFF]      │  ← NEW
│  ───────────────────────────────────────    │
│  7. Run                                     │
│  8. Back to main menu                       │
└─────────────────────────────────────────────┘
```

### Swarm Mode Submenu

When user selects "Enable Swarm Mode", they enter configuration:

```
┌─────────────────────────────────────────────┐
│     🐝 SWARM MODE CONFIGURATION             │
├─────────────────────────────────────────────┤
│  Current: ENABLED                           │
│                                             │
│  1. Strategy: Auto                          │
│  2. Worker Model: gemini/2.5-flash          │
│  3. Aggregator Model: claude/3.5-haiku      │
│  4. Parallel Workers: 5                     │
│  5. Memory Backend: SQLite                  │
│  ───────────────────────────────────────    │
│  6. Disable Swarm Mode                      │
│  7. Back                                    │
└─────────────────────────────────────────────┘
```

### Strategy Selection Submenu

```
┌─────────────────────────────────────────────┐
│     SELECT SWARM STRATEGY                   │
├─────────────────────────────────────────────┤
│  1. 🤖 Auto (Recommended)                   │
│     Let AIWB choose based on codebase size  │
│                                             │
│  2. 🔍 RAG (Semantic Search)                │
│     Best for: Repeated queries, < 1s        │
│     Setup: 5-10 min indexing                │
│     Memory: 30-300MB                        │
│                                             │
│  3. 📊 Map-Reduce (Parallel Processing)     │
│     Best for: One-time analysis             │
│     Setup: None                             │
│     Speed: 2-5 min for 100K LOC             │
│                                             │
│  4. 🏗️  Hierarchical (Battery-Friendly)     │
│     Best for: Termux/mobile                 │
│     Setup: 30-60 min, battery-safe          │
│     Memory: 5-30MB                          │
│                                             │
│  5. Back                                    │
└─────────────────────────────────────────────┘
```

### Auto Strategy Decision Tree

```
When "Auto" is selected, AIWB automatically chooses:

Context size < 10K tokens?
  → Use standard single-model (no swarm)

Context size 10K-50K tokens?
  → Use Hierarchical (fast, light)

Context size > 50K tokens + Desktop?
  → Use RAG (if indexed) or Map-Reduce

Context size > 50K tokens + Termux?
  → Use Hierarchical (battery-friendly)

Already have RAG index?
  → Always use RAG (fastest)
```

---

## Implementation

### File Structure

```
lib/
├── swarm.sh          ← NEW: Swarm mode core
├── swarm_rag.sh      ← NEW: RAG implementation
├── swarm_mapreduce.sh ← NEW: Map-Reduce implementation
├── swarm_hierarchical.sh ← NEW: Hierarchical implementation
├── modes.sh          ← MODIFIED: Add swarm menu
└── api.sh            ← MODIFIED: Multi-agent calls
```

### Core Implementation: lib/swarm.sh

```bash
#!/data/data/com.termux/files/usr/bin/bash
# AIWB Swarm Mode - Multi-agent processing

# Swarm configuration
SWARM_ENABLED=false
SWARM_STRATEGY="auto"
SWARM_WORKER_PROVIDER="gemini"
SWARM_WORKER_MODEL="2.5-flash"
SWARM_AGGREGATOR_PROVIDER="claude"
SWARM_AGGREGATOR_MODEL="3.5-haiku"
SWARM_WORKERS=5
SWARM_MEMORY_BACKEND="sqlite"  # or "chromadb"

# Load swarm sub-modules
source "${LIB_DIR}/swarm_rag.sh"
source "${LIB_DIR}/swarm_mapreduce.sh"
source "${LIB_DIR}/swarm_hierarchical.sh"

#──────────────────────────────────────────────────────────────
# Swarm configuration menu
#──────────────────────────────────────────────────────────────

menu_swarm_config() {
    while true; do
        clear
        echo "═══════════════════════════════════════════════════"
        echo "      🐝 SWARM MODE CONFIGURATION"
        echo "═══════════════════════════════════════════════════"
        echo ""
        echo "  Status: $([ "$SWARM_ENABLED" = true ] && echo "✓ ENABLED" || echo "✗ DISABLED")"
        echo ""
        echo "  Strategy:         $SWARM_STRATEGY"
        echo "  Worker Model:     $SWARM_WORKER_PROVIDER/$SWARM_WORKER_MODEL"
        echo "  Aggregator Model: $SWARM_AGGREGATOR_PROVIDER/$SWARM_AGGREGATOR_MODEL"
        echo "  Parallel Workers: $SWARM_WORKERS"
        echo "  Memory Backend:   $SWARM_MEMORY_BACKEND"
        echo ""
        echo "───────────────────────────────────────────────────"
        echo "  1. Change Strategy"
        echo "  2. Select Worker Model"
        echo "  3. Select Aggregator Model"
        echo "  4. Set Worker Count"
        echo "  5. Change Memory Backend"
        echo "───────────────────────────────────────────────────"
        echo "  6. $([ "$SWARM_ENABLED" = true ] && echo "Disable" || echo "Enable") Swarm Mode"
        echo "  7. Back to Mode Menu"
        echo ""

        read -p "Select option (1-7): " choice

        case "$choice" in
            1) menu_swarm_strategy ;;
            2) menu_swarm_worker_model ;;
            3) menu_swarm_aggregator_model ;;
            4) menu_swarm_worker_count ;;
            5) menu_swarm_memory_backend ;;
            6) swarm_toggle ;;
            7) return ;;
            *) echo "Invalid option" ;;
        esac
    done
}

#──────────────────────────────────────────────────────────────
# Strategy selection
#──────────────────────────────────────────────────────────────

menu_swarm_strategy() {
    clear
    echo "═══════════════════════════════════════════════════"
    echo "      SELECT SWARM STRATEGY"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "  1. 🤖 Auto (Recommended)"
    echo "     Let AIWB choose based on context size"
    echo ""
    echo "  2. 🔍 RAG (Retrieval-Augmented Generation)"
    echo "     Best for: Repeated queries, semantic search"
    echo "     Speed: < 1 second per query"
    echo "     Setup: 5-10 min one-time indexing"
    if is_termux; then
        echo "     ⚠️  Heavy on mobile (300MB, battery drain)"
    fi
    echo ""
    echo "  3. 📊 Map-Reduce (Parallel Processing)"
    echo "     Best for: One-time deep analysis"
    echo "     Speed: 2-5 minutes for 100K LOC"
    echo "     Setup: None required"
    echo ""
    echo "  4. 🏗️  Hierarchical (Summary Pyramid)"
    echo "     Best for: Termux/mobile, battery-friendly"
    echo "     Speed: 5-10 seconds per query"
    echo "     Setup: 30-60 min battery-safe indexing"
    if is_termux; then
        echo "     ✓ Recommended for mobile!"
    fi
    echo ""
    echo "  5. Back"
    echo ""

    read -p "Select strategy (1-5): " choice

    case "$choice" in
        1) SWARM_STRATEGY="auto" ;;
        2) SWARM_STRATEGY="rag" ;;
        3) SWARM_STRATEGY="mapreduce" ;;
        4) SWARM_STRATEGY="hierarchical" ;;
        5) return ;;
        *) echo "Invalid option"; return ;;
    esac

    config_set "swarm_strategy" "$SWARM_STRATEGY"
    info "Strategy set to: $SWARM_STRATEGY"
    sleep 1
}

#──────────────────────────────────────────────────────────────
# Worker model selection
#──────────────────────────────────────────────────────────────

menu_swarm_worker_model() {
    clear
    echo "═══════════════════════════════════════════════════"
    echo "      SELECT WORKER MODEL (for parallel tasks)"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "  Workers process chunks in parallel."
    echo "  Use CHEAP, FAST models!"
    echo ""
    echo "  Recommended:"
    echo "  1. gemini/2.5-flash      ($0.10/1M) ⭐"
    echo "  2. gemini/2.0-flash-lite ($0.05/1M) ⭐⭐"
    echo "  3. groq/llama-3.3-70b    ($0.59/1M)"
    echo "  4. claude/3.5-haiku      ($1.00/1M)"
    echo ""
    echo "  5. Custom provider/model"
    echo "  6. Back"
    echo ""

    read -p "Select worker model (1-6): " choice

    case "$choice" in
        1)
            SWARM_WORKER_PROVIDER="gemini"
            SWARM_WORKER_MODEL="2.5-flash"
            ;;
        2)
            SWARM_WORKER_PROVIDER="gemini"
            SWARM_WORKER_MODEL="2.0-flash-lite"
            ;;
        3)
            SWARM_WORKER_PROVIDER="groq"
            SWARM_WORKER_MODEL="llama-3.3-70b"
            ;;
        4)
            SWARM_WORKER_PROVIDER="claude"
            SWARM_WORKER_MODEL="3.5-haiku"
            ;;
        5)
            read -p "Provider: " SWARM_WORKER_PROVIDER
            read -p "Model: " SWARM_WORKER_MODEL
            ;;
        6) return ;;
        *) echo "Invalid option"; return ;;
    esac

    config_set "swarm_worker_provider" "$SWARM_WORKER_PROVIDER"
    config_set "swarm_worker_model" "$SWARM_WORKER_MODEL"
    success "Worker model set to: $SWARM_WORKER_PROVIDER/$SWARM_WORKER_MODEL"
    sleep 1
}

#──────────────────────────────────────────────────────────────
# Aggregator model selection
#──────────────────────────────────────────────────────────────

menu_swarm_aggregator_model() {
    clear
    echo "═══════════════════════════════════════════════════"
    echo "      SELECT AGGREGATOR MODEL (for final synthesis)"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "  Aggregator combines results from workers."
    echo "  Use BETTER, more capable models."
    echo ""
    echo "  Recommended:"
    echo "  1. claude/3.5-sonnet    ($3.00/1M) ⭐⭐"
    echo "  2. claude/3.5-haiku     ($1.00/1M) ⭐"
    echo "  3. gemini/2.5-flash     ($0.10/1M)"
    echo "  4. openai/gpt-4o        ($2.50/1M)"
    echo ""
    echo "  5. Custom provider/model"
    echo "  6. Back"
    echo ""

    read -p "Select aggregator model (1-6): " choice

    case "$choice" in
        1)
            SWARM_AGGREGATOR_PROVIDER="claude"
            SWARM_AGGREGATOR_MODEL="3.5-sonnet"
            ;;
        2)
            SWARM_AGGREGATOR_PROVIDER="claude"
            SWARM_AGGREGATOR_MODEL="3.5-haiku"
            ;;
        3)
            SWARM_AGGREGATOR_PROVIDER="gemini"
            SWARM_AGGREGATOR_MODEL="2.5-flash"
            ;;
        4)
            SWARM_AGGREGATOR_PROVIDER="openai"
            SWARM_AGGREGATOR_MODEL="gpt-4o"
            ;;
        5)
            read -p "Provider: " SWARM_AGGREGATOR_PROVIDER
            read -p "Model: " SWARM_AGGREGATOR_MODEL
            ;;
        6) return ;;
        *) echo "Invalid option"; return ;;
    esac

    config_set "swarm_aggregator_provider" "$SWARM_AGGREGATOR_PROVIDER"
    config_set "swarm_aggregator_model" "$SWARM_AGGREGATOR_MODEL"
    success "Aggregator model set to: $SWARM_AGGREGATOR_PROVIDER/$SWARM_AGGREGATOR_MODEL"
    sleep 1
}

#──────────────────────────────────────────────────────────────
# Worker count
#──────────────────────────────────────────────────────────────

menu_swarm_worker_count() {
    clear
    echo "SET NUMBER OF PARALLEL WORKERS"
    echo ""
    echo "Recommended:"
    if is_termux; then
        echo "  - Mobile: 2-3 workers (battery-friendly)"
    else
        echo "  - Desktop: 5-10 workers"
    fi
    echo ""
    echo "Current: $SWARM_WORKERS"
    echo ""

    read -p "Enter worker count (1-20): " count

    if [[ "$count" =~ ^[0-9]+$ ]] && (( count >= 1 && count <= 20 )); then
        SWARM_WORKERS=$count
        config_set "swarm_workers" "$SWARM_WORKERS"
        success "Worker count set to: $SWARM_WORKERS"
    else
        error "Invalid count"
    fi
    sleep 1
}

#──────────────────────────────────────────────────────────────
# Memory backend
#──────────────────────────────────────────────────────────────

menu_swarm_memory_backend() {
    clear
    echo "═══════════════════════════════════════════════════"
    echo "      SELECT MEMORY BACKEND"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "  1. SQLite (Lightweight, 5-30MB)"
    if is_termux; then
        echo "     ✓ Pre-installed on Termux"
    fi
    echo ""
    echo "  2. ChromaDB (Full vector search, 30-300MB)"
    echo "     Requires: pip install chromadb"
    echo ""
    echo "  3. Back"
    echo ""

    read -p "Select backend (1-3): " choice

    case "$choice" in
        1) SWARM_MEMORY_BACKEND="sqlite" ;;
        2) SWARM_MEMORY_BACKEND="chromadb" ;;
        3) return ;;
        *) echo "Invalid option"; return ;;
    esac

    config_set "swarm_memory_backend" "$SWARM_MEMORY_BACKEND"
    info "Memory backend set to: $SWARM_MEMORY_BACKEND"
    sleep 1
}

#──────────────────────────────────────────────────────────────
# Toggle swarm mode
#──────────────────────────────────────────────────────────────

swarm_toggle() {
    if [ "$SWARM_ENABLED" = true ]; then
        SWARM_ENABLED=false
        config_set "swarm_enabled" "false"
        info "Swarm mode DISABLED"
    else
        SWARM_ENABLED=true
        config_set "swarm_enabled" "true"
        success "Swarm mode ENABLED 🐝"
    fi
    sleep 1
}

#──────────────────────────────────────────────────────────────
# Main swarm execution (called from mode_run)
#──────────────────────────────────────────────────────────────

swarm_execute() {
    local prompt="$1"
    local context="$2"
    local mode="$3"

    info "🐝 Swarm mode active..."

    # Auto-detect strategy if set to "auto"
    if [ "$SWARM_STRATEGY" = "auto" ]; then
        SWARM_STRATEGY=$(swarm_auto_detect "$context")
        info "Auto-selected strategy: $SWARM_STRATEGY"
    fi

    # Execute based on strategy
    case "$SWARM_STRATEGY" in
        rag)
            swarm_rag_execute "$prompt" "$context" "$mode"
            ;;
        mapreduce)
            swarm_mapreduce_execute "$prompt" "$context" "$mode"
            ;;
        hierarchical)
            swarm_hierarchical_execute "$prompt" "$context" "$mode"
            ;;
        *)
            error "Unknown swarm strategy: $SWARM_STRATEGY"
            return 1
            ;;
    esac
}

#──────────────────────────────────────────────────────────────
# Auto-detect best strategy
#──────────────────────────────────────────────────────────────

swarm_auto_detect() {
    local context="$1"
    local tokens=$(estimate_tokens "$context")

    # Check if RAG index exists
    if swarm_rag_is_indexed; then
        echo "rag"
        return
    fi

    # Small context - no swarm needed
    if (( tokens < 10000 )); then
        warn "Context is small ($tokens tokens), swarm not needed"
        SWARM_ENABLED=false
        echo "none"
        return
    fi

    # Medium context on mobile - use hierarchical
    if is_termux && (( tokens < 50000 )); then
        echo "hierarchical"
        return
    fi

    # Large context on desktop - map-reduce
    if ! is_termux && (( tokens > 50000 )); then
        echo "mapreduce"
        return
    fi

    # Default: hierarchical (safest, works everywhere)
    echo "hierarchical"
}

#──────────────────────────────────────────────────────────────
# Utility: Check if running on Termux
#──────────────────────────────────────────────────────────────

is_termux() {
    [[ -n "$TERMUX_VERSION" ]] || [[ "$PREFIX" == *"com.termux"* ]]
}

#──────────────────────────────────────────────────────────────
# Load swarm configuration from config.json
#──────────────────────────────────────────────────────────────

swarm_load_config() {
    SWARM_ENABLED=$(config_get "swarm_enabled" "false")
    SWARM_STRATEGY=$(config_get "swarm_strategy" "auto")
    SWARM_WORKER_PROVIDER=$(config_get "swarm_worker_provider" "gemini")
    SWARM_WORKER_MODEL=$(config_get "swarm_worker_model" "2.5-flash")
    SWARM_AGGREGATOR_PROVIDER=$(config_get "swarm_aggregator_provider" "claude")
    SWARM_AGGREGATOR_MODEL=$(config_get "swarm_aggregator_model" "3.5-haiku")
    SWARM_WORKERS=$(config_get "swarm_workers" "5")
    SWARM_MEMORY_BACKEND=$(config_get "swarm_memory_backend" "sqlite")
}

# Load config on source
swarm_load_config
```

---

## Integration with Existing Modes

### Modified: lib/modes.sh

```bash
# Add to mode menu (inside mode_make, mode_tweak, mode_debug)

menu_mode_main() {
    while true; do
        clear
        echo "═══════════════════════════════════════════════════"
        echo "      ${MODE_NAME} MODE"
        echo "═══════════════════════════════════════════════════"
        echo ""
        echo "  Prompt:       ${MODE_PROMPT:-Not set}"
        echo "  Instructions: ${MODE_INSTRUCT_FILE:-None}"
        echo "  Context:      ${#MODE_UPLOADS[@]} items"
        echo "  Model:        ${MODE_MODEL_PROVIDER}/${MODE_MODEL_NAME}"
        echo "  Verification: ${MODE_CHECK_PROVIDER:-None}"
        echo "  🐝 Swarm:      $([ "$SWARM_ENABLED" = true ] && echo "✓ ON ($SWARM_STRATEGY)" || echo "OFF")"  # NEW
        echo ""
        echo "───────────────────────────────────────────────────"
        echo "  1. Set prompt"
        echo "  2. Set instruction file"
        echo "  3. Upload context"
        echo "  4. Select model"
        echo "  5. Verification (optional)"
        echo "  6. 🐝 Swarm Mode"  # NEW
        echo "───────────────────────────────────────────────────"
        echo "  7. Run"
        echo "  8. Back to main menu"
        echo ""

        read -p "Select option (1-8): " choice

        case "$choice" in
            1) menu_set_prompt ;;
            2) menu_set_instruct_file ;;
            3) menu_upload_context ;;
            4) menu_select_model ;;
            5) menu_verification ;;
            6) menu_swarm_config ;;  # NEW
            7) mode_run; break ;;
            8) return ;;
            *) echo "Invalid option" ;;
        esac
    done
}

# Modified mode_run to check for swarm
mode_run() {
    # ... existing context assembly code ...

    # Check if swarm mode is enabled
    if [ "$SWARM_ENABLED" = true ]; then
        # Execute with swarm
        result=$(swarm_execute "$final_prompt" "$context" "$MODE_CURRENT")
    else
        # Standard single-model execution
        result=$(call_api "$final_prompt" "$MODE_MODEL_PROVIDER" "$MODE_MODEL_NAME")
    fi

    # ... rest of execution ...
}
```

---

## Visual Workflow

### Standard Mode (Swarm OFF)

```
User Input → Assemble Context → Single Model → Output
```

### Swarm Mode (Map-Reduce)

```
                    ┌─ Worker 1 (Gemini Flash) → Summary 1
                    │
User Input → Split ├─ Worker 2 (Gemini Flash) → Summary 2
   into chunks     │
                    ├─ Worker 3 (Gemini Flash) → Summary 3
                    │
                    └─ Worker N (Gemini Flash) → Summary N
                                │
                                └──→ Aggregator (Claude Sonnet) → Final Output
```

### Swarm Mode (RAG)

```
User Input → Vector Search (local, <100ms) → Top 5 chunks → Worker (Gemini) → Output
```

### Swarm Mode (Hierarchical)

```
User Input → SQLite Query (L4→L3→L2) → Relevant files → Worker → Output
```

---

## Cost Estimation Display

When swarm is enabled, show detailed cost breakdown:

```
═══════════════════════════════════════════════════
      ESTIMATED COST (SWARM MODE: MAP-REDUCE)
═══════════════════════════════════════════════════

  Context: 125,000 tokens
  Strategy: Split into 50 chunks of 2,500 tokens

  Phase 1 - Parallel Workers (50 workers):
    Model: gemini/2.5-flash
    Input:  50 × 2,500 = 125,000 tokens
    Output: 50 × 200   = 10,000 tokens
    Cost:   $0.0155

  Phase 2 - Aggregation (1 call):
    Model: claude/3.5-haiku
    Input:  10,000 tokens
    Output: 1,000 tokens
    Cost:   $0.015

  Total Estimated Cost: $0.0305
  Estimated Time: 2-3 minutes (5 parallel workers)

  Without swarm (single call): Would FAIL (exceeds context)

  Proceed? (yes/no):
```

---

## Status Messages During Execution

```bash
🐝 Swarm mode active...
📊 Strategy: map-reduce
🔧 Worker model: gemini/2.5-flash
🎯 Aggregator: claude/3.5-haiku

Phase 1: Chunking codebase...
  ✓ Created 50 chunks (avg 2,500 tokens each)

Phase 2: Launching workers (5 parallel)...
  [████████████████░░░░] 80% (40/50 chunks processed)
  Worker 1: Processing chunk 41...
  Worker 2: Processing chunk 42...
  Worker 3: Processing chunk 43...
  Worker 4: Processing chunk 44...
  Worker 5: Processing chunk 45...

Phase 3: Aggregating results...
  ✓ Combined 50 summaries
  ✓ Generated final output

✓ Complete! Total time: 2m 14s
```

---

## Configuration File Updates

### config.json (new fields)

```json
{
  "version": "2.0.0",
  "workspace": "/path/to/workspace",
  "model_provider": "gemini",
  "model_name": "2.5-flash",

  "swarm": {
    "enabled": false,
    "strategy": "auto",
    "worker_provider": "gemini",
    "worker_model": "2.5-flash",
    "aggregator_provider": "claude",
    "aggregator_model": "3.5-haiku",
    "workers": 5,
    "memory_backend": "sqlite"
  }
}
```

---

## Summary

### New Commands

```bash
# Swarm management
aiwb swarm enable          # Enable swarm mode
aiwb swarm disable         # Disable swarm mode
aiwb swarm config          # Configure swarm
aiwb swarm status          # Show swarm status

# RAG-specific
aiwb swarm index           # Index workspace for RAG
aiwb swarm reindex         # Rebuild RAG index
aiwb swarm search "query"  # Test RAG search

# Hierarchical-specific
aiwb swarm build-hierarchy # Build summary pyramid
aiwb swarm update-hierarchy # Update changed files
```

### New Files

```
lib/swarm.sh              - Core swarm logic & menus
lib/swarm_rag.sh          - RAG implementation
lib/swarm_mapreduce.sh    - Map-Reduce implementation
lib/swarm_hierarchical.sh - Hierarchical implementation
```

### Implementation Effort

- **Core swarm.sh**: 2-3 days
- **RAG module**: 2 days
- **Map-Reduce module**: 1 day
- **Hierarchical module**: 1 day
- **Menu integration**: 1 day
- **Testing & docs**: 2 days

**Total**: ~9-10 days for full implementation

---

This design makes it crystal clear to users that they're using multiple agents, gives them full control over the configuration, and provides real-time feedback during execution.
