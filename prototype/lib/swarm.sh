#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# AIWB Swarm Mode - Multi-Agent Processing
# ═══════════════════════════════════════════════════════════════════════════

# Global swarm configuration
SWARM_ENABLED=false
SWARM_STRATEGY="auto"
SWARM_WORKER_PROVIDER="gemini"
SWARM_WORKER_MODEL="2.5-flash"
SWARM_AGGREGATOR_PROVIDER="claude"
SWARM_AGGREGATOR_MODEL="3.5-haiku"
SWARM_WORKERS=5
SWARM_MEMORY_BACKEND="sqlite"

#──────────────────────────────────────────────────────────────
# Main swarm configuration menu
#──────────────────────────────────────────────────────────────

menu_swarm_config() {
    while true; do
        clear
        cat <<EOF
═══════════════════════════════════════════════════
      🐝 SWARM MODE CONFIGURATION
═══════════════════════════════════════════════════

  Status: $([ "$SWARM_ENABLED" = true ] && echo "✓ ENABLED" || echo "✗ DISABLED")

  Strategy:         $SWARM_STRATEGY
  Worker Model:     $SWARM_WORKER_PROVIDER/$SWARM_WORKER_MODEL
  Aggregator Model: $SWARM_AGGREGATOR_PROVIDER/$SWARM_AGGREGATOR_MODEL
  Parallel Workers: $SWARM_WORKERS
  Memory Backend:   $SWARM_MEMORY_BACKEND

───────────────────────────────────────────────────
  1. Change Strategy
  2. Select Worker Model
  3. Select Aggregator Model
  4. Set Worker Count
  5. Change Memory Backend
───────────────────────────────────────────────────
  6. $([ "$SWARM_ENABLED" = true ] && echo "Disable" || echo "Enable") Swarm Mode
  7. Back to Mode Menu

EOF

        read -p "Select option (1-7): " choice

        case "$choice" in
            1) menu_swarm_strategy ;;
            2) menu_swarm_worker_model ;;
            3) menu_swarm_aggregator_model ;;
            4) menu_swarm_worker_count ;;
            5) menu_swarm_memory_backend ;;
            6) swarm_toggle ;;
            7) return ;;
            *) echo "Invalid option"; sleep 1 ;;
        esac
    done
}

#──────────────────────────────────────────────────────────────
# Strategy selection menu
#──────────────────────────────────────────────────────────────

menu_swarm_strategy() {
    clear
    cat <<EOF
═══════════════════════════════════════════════════
      SELECT SWARM STRATEGY
═══════════════════════════════════════════════════

  1. 🤖 Auto (Recommended)
     Let AIWB choose based on context size and platform

  2. 🔍 RAG (Retrieval-Augmented Generation)
     Best for: Repeated queries, semantic search
     Speed: < 1 second per query
     Setup: 5-10 min one-time indexing
$(is_termux && echo "     ⚠️  Heavy on mobile (300MB, battery drain)")

  3. 📊 Map-Reduce (Parallel Processing)
     Best for: One-time deep analysis
     Speed: 2-5 minutes for 100K LOC
     Setup: None required

  4. 🏗️  Hierarchical (Summary Pyramid)
     Best for: Termux/mobile, battery-friendly
     Speed: 5-10 seconds per query
     Setup: 30-60 min battery-safe indexing
$(is_termux && echo "     ✓ Recommended for mobile!")

  5. Back

EOF

    read -p "Select strategy (1-5): " choice

    case "$choice" in
        1) SWARM_STRATEGY="auto" ;;
        2) SWARM_STRATEGY="rag" ;;
        3) SWARM_STRATEGY="mapreduce" ;;
        4) SWARM_STRATEGY="hierarchical" ;;
        5) return ;;
        *) echo "Invalid option"; sleep 1; return ;;
    esac

    config_set "swarm_strategy" "$SWARM_STRATEGY"
    echo "✓ Strategy set to: $SWARM_STRATEGY"
    sleep 1
}

