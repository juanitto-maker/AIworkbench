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
SWARM_AGGREGATOR_MODEL="sonnet-4-5-20250929"
SWARM_WORKERS=5
SWARM_MIN_TOKENS=100   # Minimum tokens to activate swarm (very low for easy testing)
SWARM_FORCE=false      # Force swarm mode regardless of token count

# Initialize swarm from config
swarm_init() {
    SWARM_ENABLED=$(config_get "swarm.enabled" "false")
    SWARM_STRATEGY=$(config_get "swarm.strategy" "auto")
    SWARM_WORKER_PROVIDER=$(config_get "swarm.worker_provider" "gemini")
    SWARM_WORKER_MODEL=$(config_get "swarm.worker_model" "2.5-flash")
    SWARM_AGGREGATOR_PROVIDER=$(config_get "swarm.aggregator_provider" "claude")
    SWARM_AGGREGATOR_MODEL=$(config_get "swarm.aggregator_model" "sonnet-4-5-20250929")
    SWARM_WORKERS=$(config_get "swarm.workers" "5")
    SWARM_MIN_TOKENS=$(config_get "swarm.min_tokens" "100")
    SWARM_FORCE=$(config_get "swarm.force" "false")

    # Export swarm config so background workers can access it
    export SWARM_ENABLED SWARM_STRATEGY
    export SWARM_WORKER_PROVIDER SWARM_WORKER_MODEL
    export SWARM_AGGREGATOR_PROVIDER SWARM_AGGREGATOR_MODEL
    export SWARM_WORKERS SWARM_MIN_TOKENS SWARM_FORCE

    # Load and export API keys for background workers
    local env_file
    env_file="$(get_env_file)"
    if [[ -f "$env_file" ]]; then
        source "$env_file"
        # Export all API keys so background workers can access them
        [[ -n "${GEMINI_API_KEY:-}" ]] && export GEMINI_API_KEY
        [[ -n "${ANTHROPIC_API_KEY:-}" ]] && export ANTHROPIC_API_KEY
        [[ -n "${OPENAI_API_KEY:-}" ]] && export OPENAI_API_KEY
        [[ -n "${GROQ_API_KEY:-}" ]] && export GROQ_API_KEY
        [[ -n "${XAI_API_KEY:-}" ]] && export XAI_API_KEY
    fi
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

        local force_display
        if [[ "$SWARM_FORCE" = "true" ]]; then
            force_display="(FORCED)"
        else
            force_display=""
        fi

        local choice
        choice=$(ui_choose "🐝 Swarm Mode ($status_display)" \
            "Strategy: $SWARM_STRATEGY" \
            "Worker model: $SWARM_WORKER_PROVIDER/$SWARM_WORKER_MODEL" \
            "Aggregator model: $SWARM_AGGREGATOR_PROVIDER/$SWARM_AGGREGATOR_MODEL" \
            "Worker count: $SWARM_WORKERS" \
            "Min tokens: $SWARM_MIN_TOKENS $force_display" \
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
            "Min tokens:"*)
                menu_swarm_min_tokens
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
            SWARM_WORKER_MODEL="llama-3.3-70b-versatile"
            ;;
        "claude/3.5-haiku"*)
            SWARM_WORKER_PROVIDER="claude"
            SWARM_WORKER_MODEL="3-haiku-20240307"
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
        "claude/sonnet-4.5 (\$3.00/1M) ⭐⭐ NEW" \
        "claude/3.5-sonnet (\$3.00/1M) ⭐⭐" \
        "claude/3.5-haiku (\$1.00/1M) ⭐" \
        "gemini/2.5-flash (\$0.10/1M)" \
        "openai/gpt-4o (\$2.50/1M)" \
        "Back")

    case "$choice" in
        "claude/sonnet-4.5"*)
            SWARM_AGGREGATOR_PROVIDER="claude"
            SWARM_AGGREGATOR_MODEL="sonnet-4-5-20250929"
            ;;
        "claude/3.5-sonnet"*)
            SWARM_AGGREGATOR_PROVIDER="claude"
            SWARM_AGGREGATOR_MODEL="3-5-sonnet-20240620"
            ;;
        "claude/3.5-haiku"*)
            SWARM_AGGREGATOR_PROVIDER="claude"
            SWARM_AGGREGATOR_MODEL="3-haiku-20240307"
            ;;
        "gemini/2.5-flash"*)
            SWARM_AGGREGATOR_PROVIDER="gemini"
            SWARM_AGGREGATOR_MODEL="2.0-flash-exp"
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

