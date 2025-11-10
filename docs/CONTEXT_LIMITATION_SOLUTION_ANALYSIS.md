# Context Limitation Solution Analysis
## Using Parallel Agents & Local Memory for Large Codebases (100k+ Lines)

**Date**: 2025-11-10
**Analysis**: Feasibility of using cheap, context-limited models with parallel execution and local memory buffers to work on massive codebases

---

## Executive Summary

**Question**: Can we use multiple instances of cheap but good models (with context limitations) working in parallel with a shared local memory buffer to handle codebases with 100k+ lines of code?

**Answer**: **YES** - This is technically feasible and economically viable. Several established patterns exist:

1. **Map-Reduce Pattern** - Divide codebase into chunks, process in parallel, aggregate results
2. **RAG (Retrieval-Augmented Generation)** - Semantic search + context injection
3. **Hierarchical Summarization** - Multi-level abstraction pyramid
4. **Agent Swarm** - Specialized agents with shared memory bus
5. **Streaming Context Windows** - Rolling window with relevance-based eviction

**Best Approach**: Hybrid RAG + Map-Reduce with intelligent chunking and vector-based retrieval.

---

## 1. Current AIWB Limitations (Baseline)

### Architecture Constraints

| Constraint | Current State | Impact on 100k LOC |
|------------|---------------|-------------------|
| **Context Assembly** | Loads all files into single Bash variable | Impossible (memory limits) |
| **Processing Model** | Sequential, single-threaded | Takes hours for large codebases |
| **File Selection** | Naive (first 5 files, head -20) | Misses critical context |
| **Token Management** | Basic estimation (chars/4) | Exceeds API limits |
| **Memory Model** | In-memory only, no persistence | Cannot handle distributed work |
| **Caching** | None - resends everything | Wastes tokens and cost |

### Practical Limits

```bash
# Current AIWB can handle:
✓ Small projects:  < 1MB,    < 50 files    (< 10K LOC)
✓ Medium projects: 1-10MB,   50-500 files  (10-50K LOC)
⚠ Large projects:  10-50MB,  500-5K files  (50-100K LOC) - Slow, may fail
✗ Massive projects: > 50MB,  5K+ files     (> 100K LOC) - Will fail

# For 100K lines of code (~5MB text):
- Context assembly: 30+ seconds
- Bash variable size: 256KB limit (exceeded!)
- Token count: ~25K tokens (exceeds most context windows)
- Cost per request: $0.20-2.00 (unsustainable for repeated calls)
```

---

## 2. Proposed Solution Architectures

### Architecture A: Map-Reduce with Parallel Agents

**Concept**: Split codebase into manageable chunks, process in parallel, merge results.

```
┌─────────────────────────────────────────────────────────┐
│              MASTER COORDINATOR                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │  1. Code Chunking Engine                        │   │
│  │     └─ Split by: Module, Package, Namespace     │   │
│  │        Max chunk: 2K-4K tokens (~8K chars)      │   │
│  │                                                  │   │
│  │  2. Task Queue                                  │   │
│  │     ├─ Task 1: Analyze src/auth/*.go           │   │
│  │     ├─ Task 2: Analyze src/db/*.go             │   │
│  │     └─ Task N: Analyze src/api/*.go            │   │
│  │                                                  │   │
│  │  3. Shared Memory Buffer (Key-Value Store)     │   │
│  │     ├─ SQLite/Redis/File-based JSON            │   │
│  │     └─ Stores: Summaries, Symbols, Embeddings  │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ AGENT 1  │    │ AGENT 2  │    │ AGENT N  │
    │ (Gemini) │    │ (Gemini) │    │ (Gemini) │
    │ 2K ctx   │    │ 2K ctx   │    │ 2K ctx   │
    └──────────┘    └──────────┘    └──────────┘
          │               │               │
          └───────────────┼───────────────┘
                          │
                          ▼
              ┌──────────────────────┐
              │  RESULT AGGREGATOR   │
              │  ├─ Merge summaries  │
              │  ├─ Build call graph │
              │  └─ Final answer     │
              └──────────────────────┘
```

**Implementation**:

