#!/usr/bin/env bash
# swarm.sh - Multi-agent swarm mode for large codebase processing

[[ -z "${AIWB_LIB_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[[ -z "${AIWB_LIB_CONFIG_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
[[ -z "${AIWB_LIB_UI_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"
[[ -z "${AIWB_LIB_API_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/api.sh"

# ============================================================================
# SWARM STATE MANAGEMENT
# ============================================================================

# Global swarm configuration
SWARM_ENABLED=false
SWARM_STRATEGY="auto"
SWARM_WORKER_PROVIDER="gemini"
SWARM_WORKER_MODEL="2.5-flash"
SWARM_AGGREGATOR_PROVIDER="claude"
SWARM_AGGREGATOR_MODEL="3.5-haiku"
SWARM_WORKERS=5

# Initialize swarm from config
swarm_init() {
    SWARM_ENABLED=$(config_get "swarm.enabled" "false")
    SWARM_STRATEGY=$(config_get "swarm.strategy" "auto")
    SWARM_WORKER_PROVIDER=$(config_get "swarm.worker_provider" "gemini")
    SWARM_WORKER_MODEL=$(config_get "swarm.worker_model" "2.5-flash")
    SWARM_AGGREGATOR_PROVIDER=$(config_get "swarm.aggregator_provider" "claude")
    SWARM_AGGREGATOR_MODEL=$(config_get "swarm.aggregator_model" "3.5-haiku")
    SWARM_WORKERS=$(config_get "swarm.workers" "5")
}

# Get swarm display
get_swarm_display() {
    if [[ "$SWARM_ENABLED" = "true" ]]; then
        echo "🐝 ON ($SWARM_STRATEGY, ${SWARM_WORKERS} workers)"
    else
        echo "OFF"
    fi
}

# ============================================================================
# SWARM MENU
# ============================================================================

menu_swarm() {
    while true; do
        local status_display
        if [[ "$SWARM_ENABLED" = "true" ]]; then
            status_display="✓ ENABLED"
        else
            status_display="✗ DISABLED"
        fi

        local choice
        choice=$(ui_choose "🐝 Swarm Mode ($status_display)" \
            "Strategy: $SWARM_STRATEGY" \
            "Worker model: $SWARM_WORKER_PROVIDER/$SWARM_WORKER_MODEL" \
            "Aggregator model: $SWARM_AGGREGATOR_PROVIDER/$SWARM_AGGREGATOR_MODEL" \
            "Worker count: $SWARM_WORKERS" \
            "$([ "$SWARM_ENABLED" = "true" ] && echo "Disable" || echo "Enable") swarm" \
            "Back")

        case "$choice" in
            "Strategy:"*)
                menu_swarm_strategy
                ;;
            "Worker model:"*)
                menu_swarm_worker_model
                ;;
            "Aggregator model:"*)
                menu_swarm_aggregator_model
                ;;
            "Worker count:"*)
                menu_swarm_workers
                ;;
            *"swarm")
                swarm_toggle
                ;;
            "Back"|"")
                return 0
                ;;
        esac
    done
}

# Strategy selection submenu
menu_swarm_strategy() {
    local current_strategy="$SWARM_STRATEGY"

    local choice
    choice=$(ui_choose "Select Swarm Strategy" \
        "auto - Let AIWB choose (Recommended)" \
        "mapreduce - Parallel processing" \
        "hierarchical - Battery-friendly (mobile)" \
        "Back")

    case "$choice" in
        "auto"*)
            SWARM_STRATEGY="auto"
            ;;
        "mapreduce"*)
            SWARM_STRATEGY="mapreduce"
            ;;
        "hierarchical"*)
            SWARM_STRATEGY="hierarchical"
            ;;
        "Back"|"")
            return 0
            ;;
    esac

    if [[ "$SWARM_STRATEGY" != "$current_strategy" ]]; then
        config_set "swarm.strategy" "$SWARM_STRATEGY"
        success "Strategy set to: $SWARM_STRATEGY"
    fi
}