# Minimum tokens configuration
menu_swarm_min_tokens() {
    local choice
    choice=$(ui_choose "Swarm Activation Threshold" \
        "100 tokens - Very low threshold ⭐ RECOMMENDED FOR TESTING" \
        "1000 tokens - Low threshold" \
        "5000 tokens - Medium threshold" \
        "10000 tokens - High threshold (production)" \
        "Force swarm mode (ignore token count)" \
        "Back")

    case "$choice" in
        "100 tokens"*)
            SWARM_MIN_TOKENS=100
            SWARM_FORCE="false"
            ;;
        "1000 tokens"*)
            SWARM_MIN_TOKENS=1000
            SWARM_FORCE="false"
            ;;
        "5000 tokens"*)
            SWARM_MIN_TOKENS=5000
            SWARM_FORCE="false"
            ;;
        "10000 tokens"*)
            SWARM_MIN_TOKENS=10000
            SWARM_FORCE="false"
            ;;
        "Force swarm"*)
            SWARM_FORCE="true"
            success "Force mode enabled - swarm will activate regardless of token count"
            ;;
        "Back"|"")
            return 0
            ;;
    esac

    if [[ "$SWARM_FORCE" != "true" ]]; then
        config_set "swarm.min_tokens" "$SWARM_MIN_TOKENS"
        config_set "swarm.force" "false"
        success "Minimum tokens set to: $SWARM_MIN_TOKENS"
    else
        config_set "swarm.force" "true"
    fi
}

# Toggle swarm on/off
swarm_toggle() {
    if [[ "$SWARM_ENABLED" = "true" ]]; then
        SWARM_ENABLED="false"
        config_set "swarm.enabled" "false"
        msg "Multi-agent AI swarm mode DISABLED"
    else
        SWARM_ENABLED="true"
        config_set "swarm.enabled" "true"
        success "Multi-agent AI swarm mode ENABLED 🐝"
        echo ""
        msg "Swarm mode uses multiple AI workers to analyze large codebases in parallel"
        msg "This is NOT Docker Swarm - it's an AI orchestration feature for code analysis"
    fi
}

# ============================================================================
# SWARM EXECUTION
# ============================================================================

# Main swarm execution entry point
swarm_execute() {
    local prompt="$1"
    local mode="$2"

    echo "" >&2
    ui_header "🐝 Swarm Mode Execution" >&2
    echo "" >&2
    echo "DEBUG: swarm_execute called with mode=$mode" >&2
    echo "DEBUG: Prompt length: ${#prompt} characters" >&2

    # Calculate tokens for messaging
    local tokens=$(estimate_tokens "$prompt")
    echo "DEBUG: Estimated tokens: $tokens" >&2

    # Auto-detect strategy if set to auto
    local strategy="$SWARM_STRATEGY"
    echo "DEBUG: Current SWARM_STRATEGY=$SWARM_STRATEGY" >&2
    if [[ "$strategy" = "auto" ]]; then
        strategy=$(swarm_auto_detect "$prompt")
        echo "Auto-detected strategy: $strategy" >&2
    fi

    echo "Strategy: $strategy" >&2
    echo "Workers: $SWARM_WORKERS × $SWARM_WORKER_PROVIDER/$SWARM_WORKER_MODEL" >&2
    echo "Aggregator: $SWARM_AGGREGATOR_PROVIDER/$SWARM_AGGREGATOR_MODEL" >&2
    echo "" >&2

    # Execute based on strategy
    case "$strategy" in
        mapreduce)
            swarm_mapreduce "$prompt" "$mode"
            ;;
        hierarchical)
            swarm_hierarchical "$prompt" "$mode"
            ;;
        none)
            echo "⚠ Prompt too small for swarm mode (estimated $tokens tokens < $SWARM_MIN_TOKENS threshold)" >&2
            echo "💡 Tip: Use '/swarm' menu to enable Force mode or lower the threshold" >&2
            echo "DEBUG: Returning 1 to fall back to standard execution" >&2
            return 1  # Fall back to standard execution
            ;;
        *)
            echo "ERROR: Unknown strategy: $strategy" >&2
            return 1
            ;;
    esac
}