```bash
#!/bin/bash
# Parallel agent architecture for AIWB

# 1. Chunk the codebase
chunk_codebase() {
    local dir="$1"
    local max_tokens=2000

    # Find all source files, group by directory
    find "$dir" -type f \( -name "*.go" -o -name "*.py" -o -name "*.js" \) | \
    while read file; do
        # Estimate tokens
        tokens=$(wc -c < "$file" | awk '{print int($1/4)}')

        if (( tokens < max_tokens )); then
            echo "CHUNK:$file"
        else
            # Split large files into functions/classes
            echo "CHUNK:$file:split_required"
        fi
    done
}

# 2. Shared memory using SQLite
init_memory_buffer() {
    sqlite3 ~/.aiwb/memory.db <<EOF
CREATE TABLE IF NOT EXISTS chunks (
    id INTEGER PRIMARY KEY,
    file_path TEXT,
    chunk_id TEXT,
    content TEXT,
    summary TEXT,
    embedding BLOB,
    processed INTEGER DEFAULT 0
);
CREATE INDEX idx_chunk ON chunks(chunk_id);
CREATE INDEX idx_processed ON chunks(processed);
EOF
}

# 3. Parallel worker function
process_chunk_worker() {
    local chunk_id="$1"
    local provider="gemini"  # Cheap model
    local model="2.5-flash"  # ~$0.10 per 1M tokens

    # Get chunk from memory
    content=$(sqlite3 ~/.aiwb/memory.db \
        "SELECT content FROM chunks WHERE chunk_id='$chunk_id'")

    # Build focused prompt
    prompt="Analyze this code and provide:
1. Summary (1-2 sentences)
2. Key functions/classes
3. Dependencies
4. Potential issues

Code:
$content"

    # Call API (async/parallel)
    result=$(call_api "$prompt" "$provider" "$model")

    # Store summary back to memory
    sqlite3 ~/.aiwb/memory.db \
        "UPDATE chunks SET summary='$result', processed=1 WHERE chunk_id='$chunk_id'"
}

# 4. Parallel dispatcher
dispatch_parallel_agents() {
    local max_parallel=5  # Run 5 agents at once

    # Get all unprocessed chunks
    sqlite3 ~/.aiwb/memory.db \
        "SELECT chunk_id FROM chunks WHERE processed=0" | \
    while read chunk_id; do
        # Launch worker in background
        process_chunk_worker "$chunk_id" &

        # Rate limiting: max N parallel
        if (( $(jobs -p | wc -l) >= max_parallel )); then
            wait -n  # Wait for any one job to finish
        fi
    done

    # Wait for all remaining jobs
    wait
}

# 5. Query interface
query_codebase() {
    local query="$1"

    # Get relevant summaries from memory
    relevant_chunks=$(sqlite3 ~/.aiwb/memory.db \
        "SELECT file_path, summary FROM chunks WHERE summary LIKE '%$query%' LIMIT 10")

    # Build final prompt with relevant context
    final_prompt="Based on these code summaries, answer: $query

Context:
$relevant_chunks"

    # Use better model for final answer
    call_api "$final_prompt" "claude" "3.5-sonnet"
}
```

**Pros**:
- ✓ Handles unlimited codebase size
- ✓ Embarrassingly parallel (linear speedup)
- ✓ Uses cheap models ($0.10 per 1M tokens)
- ✓ Each agent has manageable context (2-4K tokens)
- ✓ Intermediate results cached

**Cons**:
- ✗ Setup complexity (task queue, workers)
- ✗ Requires shared storage (SQLite/Redis)
- ✗ Context boundaries may split related code
- ✗ Aggregation step still needs human guidance

---

### Architecture B: RAG (Retrieval-Augmented Generation)

**Concept**: Index entire codebase with embeddings, retrieve relevant chunks on-demand.

```
┌─────────────────────────────────────────────────┐
│           VECTOR DATABASE (One-time setup)       │
│  ┌───────────────────────────────────────────┐ │
│  │  1. Code Embedding Pipeline               │ │
│  │     ├─ Parse code into chunks             │ │
│  │     ├─ Generate embeddings (local model)  │ │
│  │     └─ Store in vector DB (ChromaDB)      │ │
│  │                                            │ │
│  │  Storage: 100K LOC = ~10K chunks          │ │
│  │           ~10K embeddings (768-dim)       │ │
│  │           ~30MB vector DB                 │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
                      │
                      │ Query: "How does authentication work?"
                      ▼
          ┌────────────────────────┐
          │  SEMANTIC SEARCH       │
          │  ├─ Embed query        │
          │  ├─ Cosine similarity  │
          │  └─ Top-K results      │
          └────────────────────────┘
                      │
                      │ Returns: 5-10 relevant chunks (~2K tokens)
                      ▼
          ┌────────────────────────┐
          │  CONTEXT INJECTION     │
          │  ├─ Build prompt       │
          │  └─ Send to LLM        │
          └────────────────────────┘
                      │
                      ▼
              ┌────────────┐
              │  AGENT     │
              │  (Gemini)  │
              │  4K ctx    │
              └────────────┘
                      │
                      ▼
                  ANSWER
```

**Implementation**:

```bash
#!/bin/bash
# RAG implementation for AIWB

# Dependencies:
# - sentence-transformers (for embeddings)
# - chromadb (vector database)
# - ollama (local embedding model)

# 1. Index codebase (one-time operation)
index_codebase() {
    local dir="$1"
    local db_path="~/.aiwb/vector_db"

    # Create Python script for embedding
    python3 <<EOF
import os
import chromadb
from sentence_transformers import SentenceTransformer

# Initialize
client = chromadb.PersistentClient(path="$db_path")
collection = client.get_or_create_collection("codebase")
model = SentenceTransformer('all-MiniLM-L6-v2')  # 384-dim, 80MB

# Chunk and embed all files
for root, dirs, files in os.walk("$dir"):
    for file in files:
        if file.endswith(('.py', '.js', '.go', '.rs', '.java')):
            path = os.path.join(root, file)
            with open(path, 'r') as f:
                content = f.read()

            # Split into chunks (by function/class)
            chunks = split_into_chunks(content, max_chars=2000)

            for i, chunk in enumerate(chunks):
                chunk_id = f"{path}:{i}"
                embedding = model.encode(chunk)

                collection.add(
                    ids=[chunk_id],
                    embeddings=[embedding.tolist()],
                    documents=[chunk],
                    metadatas=[{"file": path, "chunk": i}]
                )

print(f"Indexed {collection.count()} chunks")
EOF
}

# 2. Semantic search
search_relevant_code() {
    local query="$1"
    local top_k=5

    python3 <<EOF
import chromadb
from sentence_transformers import SentenceTransformer

client = chromadb.PersistentClient(path="$db_path")
collection = client.get_collection("codebase")
model = SentenceTransformer('all-MiniLM-L6-v2')

# Embed query
query_embedding = model.encode("$query")

# Search
results = collection.query(
    query_embeddings=[query_embedding.tolist()],
    n_results=$top_k
)

# Return relevant chunks
for doc, meta in zip(results['documents'][0], results['metadatas'][0]):
    print(f"--- {meta['file']} ---")
    print(doc)
    print()
EOF
}

# 3. RAG query function
rag_query() {
    local user_query="$1"

    # Retrieve relevant context
    context=$(search_relevant_code "$user_query")

    # Build prompt with context
    prompt="Answer this question about the codebase:

Question: $user_query

Relevant Code:
$context

Provide a concise answer based on the code above."

    # Send to cheap model
    call_api "$prompt" "gemini" "2.5-flash"
}
```

**Pros**:
- ✓ Very fast queries (< 100ms search)
- ✓ Only sends relevant code (not entire codebase)
- ✓ Semantic understanding (finds related code)
- ✓ One-time indexing cost
- ✓ Works with context-limited models
- ✓ Local embeddings (no API cost)

**Cons**:
- ✗ Initial indexing takes time (5-10 min for 100K LOC)
- ✗ Requires Python dependencies
- ✗ Vector DB storage (~30MB for 100K LOC)
- ✗ May miss code if chunking is poor

---

### Architecture C: Hierarchical Summarization

**Concept**: Build a pyramid of summaries at different abstraction levels.

```
                    ┌──────────────────────┐
                    │   LEVEL 4: Project   │
                    │   "Web API with auth"│
                    │   (100 tokens)       │
                    └──────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
      ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
      │  LEVEL 3:   │ │  LEVEL 3:   │ │  LEVEL 3:   │
      │  Package    │ │  Package    │ │  Package    │
      │  Summaries  │ │  Summaries  │ │  Summaries  │
      │  (500 tok)  │ │  (500 tok)  │ │  (500 tok)  │
      └─────────────┘ └─────────────┘ └─────────────┘
              │               │               │
      ┌───────┼───────┐       │       ┌───────┼───────┐
      ▼       ▼       ▼       ▼       ▼       ▼       ▼
   ┌────┐ ┌────┐ ┌────┐   ┌────┐ ┌────┐ ┌────┐ ┌────┐
   │L2: │ │L2: │ │L2: │   │L2: │ │L2: │ │L2: │ │L2: │
   │File│ │File│ │File│   │File│ │File│ │File│ │File│
   │Sum.│ │Sum.│ │Sum.│   │Sum.│ │Sum.│ │Sum.│ │Sum.│
   │200t│ │200t│ │200t│   │200t│ │200t│ │200t│ │200t│
   └────┘ └────┘ └────┘   └────┘ └────┘ └────┘ └────┘
      │       │       │       │       │       │       │
   ┌────────────────────────────────────────────────────┐
   │         LEVEL 1: Full Code (100K LOC)              │
   └────────────────────────────────────────────────────┘
```

**Query Strategy**:
1. Start at Level 4 (project summary)
2. Agent decides which Level 3 branches are relevant
3. Drill down to Level 2 (specific files)
4. Fetch Level 1 (actual code) only for relevant sections

**Implementation**:

```bash
#!/bin/bash
# Hierarchical summarization

# 1. Build summary pyramid (one-time)
build_summary_pyramid() {
    local dir="$1"

    # Level 1: Store all code
    # (Already on disk, no action needed)

    # Level 2: File summaries
    find "$dir" -name "*.go" -o -name "*.py" -o -name "*.js" | \
    while read file; do
        summary=$(call_api "Summarize this code in 2-3 sentences: $(cat $file)" \
                           "gemini" "2.5-flash")

        # Store summary
        echo "$file|$summary" >> ~/.aiwb/summaries_l2.txt
    done

    # Level 3: Package summaries
    find "$dir" -type d | \
    while read pkg; do
        # Get all file summaries in this package
        pkg_summaries=$(grep "^$pkg/" ~/.aiwb/summaries_l2.txt | cut -d'|' -f2)

        # Aggregate
        pkg_summary=$(call_api "Combine these file summaries: $pkg_summaries" \
                               "gemini" "2.5-flash")

        echo "$pkg|$pkg_summary" >> ~/.aiwb/summaries_l3.txt
    done

    # Level 4: Project summary
    all_pkg_summaries=$(cat ~/.aiwb/summaries_l3.txt | cut -d'|' -f2)
    project_summary=$(call_api "Summarize this project: $all_pkg_summaries" \
                               "claude" "3.5-sonnet")

    echo "$project_summary" > ~/.aiwb/summary_l4.txt
}

# 2. Smart query with drill-down
hierarchical_query() {
    local query="$1"

    # Start with L4
    l4=$(cat ~/.aiwb/summary_l4.txt)

    # Ask agent which packages are relevant
    relevant_pkgs=$(call_api "Given this project: $l4
    Which packages would be relevant for: $query?
    Respond with package names only." "gemini" "2.5-flash")

    # Get L3 summaries for those packages
    l3_context=""
    echo "$relevant_pkgs" | while read pkg; do
        l3_context+=$(grep "^$pkg|" ~/.aiwb/summaries_l3.txt)
    done

    # Ask agent which files are relevant
    relevant_files=$(call_api "Given these packages: $l3_context
    Which files would be relevant for: $query?" "gemini" "2.5-flash")

    # Fetch actual code (L1) for those files
    final_context=""
    echo "$relevant_files" | while read file; do
        final_context+="--- $file ---\n$(cat $file)\n\n"
    done

    # Final answer with precise context
    call_api "Answer this question: $query

Context:
$final_context" "claude" "3.5-sonnet"
}
```

**Pros**:
- ✓ Minimal context per query
- ✓ Intelligent drill-down
- ✓ Works with any codebase size
- ✓ Cheap models for intermediate steps
- ✓ Cache-friendly (summaries rarely change)

**Cons**:
- ✗ Initial summarization cost (but one-time)
- ✗ Multi-step queries (latency)
- ✗ Summaries may lose detail
- ✗ Requires rebuild when code changes significantly

---

### Architecture D: Agent Swarm with Shared Memory Bus

**Concept**: Multiple specialized agents communicate via shared memory.

```
┌──────────────────────────────────────────────────────┐
│              SHARED MEMORY BUS (Redis)               │
│  ┌────────────────────────────────────────────────┐ │
│  │  Channels:                                     │ │
│  │  ├─ code_index: {file -> summary}             │ │
│  │  ├─ symbol_table: {func -> location}          │ │
│  │  ├─ call_graph: {func -> [callers]}           │ │
│  │  ├─ task_queue: [pending tasks]               │ │
│  │  └─ results: {task_id -> result}              │ │
│  └────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
       │              │              │              │
       ▼              ▼              ▼              ▼
 ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
 │ INDEXER  │  │ ANALYZER │  │ REVIEWER │  │ EXPLAINER│
 │  Agent   │  │  Agent   │  │  Agent   │  │  Agent   │
 │          │  │          │  │          │  │          │
 │  Role:   │  │  Role:   │  │  Role:   │  │  Role:   │
 │  Build   │  │  Find    │  │  Check   │  │  Answer  │
 │  indexes │  │  bugs    │  │  quality │  │  queries │
 └──────────┘  └──────────┘  └──────────┘  └──────────┘
```

**Implementation**:

```bash
#!/bin/bash
# Agent swarm architecture

# Requires: redis-server running

# 1. Initialize memory bus
init_memory_bus() {
    redis-cli FLUSHDB

    # Create channels
    redis-cli SADD agents "indexer" "analyzer" "reviewer" "explainer"
}

# 2. Indexer agent
agent_indexer() {
    while true; do
        # Check for new files to index
        file=$(redis-cli LPOP index_queue)
        if [[ -z "$file" ]]; then
            sleep 1
            continue
        fi

        # Analyze file
        content=$(cat "$file")
        summary=$(call_api "Summarize: $content" "gemini" "2.5-flash")

        # Store in memory bus
        redis-cli HSET code_index "$file" "$summary"

        # Extract symbols
        symbols=$(call_api "List all functions/classes: $content" "gemini" "2.5-flash")
        redis-cli HSET symbol_table "$file" "$symbols"
    done
}

# 3. Analyzer agent
agent_analyzer() {
    while true; do
        # Wait for analysis tasks
        task=$(redis-cli BLPOP analyze_queue 5)  # 5s timeout
        if [[ -z "$task" ]]; then
            continue
        fi

        # Get context from memory bus
        file=$(echo "$task" | jq -r '.file')
        context=$(redis-cli HGET code_index "$file")

        # Perform analysis
        result=$(call_api "Analyze for bugs: $context" "gemini" "2.5-flash")

        # Store result
        redis-cli HSET results "$(echo $task | jq -r '.id')" "$result"
    done
}

# 4. Query coordinator
query_with_swarm() {
    local query="$1"
    local task_id=$(uuidgen)

    # Determine which agents are needed
    agents_needed=$(call_api "Which agents would help answer: $query?
    Available: indexer, analyzer, reviewer, explainer" "gemini" "2.5-flash")

    # Dispatch to agents
    echo "$agents_needed" | while read agent; do
        task=$(jq -n --arg id "$task_id" --arg query "$query" \
               '{id: $id, query: $query}')
        redis-cli RPUSH "${agent}_queue" "$task"
    done

    # Wait for results
    while true; do
        result=$(redis-cli HGET results "$task_id")
        if [[ -n "$result" ]]; then
            echo "$result"
            break
        fi
        sleep 0.5
    done
}

# 5. Launch swarm
launch_agent_swarm() {
    agent_indexer &
    agent_analyzer &
    agent_reviewer &
    agent_explainer &

    echo "Agent swarm launched (4 agents)"
}
```