# Worker model selection
menu_swarm_worker_model() {
    local choice
    choice=$(ui_choose "Select Worker Model (for parallel tasks)" \
        "gemini/2.5-flash (\$0.10/1M) ⭐" \
        "gemini/2.0-flash-lite (\$0.05/1M) ⭐⭐" \
        "groq/llama-3.3-70b (\$0.59/1M)" \
        "claude/3.5-haiku (\$1.00/1M)" \
        "Back")

    case "$choice" in
        "gemini/2.5-flash"*)
            SWARM_WORKER_PROVIDER="gemini"
            SWARM_WORKER_MODEL="2.5-flash"
            ;;
        "gemini/2.0-flash-lite"*)
            SWARM_WORKER_PROVIDER="gemini"
            SWARM_WORKER_MODEL="2.0-flash-lite"
            ;;
        "groq/llama-3.3-70b"*)
            SWARM_WORKER_PROVIDER="groq"
            SWARM_WORKER_MODEL="llama-3.3-70b"
            ;;
        "claude/3.5-haiku"*)
            SWARM_WORKER_PROVIDER="claude"
            SWARM_WORKER_MODEL="3.5-haiku"
            ;;
        "Back"|"")
            return 0
            ;;
    esac

    config_set "swarm.worker_provider" "$SWARM_WORKER_PROVIDER"
    config_set "swarm.worker_model" "$SWARM_WORKER_MODEL"
    success "Worker model set to: $SWARM_WORKER_PROVIDER/$SWARM_WORKER_MODEL"
}

# Aggregator model selection
menu_swarm_aggregator_model() {
    local choice
    choice=$(ui_choose "Select Aggregator Model (for final synthesis)" \
        "claude/3.5-sonnet (\$3.00/1M) ⭐⭐" \
        "claude/3.5-haiku (\$1.00/1M) ⭐" \
        "gemini/2.5-flash (\$0.10/1M)" \
        "openai/gpt-4o (\$2.50/1M)" \
        "Back")

    case "$choice" in
        "claude/3.5-sonnet"*)
            SWARM_AGGREGATOR_PROVIDER="claude"
            SWARM_AGGREGATOR_MODEL="3.5-sonnet"
            ;;
        "claude/3.5-haiku"*)
            SWARM_AGGREGATOR_PROVIDER="claude"
            SWARM_AGGREGATOR_MODEL="3.5-haiku"
            ;;
        "gemini/2.5-flash"*)
            SWARM_AGGREGATOR_PROVIDER="gemini"
            SWARM_AGGREGATOR_MODEL="2.5-flash"
            ;;
        "openai/gpt-4o"*)
            SWARM_AGGREGATOR_PROVIDER="openai"
            SWARM_AGGREGATOR_MODEL="gpt-4o"
            ;;
        "Back"|"")
            return 0
            ;;
    esac

    config_set "swarm.aggregator_provider" "$SWARM_AGGREGATOR_PROVIDER"
    config_set "swarm.aggregator_model" "$SWARM_AGGREGATOR_MODEL"
    success "Aggregator model set to: $SWARM_AGGREGATOR_PROVIDER/$SWARM_AGGREGATOR_MODEL"
}

# Worker count configuration
menu_swarm_workers() {
    local count
    count=$(ui_input "Enter number of parallel workers (1-20):")

    if [[ "$count" =~ ^[0-9]+$ ]] && (( count >= 1 && count <= 20 )); then
        SWARM_WORKERS=$count
        config_set "swarm.workers" "$SWARM_WORKERS"
        success "Worker count set to: $SWARM_WORKERS"
    else
        err "Invalid count. Must be between 1 and 20."
    fi
}

# Toggle swarm on/off
swarm_toggle() {
    if [[ "$SWARM_ENABLED" = "true" ]]; then
        SWARM_ENABLED="false"
        config_set "swarm.enabled" "false"
        msg "Swarm mode DISABLED"
    else
        SWARM_ENABLED="true"
        config_set "swarm.enabled" "true"
        success "Swarm mode ENABLED 🐝"
    fi
}

# ============================================================================
# SWARM EXECUTION
# ============================================================================

# Main swarm execution entry point
swarm_execute() {
    local prompt="$1"
    local mode="$2"

    echo ""
    ui_header "🐝 Swarm Mode Execution"
    echo ""
    msg "DEBUG: swarm_execute called with mode=$mode"
    msg "DEBUG: Prompt length: ${#prompt} characters"

    # Auto-detect strategy if set to auto
    local strategy="$SWARM_STRATEGY"
    msg "DEBUG: Current SWARM_STRATEGY=$SWARM_STRATEGY"
    if [[ "$strategy" = "auto" ]]; then
        strategy=$(swarm_auto_detect "$prompt")
        msg "Auto-detected strategy: $strategy"
    fi

    msg "Strategy: $strategy"
    msg "Workers: $SWARM_WORKERS × $SWARM_WORKER_PROVIDER/$SWARM_WORKER_MODEL"
    msg "Aggregator: $SWARM_AGGREGATOR_PROVIDER/$SWARM_AGGREGATOR_MODEL"
    echo ""

    # Execute based on strategy
    case "$strategy" in
        mapreduce)
            swarm_mapreduce "$prompt" "$mode"
            ;;
        hierarchical)
            swarm_hierarchical "$prompt" "$mode"
            ;;
        none)
            warn "Context too small for swarm, using standard mode"
            return 1  # Fall back to standard execution
            ;;
        *)
            err "Unknown strategy: $strategy"
            return 1
            ;;
    esac
}