#──────────────────────────────────────────────────────────────
# Worker model selection menu
#──────────────────────────────────────────────────────────────

menu_swarm_worker_model() {
    clear
    cat <<EOF
═══════════════════════════════════════════════════
      SELECT WORKER MODEL (for parallel tasks)
═══════════════════════════════════════════════════

  Workers process chunks in parallel.
  Use CHEAP, FAST models!

  Recommended:
  1. gemini/2.5-flash      (\$0.10/1M tokens) ⭐
  2. gemini/2.0-flash-lite (\$0.05/1M tokens) ⭐⭐
  3. groq/llama-3.3-70b    (\$0.59/1M tokens)
  4. claude/3.5-haiku      (\$1.00/1M tokens)

  5. Custom provider/model
  6. Back

EOF

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
        *) echo "Invalid option"; sleep 1; return ;;
    esac

    config_set "swarm_worker_provider" "$SWARM_WORKER_PROVIDER"
    config_set "swarm_worker_model" "$SWARM_WORKER_MODEL"
    echo "✓ Worker model set to: $SWARM_WORKER_PROVIDER/$SWARM_WORKER_MODEL"
    sleep 1
}

#──────────────────────────────────────────────────────────────
# Aggregator model selection menu
#──────────────────────────────────────────────────────────────

menu_swarm_aggregator_model() {
    clear
    cat <<EOF
═══════════════════════════════════════════════════
      SELECT AGGREGATOR MODEL (for final synthesis)
═══════════════════════════════════════════════════

  Aggregator combines results from workers.
  Use BETTER, more capable models.

  Recommended:
  1. claude/3.5-sonnet    (\$3.00/1M tokens) ⭐⭐
  2. claude/3.5-haiku     (\$1.00/1M tokens) ⭐
  3. gemini/2.5-flash     (\$0.10/1M tokens)
  4. openai/gpt-4o        (\$2.50/1M tokens)

  5. Custom provider/model
  6. Back

EOF

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
        *) echo "Invalid option"; sleep 1; return ;;
    esac

    config_set "swarm_aggregator_provider" "$SWARM_AGGREGATOR_PROVIDER"
    config_set "swarm_aggregator_model" "$SWARM_AGGREGATOR_MODEL"
    echo "✓ Aggregator model set to: $SWARM_AGGREGATOR_PROVIDER/$SWARM_AGGREGATOR_MODEL"
    sleep 1
}

#──────────────────────────────────────────────────────────────
# Worker count configuration
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
        echo "✓ Worker count set to: $SWARM_WORKERS"
    else
        echo "✗ Invalid count"
    fi
    sleep 1
}

#──────────────────────────────────────────────────────────────
# Memory backend selection
#──────────────────────────────────────────────────────────────

menu_swarm_memory_backend() {
    clear
    cat <<EOF
═══════════════════════════════════════════════════
      SELECT MEMORY BACKEND
═══════════════════════════════════════════════════

  1. SQLite (Lightweight, 5-30MB)
$(is_termux && echo "     ✓ Pre-installed on Termux")

  2. ChromaDB (Full vector search, 30-300MB)
     Requires: pip install chromadb

  3. Back

EOF

    read -p "Select backend (1-3): " choice

    case "$choice" in
        1) SWARM_MEMORY_BACKEND="sqlite" ;;
        2) SWARM_MEMORY_BACKEND="chromadb" ;;
        3) return ;;
        *) echo "Invalid option"; sleep 1; return ;;
    esac

    config_set "swarm_memory_backend" "$SWARM_MEMORY_BACKEND"
    echo "✓ Memory backend set to: $SWARM_MEMORY_BACKEND"
    sleep 1
}

#──────────────────────────────────────────────────────────────
# Toggle swarm on/off
#──────────────────────────────────────────────────────────────