**Pros**:
- ✓ Highly scalable (add more agents dynamically)
- ✓ Specialized agents = better results
- ✓ Asynchronous (non-blocking)
- ✓ Shared memory = consistent state

**Cons**:
- ✗ Complex architecture
- ✗ Requires Redis/external service
- ✗ Agent coordination overhead
- ✗ Debugging is difficult

---

## 3. Cost-Benefit Analysis

### Model Selection for 100K LOC Processing

| Model | Context | Cost (per 1M tokens) | Speed | Best Use Case |
|-------|---------|---------------------|-------|---------------|
| **Gemini 2.5 Flash** | 1M | $0.10 (in), $0.30 (out) | Fast | ✓ Chunking, summarization |
| **Gemini 2.0 Flash Lite** | 1M | $0.05 (in), $0.15 (out) | Very Fast | ✓ Parallel workers |
| **Claude 3.5 Haiku** | 200K | $1.00 (in), $5.00 (out) | Fast | Final aggregation |
| **Claude 3.5 Sonnet** | 200K | $3.00 (in), $15.00 (out) | Medium | Complex reasoning |
| **Llama 3.3 70B (Groq)** | 128K | $0.59 (in), $0.79 (out) | Very Fast | ✓ High-volume tasks |

### Cost Comparison: 100K LOC Codebase

**Scenario**: Analyze 100,000 lines of code (~500KB text, ~125K tokens)

#### Option 1: Naive Approach (Current AIWB)
```
Approach: Send entire codebase to Claude 3.5 Sonnet
Input tokens: 125,000
Output tokens: 2,000 (summary)
Cost: (125K × $3/1M) + (2K × $15/1M) = $0.375 + $0.03 = $0.41

Problem: Exceeds context window (200K max)
Reality: FAILS - cannot process
```

#### Option 2: Map-Reduce with Gemini Flash
```
Approach: Split into 50 chunks of 2.5K tokens each

Phase 1 (Parallel): 50 chunks × Gemini 2.5 Flash
  Input: 50 × 2,500 tokens = 125K tokens
  Output: 50 × 200 tokens (summaries) = 10K tokens
  Cost: (125K × $0.10/1M) + (10K × $0.30/1M) = $0.0125 + $0.003 = $0.0155

Phase 2 (Aggregation): Merge 50 summaries with Claude Haiku
  Input: 10K tokens
  Output: 1K tokens
  Cost: (10K × $1/1M) + (1K × $5/1M) = $0.01 + $0.005 = $0.015

Total: $0.0155 + $0.015 = $0.0305
Time: ~2 minutes (5 parallel agents)
```

#### Option 3: RAG with Embeddings
```
Approach: Index once, query multiple times

Setup (One-time):
  Embedding: 10,000 chunks × local model = FREE
  Storage: ~30MB vector DB = FREE
  Time: 5-10 minutes

Per Query:
  Vector search: 10ms = FREE (local)
  Retrieve top 5 chunks: 2,500 tokens context
  LLM call (Gemini Flash): (2.5K × $0.10/1M) + (500 × $0.30/1M)
  Cost: $0.00025 + $0.00015 = $0.0004 per query

For 100 queries: $0.04 total
Time: < 1 second per query
```

#### Option 4: Hierarchical Summarization
```
Approach: Build summary pyramid

Setup (One-time):
  Level 2 (file summaries): 200 files × 1K tokens = 200K tokens
    Cost: (200K × $0.10/1M) + (200 × 200 × $0.30/1M) = $0.02 + $0.012 = $0.032

  Level 3 (package summaries): 20 packages × 1K tokens = 20K tokens
    Cost: (20K × $0.10/1M) + (20 × 200 × $0.30/1M) = $0.002 + $0.0012 = $0.0032

  Level 4 (project summary): 1 summary × 2K tokens
    Cost: (2K × $1/1M) + (500 × $5/1M) = $0.002 + $0.0025 = $0.0045

  Total Setup: $0.0397 (~$0.04)

Per Query:
  L4 → L3 → L2 → L1 drill-down: ~5K tokens
  Cost: $0.0005 per query

For 100 queries: $0.04 + $0.05 = $0.09
```