# Auto-detect best strategy
swarm_auto_detect() {
    local prompt="$1"
    local tokens=$(estimate_tokens "$prompt")

    # Small context - no swarm needed
    if (( tokens < 10000 )); then
        echo "none"
        return
    fi

    # Default to map-reduce for now (hierarchical requires SQLite setup)
    echo "mapreduce"
}

# ============================================================================
# MAP-REDUCE IMPLEMENTATION
# ============================================================================

swarm_mapreduce() {
    local prompt="$1"
    local mode="$2"

    msg "DEBUG: Estimating tokens for prompt..."
    local tokens=$(estimate_tokens "$prompt")
    msg "DEBUG: Estimated tokens: $tokens"

    local chunk_size=2500  # tokens per chunk
    local num_chunks=$(( (tokens + chunk_size - 1) / chunk_size ))
    msg "DEBUG: Calculated $num_chunks chunks (chunk_size=$chunk_size)"

    # If only 1-2 chunks, not worth the overhead
    if (( num_chunks <= 2 )); then
        warn "Prompt small enough for standard mode ($num_chunks chunks)"
        warn "DEBUG: tokens=$tokens, num_chunks=$num_chunks"
        return 1
    fi

    msg "Splitting prompt into $num_chunks chunks..."

    # Split prompt into chunks (simple line-based splitting for now)
    local -a chunks=()
    local lines_per_chunk=$(( $(echo "$prompt" | wc -l) / num_chunks ))

    local temp_file=$(mktemp)
    echo "$prompt" > "$temp_file"

    for (( i=0; i<num_chunks; i++ )); do
        local start_line=$(( i * lines_per_chunk + 1 ))
        local end_line=$(( (i + 1) * lines_per_chunk ))

        if (( i == num_chunks - 1 )); then
            # Last chunk gets everything remaining
            chunks[$i]=$(sed -n "${start_line},\$p" "$temp_file")
        else
            chunks[$i]=$(sed -n "${start_line},${end_line}p" "$temp_file")
        fi
    done

    rm -f "$temp_file"

    # Phase 1: Process chunks in parallel
    echo ""
    msg "Phase 1: Processing $num_chunks chunks with $SWARM_WORKERS workers..."
    echo ""

    local -a summaries=()
    local processed=0
    local total=$num_chunks

    for (( i=0; i<num_chunks; i++ )); do
        # Wait if we've hit max parallel workers
        while (( $(jobs -r | wc -l) >= SWARM_WORKERS )); do
            sleep 0.5
        done

        # Process chunk in background
        (
            local chunk_num=$((i + 1))
            local chunk_prompt="Summarize this code chunk ($chunk_num/$total):

${chunks[$i]}"

            local summary=$(call_api "$chunk_prompt" "$SWARM_WORKER_PROVIDER" "$SWARM_WORKER_MODEL")
            echo "$summary" > "/tmp/swarm_chunk_$i.txt"
        ) &

        msg "Worker launched for chunk $((i + 1))/$num_chunks"
    done

    # Wait for all workers to complete
    msg "Waiting for all workers to complete..."
    wait

    # Collect summaries
    for (( i=0; i<num_chunks; i++ )); do
        if [[ -f "/tmp/swarm_chunk_$i.txt" ]]; then
            summaries[$i]=$(cat "/tmp/swarm_chunk_$i.txt")
            rm -f "/tmp/swarm_chunk_$i.txt"
        fi
    done

    success "Phase 1 complete: $num_chunks chunks processed"
    echo ""

    # Phase 2: Aggregate results
    msg "Phase 2: Aggregating results with $SWARM_AGGREGATOR_PROVIDER/$SWARM_AGGREGATOR_MODEL..."
    echo ""

    local combined_summaries=""
    for (( i=0; i<num_chunks; i++ )); do
        combined_summaries="$combined_summaries

=== Chunk $((i + 1)) Summary ===
${summaries[$i]}"
    done

    local aggregation_prompt="Based on these code chunk summaries, provide a comprehensive ${mode} response:

$combined_summaries

Provide the final ${mode} output:"

    ui_blink "Aggregating with $SWARM_AGGREGATOR_PROVIDER..."
    local final_output=$(call_api "$aggregation_prompt" "$SWARM_AGGREGATOR_PROVIDER" "$SWARM_AGGREGATOR_MODEL")
    ui_clear_line

    echo ""
    success "Phase 2 complete: Results aggregated"
    echo ""

    # Return the final output
    echo "$final_output"
}