swarm_toggle() {
    if [ "$SWARM_ENABLED" = true ]; then
        SWARM_ENABLED=false
        config_set "swarm_enabled" "false"
        echo "✗ Swarm mode DISABLED"
    else
        SWARM_ENABLED=true
        config_set "swarm_enabled" "true"
        echo "✓ Swarm mode ENABLED 🐝"
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

    echo "🐝 Swarm mode active..."
    echo "📊 Strategy: $SWARM_STRATEGY"
    echo "🔧 Worker model: $SWARM_WORKER_PROVIDER/$SWARM_WORKER_MODEL"
    echo "🎯 Aggregator: $SWARM_AGGREGATOR_PROVIDER/$SWARM_AGGREGATOR_MODEL"
    echo ""

    # Auto-detect strategy if set to "auto"
    if [ "$SWARM_STRATEGY" = "auto" ]; then
        local detected_strategy=$(swarm_auto_detect "$context")
        echo "🤖 Auto-detected strategy: $detected_strategy"
        SWARM_STRATEGY="$detected_strategy"
    fi

    # Execute based on strategy
    case "$SWARM_STRATEGY" in
        rag)
            echo "🔍 Using RAG (Retrieval-Augmented Generation)..."
            swarm_rag_execute "$prompt" "$context" "$mode"
            ;;
        mapreduce)
            echo "📊 Using Map-Reduce (Parallel Processing)..."
            swarm_mapreduce_execute "$prompt" "$context" "$mode"
            ;;
        hierarchical)
            echo "🏗️  Using Hierarchical (Summary Pyramid)..."
            swarm_hierarchical_execute "$prompt" "$context" "$mode"
            ;;
        none)
            echo "ℹ️  Context too small for swarm, using standard mode"
            call_api "$prompt" "$MODE_MODEL_PROVIDER" "$MODE_MODEL_NAME"
            ;;
        *)
            echo "✗ Unknown swarm strategy: $SWARM_STRATEGY"
            return 1
            ;;
    esac
}

#──────────────────────────────────────────────────────────────
# Auto-detect best strategy based on context
#──────────────────────────────────────────────────────────────

swarm_auto_detect() {
    local context="$1"
    local tokens=$(estimate_tokens "$context")

    echo "ℹ️  Context size: $tokens tokens" >&2

    # Check if RAG index exists
    if swarm_rag_is_indexed 2>/dev/null; then
        echo "rag"
        return
    fi

    # Small context - no swarm needed
    if (( tokens < 10000 )); then
        echo "⚠️  Context is small ($tokens tokens), swarm not needed" >&2
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
# Utilities
#──────────────────────────────────────────────────────────────

is_termux() {
    [[ -n "$TERMUX_VERSION" ]] || [[ "$PREFIX" == *"com.termux"* ]]
}

estimate_tokens() {
    local text="$1"
    echo $(( ${#text} / 4 ))
}

#──────────────────────────────────────────────────────────────
# Placeholder functions (to be implemented in separate modules)
#──────────────────────────────────────────────────────────────

swarm_rag_execute() {
    echo "RAG execution (to be implemented in lib/swarm_rag.sh)"
}

swarm_mapreduce_execute() {
    echo "Map-Reduce execution (to be implemented in lib/swarm_mapreduce.sh)"
}

swarm_hierarchical_execute() {
    echo "Hierarchical execution (to be implemented in lib/swarm_hierarchical.sh)"
}

swarm_rag_is_indexed() {
    # Check if RAG index exists
    [[ -f "$HOME/.aiwb/rag_db/chroma.sqlite3" ]] || \
    [[ -f "$HOME/.aiwb/embeddings.db" ]]
}

config_get() {
    # Placeholder - actual implementation in lib/config.sh
    echo "${2:-}"
}

config_set() {
    # Placeholder - actual implementation in lib/config.sh
    true
}

call_api() {
    # Placeholder - actual implementation in lib/api.sh
    echo "API call: $1"
}

#──────────────────────────────────────────────────────────────
# Load swarm configuration from config.json on startup
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

# Load config when this module is sourced
swarm_load_config

echo "✓ Swarm module loaded (status: $([ "$SWARM_ENABLED" = true ] && echo "enabled" || echo "disabled"))"