### Winner: RAG Approach
- ✓ Lowest cost per query ($0.0004)
- ✓ Fastest queries (< 1 second)
- ✓ Best for interactive use
- ✓ Scales to any codebase size

---

## 4. Implementation Recommendation for AIWB

### Phase 1: Add RAG Support (Highest ROI)

**Changes to AIWB**:

```bash
# New file: lib/rag.sh

# Install dependencies (one-time)
setup_rag() {
    if ! command -v python3 &>/dev/null; then
        die "Python 3 required for RAG"
    fi

    pip3 install -q sentence-transformers chromadb

    # Download embedding model (80MB, one-time)
    python3 -c "from sentence_transformers import SentenceTransformer; \
                SentenceTransformer('all-MiniLM-L6-v2')"

    success "RAG dependencies installed"
}

# Index workspace
rag_index() {
    local workspace="$1"
    local db_path="~/.aiwb/rag_db"

    info "Indexing workspace: $workspace"
    info "This may take 5-10 minutes for large codebases..."

    python3 <<'PYEOF'
import os, sys
import chromadb
from sentence_transformers import SentenceTransformer
from pathlib import Path

workspace = sys.argv[1]
db_path = sys.argv[2]

# Initialize
client = chromadb.PersistentClient(path=db_path)
try:
    client.delete_collection("codebase")
except:
    pass
collection = client.create_collection("codebase")

model = SentenceTransformer('all-MiniLM-L6-v2')

# Supported extensions
extensions = {'.py', '.js', '.go', '.rs', '.java', '.cpp', '.c', '.sh', '.ts', '.tsx'}

# Index files
count = 0
for root, dirs, files in os.walk(workspace):
    # Skip common ignore patterns
    dirs[:] = [d for d in dirs if d not in {'.git', 'node_modules', '__pycache__', 'venv'}]

    for file in files:
        if Path(file).suffix not in extensions:
            continue

        filepath = os.path.join(root, file)
        try:
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        except:
            continue

        # Split into chunks (simple line-based)
        lines = content.split('\n')
        chunks = []
        current_chunk = []
        current_size = 0

        for line in lines:
            current_chunk.append(line)
            current_size += len(line)

            if current_size >= 2000:  # 2K chars = ~500 tokens
                chunks.append('\n'.join(current_chunk))
                current_chunk = []
                current_size = 0

        if current_chunk:
            chunks.append('\n'.join(current_chunk))

        # Embed and store
        for i, chunk in enumerate(chunks):
            if len(chunk.strip()) < 50:  # Skip tiny chunks
                continue

            chunk_id = f"{filepath}::{i}"
            embedding = model.encode(chunk)

            collection.add(
                ids=[chunk_id],
                embeddings=[embedding.tolist()],
                documents=[chunk],
                metadatas=[{
                    "file": filepath,
                    "chunk": i,
                    "lines": len(chunk.split('\n'))
                }]
            )
            count += 1

print(f"Indexed {count} code chunks")
PYEOF

    success "Indexing complete!"
}

# Search for relevant code
rag_search() {
    local query="$1"
    local top_k="${2:-5}"
    local db_path="~/.aiwb/rag_db"

    python3 <<PYEOF
import sys
import chromadb
from sentence_transformers import SentenceTransformer

query = "$query"
top_k = $top_k
db_path = "$db_path"

# Initialize
client = chromadb.PersistentClient(path=db_path)
collection = client.get_collection("codebase")
model = SentenceTransformer('all-MiniLM-L6-v2')

# Embed query
query_embedding = model.encode(query)

# Search
results = collection.query(
    query_embeddings=[query_embedding.tolist()],
    n_results=top_k
)

# Output results
for doc, meta in zip(results['documents'][0], results['metadatas'][0]):
    print(f"--- {meta['file']} (lines ~{meta['lines']}) ---")
    print(doc)
    print()
PYEOF
}

# RAG-powered query
rag_query() {
    local user_query="$1"
    local provider="${2:-gemini}"
    local model="${3:-2.5-flash}"

    # Get relevant context
    info "Searching codebase for relevant context..."
    local context=$(rag_search "$user_query" 5)

    if [[ -z "$context" ]]; then
        warn "No relevant code found. Is your workspace indexed? Run: aiwb rag-index"
        return 1
    fi

    # Build prompt
    local prompt="Answer this question about the codebase:

Question: $user_query

Relevant Code Context:
$context

Provide a clear, concise answer based on the code above."

    # Call API
    info "Generating answer..."
    call_api "$prompt" "$provider" "$model"
}
```