# ============================================================================
# HIERARCHICAL IMPLEMENTATION (Placeholder)
# ============================================================================

swarm_hierarchical() {
    local prompt="$1"
    local mode="$2"

    warn "Hierarchical strategy not yet implemented"
    warn "Falling back to standard mode"
    return 1
}

# ============================================================================
# SWARM COST ESTIMATION
# ============================================================================

swarm_estimate_cost() {
    local prompt="$1"
    local strategy="$2"

    local total_cost="0"
    local phase1_cost="0"
    local phase2_cost="0"

    case "$strategy" in
        mapreduce)
            local tokens=$(estimate_tokens "$prompt")
            local chunk_size=2500
            local num_chunks=$(( (tokens + chunk_size - 1) / chunk_size ))

            if (( num_chunks <= 2 )); then
                echo "0"  # Will fall back to standard mode
                return
            fi

            # Phase 1: Worker costs
            local worker_input_tokens=$(( num_chunks * chunk_size ))
            local worker_output_tokens=$(( num_chunks * 200 ))  # ~200 tokens per summary
            phase1_cost=$(calculate_cost "$SWARM_WORKER_PROVIDER" "$SWARM_WORKER_MODEL" "$worker_input_tokens" "$worker_output_tokens")

            # Phase 2: Aggregator cost
            local agg_input_tokens=$worker_output_tokens
            local agg_output_tokens=$(( tokens / 2 ))  # Rough estimate
            phase2_cost=$(calculate_cost "$SWARM_AGGREGATOR_PROVIDER" "$SWARM_AGGREGATOR_MODEL" "$agg_input_tokens" "$agg_output_tokens")

            total_cost=$(awk "BEGIN {printf \"%.4f\", $phase1_cost + $phase2_cost}")
            ;;
        *)
            echo "0"
            return
            ;;
    esac

    echo "$total_cost"
}

# Display swarm cost breakdown
swarm_display_cost() {
    local prompt="$1"
    local strategy="$2"

    if [[ "$strategy" = "auto" ]]; then
        strategy=$(swarm_auto_detect "$prompt")
    fi

    local tokens=$(estimate_tokens "$prompt")
    local chunk_size=2500
    local num_chunks=$(( (tokens + chunk_size - 1) / chunk_size ))

    if [[ "$strategy" = "mapreduce" ]] && (( num_chunks > 2 )); then
        echo "Swarm Mode (Map-Reduce):"
        echo "  Strategy: Split into $num_chunks chunks"
        echo ""
        echo "  Phase 1 - Workers ($num_chunks × $SWARM_WORKER_PROVIDER/$SWARM_WORKER_MODEL):"
        local worker_input=$(( num_chunks * chunk_size ))
        local worker_output=$(( num_chunks * 200 ))
        local phase1_cost=$(calculate_cost "$SWARM_WORKER_PROVIDER" "$SWARM_WORKER_MODEL" "$worker_input" "$worker_output")
        echo "    Input tokens: $worker_input"
        echo "    Output tokens: $worker_output"
        echo "    Cost: \$${phase1_cost}"
        echo ""
        echo "  Phase 2 - Aggregator ($SWARM_AGGREGATOR_PROVIDER/$SWARM_AGGREGATOR_MODEL):"
        local agg_input=$worker_output
        local agg_output=$(( tokens / 2 ))
        local phase2_cost=$(calculate_cost "$SWARM_AGGREGATOR_PROVIDER" "$SWARM_AGGREGATOR_MODEL" "$agg_input" "$agg_output")
        echo "    Input tokens: $agg_input"
        echo "    Output tokens (est): $agg_output"
        echo "    Cost: \$${phase2_cost}"
        echo ""
        local total=$(awk "BEGIN {printf \"%.4f\", $phase1_cost + $phase2_cost}")
        echo "  Total swarm cost: \$${total}"
    else
        echo "Swarm not applicable (context too small)"
    fi
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Load swarm config on source
swarm_init

# Mark as loaded
export AIWB_LIB_SWARM_LOADED=1