# Auto-detect best strategy
swarm_auto_detect() {
    local prompt="$1"
    local tokens=$(estimate_tokens "$prompt")

    # Force swarm mode if configured
    if [[ "$SWARM_FORCE" = "true" ]]; then
        echo "mapreduce"
        return
    fi

    # Small context - no swarm needed (use configurable threshold)
    if (( tokens < SWARM_MIN_TOKENS )); then
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

    echo "DEBUG: Estimating tokens for prompt..." >&2
    local tokens=$(estimate_tokens "$prompt")
    echo "DEBUG: Estimated tokens: $tokens" >&2

    local chunk_size=500  # tokens per chunk (lowered for easier testing)
    local num_chunks=$(( (tokens + chunk_size - 1) / chunk_size ))
    echo "DEBUG: Calculated $num_chunks chunks (chunk_size=$chunk_size)" >&2

    # If force mode, allow even 1 chunk for testing
    if [[ "$SWARM_FORCE" != "true" ]] && (( num_chunks < 2 )); then
        echo "⚠ Prompt too small for swarm mode ($num_chunks chunks)" >&2
        echo "DEBUG: tokens=$tokens, num_chunks=$num_chunks" >&2
        return 1
    fi

    echo -e "${CYAN}📦 Splitting prompt into $num_chunks chunks...${RESET}" >&2

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
    echo "" >&2
    echo -e "${BOLD}${CYAN}━━━ Phase 1: Parallel Processing ━━━${RESET}" >&2
    echo -e "${CYAN}Processing $num_chunks chunks with $SWARM_WORKERS parallel workers${RESET}" >&2
    echo "" >&2

    local -a summaries=()
    local processed=0
    local total=$num_chunks

    # Write chunks to temp files first (avoid ARG_MAX issues)
    local chunk_dir=$(mktemp -d)
    for (( i=0; i<num_chunks; i++ )); do
        echo "${chunks[$i]}" > "$chunk_dir/chunk_$i.txt"
    done

    for (( i=0; i<num_chunks; i++ )); do
        # Wait if we've hit max parallel workers
        while (( $(jobs -r | wc -l) >= SWARM_WORKERS )); do
            sleep "$AIWB_UI_MEDIUM_DELAY"
        done

        # Process chunk in background
        (
            local chunk_num=$((i + 1))
            local chunk_content=$(cat "$chunk_dir/chunk_$i.txt")
            local chunk_prompt="[MULTI-AGENT AI CODE ANALYSIS - WORKER TASK]

You are one of $total AI workers in a parallel code analysis system (NOT Docker/containers).
This is a multi-agent AI orchestration system that splits large codebases into chunks for analysis.

YOUR TASK: Analyze and summarize code chunk $chunk_num/$total.
Your summary will be combined with $((total - 1)) other AI-generated summaries by a synthesis model.

Focus on:
- Key functionality and purpose
- Important patterns and structures
- Notable dependencies or relationships

CODE CHUNK $chunk_num/$total:

$chunk_content"

            echo -e "${CYAN}  🤖 Worker ${chunk_num}: Processing...${RESET}" >&2
            local summary=$(call_api "$chunk_prompt" "$SWARM_WORKER_PROVIDER" "$SWARM_WORKER_MODEL")
            echo "$summary" > "$chunk_dir/output_$i.txt"
            echo -e "${GREEN}  ✓ Worker ${chunk_num}: Complete${RESET}" >&2
        ) &

        echo -e "${DIM}  → Launched worker $((i + 1))/$num_chunks${RESET}" >&2
    done

    # Wait for all workers to complete
    echo "" >&2
    echo -e "${YELLOW}⏳ Waiting for all workers to complete...${RESET}" >&2
    wait
    echo -e "${GREEN}✓ All workers finished!${RESET}" >&2

    # Collect summaries
    local failed_chunks=0
    for (( i=0; i<num_chunks; i++ )); do
        if [[ -f "$chunk_dir/output_$i.txt" ]]; then
            summaries[$i]=$(cat "$chunk_dir/output_$i.txt")
        else
            echo "ERROR: Chunk $i failed to process" >&2
            failed_chunks=$((failed_chunks + 1))
            summaries[$i]="[Chunk $i processing failed]"
        fi
    done

    # Cleanup temp directory
    rm -rf "$chunk_dir"

    if (( failed_chunks > 0 )); then
        echo "WARNING: $failed_chunks out of $num_chunks chunks failed" >&2
    fi

    echo "" >&2
    echo -e "${GREEN}✓ Phase 1 complete: $num_chunks chunks processed${RESET}" >&2
    echo "" >&2

    # Phase 2: Aggregate results
    echo -e "${BOLD}${CYAN}━━━ Phase 2: Aggregation ━━━${RESET}" >&2
    echo -e "${CYAN}Synthesizing results with ${SWARM_AGGREGATOR_PROVIDER}/${SWARM_AGGREGATOR_MODEL}${RESET}" >&2
    echo "" >&2

    local combined_summaries=""
    for (( i=0; i<num_chunks; i++ )); do
        combined_summaries="$combined_summaries

=== Chunk $((i + 1)) Summary ===
${summaries[$i]}"
        echo -e "${DIM}  → Collected chunk $((i + 1))/$num_chunks${RESET}" >&2
    done

    local aggregation_prompt="[MULTI-AGENT AI CODE ANALYSIS - AGGREGATION PHASE]

You are the synthesis AI in a multi-agent code analysis system (NOT Docker/infrastructure).
Multiple AI workers have analyzed different chunks of a large codebase in parallel.
Your role: Synthesize their summaries into a comprehensive, cohesive ${mode} response.

WORKER SUMMARIES FROM PARALLEL ANALYSIS:
$combined_summaries

YOUR TASK: Provide a comprehensive ${mode} output that:
- Synthesizes insights from all chunks
- Identifies patterns across the entire codebase
- Presents a cohesive, well-organized analysis
- Avoids redundancy while covering all important points"

    echo "" >&2
    echo -e "${YELLOW}🧠 Aggregating with ${SWARM_AGGREGATOR_PROVIDER}...${RESET}" >&2
    local final_output=$(call_api "$aggregation_prompt" "$SWARM_AGGREGATOR_PROVIDER" "$SWARM_AGGREGATOR_MODEL")

    echo "" >&2
    echo -e "${GREEN}✓ Phase 2 complete: Results aggregated${RESET}" >&2
    echo "" >&2

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