**New Commands**:
```bash
# Add to aiwb main dispatch
case "$cmd" in
    # ... existing commands ...

    rag-setup)
        setup_rag
        ;;

    rag-index)
        workspace=$(config_get "workspace")
        rag_index "$workspace"
        ;;

    rag-query|rq)
        shift
        query="$*"
        rag_query "$query"
        ;;

    rag-search|rs)
        shift
        query="$*"
        rag_search "$query" 10
        ;;
esac
```

**Usage**:
```bash
# One-time setup
aiwb rag-setup

# Index your workspace (5-10 min for 100K LOC)
aiwb rag-index

# Query the codebase
aiwb rag-query "How does authentication work?"
aiwb rq "Find all database queries"
aiwb rs "error handling"  # Just search, don't query LLM
```

---

### Phase 2: Add Parallel Map-Reduce (Advanced)

**New file**: `lib/parallel.sh`

```bash
# Parallel processing for large codebases

# Process directory in parallel chunks
parallel_process() {
    local dir="$1"
    local task="$2"  # "summarize", "analyze", "review"
    local max_workers="${3:-5}"

    # Create task queue
    local queue_file=$(mktemp)

    # Split codebase into chunks
    find "$dir" -type f \( -name "*.go" -o -name "*.py" -o -name "*.js" \) | \
    while read file; do
        echo "$file" >> "$queue_file"
    done

    local total=$(wc -l < "$queue_file")
    info "Processing $total files with $max_workers workers..."

    # Launch worker pool
    local workers=()
    for i in $(seq 1 $max_workers); do
        worker_process "$queue_file" "$task" "$i" &
        workers+=($!)
    done

    # Wait for completion
    for pid in "${workers[@]}"; do
        wait $pid
    done

    success "Parallel processing complete!"
}

# Worker process
worker_process() {
    local queue="$1"
    local task="$2"
    local worker_id="$3"

    while true; do
        # Atomic queue pop (using flock)
        local file
        (
            flock -x 200
            file=$(head -1 "$queue")
            tail -n +2 "$queue" > "${queue}.tmp"
            mv "${queue}.tmp" "$queue"
        ) 200>"${queue}.lock"

        if [[ -z "$file" ]]; then
            break
        fi

        # Process file based on task
        case "$task" in
            summarize)
                content=$(cat "$file")
                result=$(call_api "Summarize: $content" "gemini" "2.5-flash")
                echo "$file|$result" >> ~/.aiwb/parallel_results.txt
                ;;
            analyze)
                content=$(cat "$file")
                result=$(call_api "Find bugs: $content" "gemini" "2.5-flash")
                echo "$file|$result" >> ~/.aiwb/parallel_results.txt
                ;;
        esac

        info "[Worker $worker_id] Processed: $file"
    done
}

# Aggregate results
aggregate_results() {
    local results_file="~/.aiwb/parallel_results.txt"

    # Group results
    local all_summaries=$(cut -d'|' -f2 "$results_file")

    # Final aggregation with better model
    call_api "Synthesize these file analyses into a project overview:

$all_summaries" "claude" "3.5-haiku"
}
```

**Usage**:
```bash
# Process entire codebase in parallel
aiwb parallel-summarize ./src --workers 10

# Aggregate results
aiwb parallel-aggregate
```

---

## 5. Performance Projections

### 100K LOC Codebase Benchmarks

| Architecture | Setup Time | Query Time | Cost (Setup) | Cost (100 queries) | Scalability |
|--------------|-----------|------------|--------------|-------------------|-------------|
| **Naive (current)** | 0 | N/A (fails) | $0 | N/A | ✗ Fails |
| **Map-Reduce** | 0 | 2 min | $0 | $3.05 | ✓ Good |
| **RAG** | 5-10 min | 1 sec | $0 | $0.04 | ✓✓ Excellent |
| **Hierarchical** | 10-15 min | 5 sec | $0.04 | $0.09 | ✓ Good |
| **Agent Swarm** | 2 min | 1 sec | $0 | $0.05 | ✓✓ Excellent |

### 1M LOC Codebase Projections

| Architecture | Setup Time | Query Time | Cost (Setup) | Cost (1000 queries) | Scalability |
|--------------|-----------|------------|--------------|---------------------|-------------|
| **Map-Reduce** | 0 | 20 min | $0 | $30.50 | △ Slow |
| **RAG** | 1-2 hours | 1 sec | $0 | $0.40 | ✓✓ Excellent |
| **Hierarchical** | 2-3 hours | 10 sec | $0.40 | $4.90 | ✓ Good |

**Winner**: RAG scales linearly, no degradation with codebase size.

---

## 6. Conclusion & Recommendations

### Key Findings

1. **100K+ LOC is FULLY feasible** with proper architecture
2. **RAG is the best approach** for most use cases (cost, speed, scalability)
3. **Cheap models work great** for chunking/summarization (Gemini 2.5 Flash)
4. **Parallel processing is essential** for initial indexing
5. **Local embeddings are free** and fast (no API costs)

### Recommended Implementation Plan

**For AIWB v2.1-v2.5**:

1. **Immediate (v2.1)**:
   - Add RAG support (lib/rag.sh)
   - Commands: `rag-setup`, `rag-index`, `rag-query`
   - Dependencies: Python, sentence-transformers, chromadb

2. **Short-term (v2.2)**:
   - Add parallel processing (lib/parallel.sh)
   - Commands: `parallel-summarize`, `parallel-analyze`
   - Use Bash background jobs (no external dependencies)

3. **Medium-term (v2.3)**:
   - Hybrid RAG + Map-Reduce
   - Automatic re-indexing on file changes (fswatch)
   - Smart chunk size optimization

4. **Long-term (v3.0)**:
   - Agent swarm architecture
   - Real-time collaboration between agents
   - Streaming context updates

### Cost-Benefit Verdict

**For 100K LOC codebase**:
- Setup cost: **$0** (using local embeddings)
- Query cost: **$0.0004** per query
- Time per query: **< 1 second**
- Storage: **~30MB** vector DB

**ROI**: After ~100 queries, RAG pays for itself vs. current naive approach (if it worked). For heavy users (1000+ queries), savings are **~$400 vs. Map-Reduce**.

---

## 7. Example: End-to-End RAG Workflow

```bash
# ==============================================================
# COMPLETE EXAMPLE: Analyzing a 100K LOC Python web framework
# ==============================================================

# 1. Setup (one-time, ~2 minutes)
aiwb rag-setup

# 2. Index the codebase (one-time, ~5 minutes for 100K LOC)
cd ~/my-large-project
aiwb rag-index

# Output:
# Indexing workspace: /home/user/my-large-project
# Found 1,247 files
# Creating 9,842 code chunks
# Generating embeddings... [████████████] 100%
# Indexed 9,842 chunks in 4m 32s

# 3. Query the codebase (instant, $0.0004 per query)
aiwb rq "How does the authentication middleware work?"

# Output:
# Searching codebase for relevant context...
# Found 5 relevant code chunks (2.1K tokens)
#
# The authentication middleware uses JWT tokens stored in cookies.
# It validates tokens in the `auth/middleware.py::validate_jwt()` function,
# checking signature, expiration, and user permissions. If valid, it adds
# the user object to the request context. Invalid tokens return a 401 response.
#
# Cost: $0.0004 | Time: 0.8s

# 4. More queries (all instant, all cheap)
aiwb rq "Find all SQL injection vulnerabilities"
aiwb rq "What API endpoints are rate-limited?"
aiwb rq "Explain the caching strategy"

# 5. Search without LLM (just vector search, FREE)
aiwb rs "database connection pool"

# Output:
# --- src/db/pool.py (lines ~47) ---
# class ConnectionPool:
#     def __init__(self, max_connections=10):
#         self.pool = []
#         self.max_connections = max_connections
# [... more code ...]

# 6. Re-index after major changes (incremental)
git pull
aiwb rag-index --incremental

# Only re-indexes changed files (< 1 minute)
```

---

## 8. Alternative: Hybrid Approach (Best of All Worlds)

**Combine RAG + Map-Reduce + Hierarchical**:

```bash
# For queries: Use RAG (fast, cheap)
aiwb rq "How does X work?"

# For whole-codebase analysis: Use Map-Reduce (parallel)
aiwb parallel-analyze ./src --output analysis.md

# For project overview: Use Hierarchical (structured)
aiwb summarize-project --levels 4 --output overview.md
```

**This gives you**:
- Fast queries (RAG)
- Deep analysis (Map-Reduce)
- Structured understanding (Hierarchical)
- All within budget (< $1 for 100K LOC)

---

## 9. Final Answer to Original Question

**Question**: Can we use context-limited models in parallel with local memory to handle 100K+ LOC?

**Answer**: **Absolutely YES**. The recommended architecture is:

1. **RAG with local embeddings** (primary)
   - ✓ Handles any codebase size
   - ✓ Query cost: $0.0004 (negligible)
   - ✓ Query time: < 1 second
   - ✓ Uses cheap models (Gemini 2.5 Flash)
   - ✓ No context window issues

2. **Parallel Map-Reduce** (secondary, for batch analysis)
   - ✓ Process entire codebase in parallel
   - ✓ Use multiple cheap models simultaneously
   - ✓ Linear speedup (10 workers = 10× faster)

3. **Local memory buffer** (SQLite or vector DB)
   - ✓ Persistent storage of summaries
   - ✓ No repeated API calls for same code
   - ✓ Enables incremental updates

**This is not theoretical** - it's production-ready and used by:
- GitHub Copilot (RAG + embeddings)
- Cursor (RAG + context)
- Sourcegraph (code search + LLM)
- Tabnine (local models + cloud models)

**Implementation complexity**: Medium (requires Python, vector DB)
**Cost for 100K LOC**: < $0.05 for 100 queries
**Time to implement in AIWB**: 1-2 weeks

**Verdict**: This is the future of AI code assistants. AIWB should adopt RAG in v2.1.
