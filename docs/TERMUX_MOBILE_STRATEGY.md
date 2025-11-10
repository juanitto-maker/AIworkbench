# Optimal Strategy for Large Codebases on Termux/Mobile

## Mobile Constraints

Termux on Android has unique limitations:

| Constraint | Impact |
|------------|--------|
| **RAM** | 2-8GB total (shared with OS) |
| **CPU** | ARM cores, thermal throttling |
| **Battery** | Heavy processing = fast drain |
| **Storage** | Usually OK (64GB+) |
| **Network** | Mobile data may be expensive/limited |
| **Dependencies** | Limited package availability |

## Approach Comparison for Termux

### ❌ Agent Swarm - NOT RECOMMENDED

**Why avoid:**
- Requires Redis (heavyweight daemon)
- Multiple parallel processes = high memory
- Battery drain from constant processing
- Thermal throttling will slow everything
- Overkill complexity for mobile

**Verdict**: Too heavyweight for mobile

---

### ⚠️ RAG (Full) - POSSIBLE BUT HEAVY

**Requirements:**
```bash
pkg install python
pip install sentence-transformers  # ~200MB with deps
pip install chromadb              # ~50MB
```

**Pros:**
- Best query efficiency once set up
- One-time indexing cost
- Queries are fast (<1 sec)

**Cons:**
- 🔴 **Heavy setup**: 250-300MB dependencies
- 🔴 **CPU intensive**: Embedding generation on ARM
- 🔴 **Battery drain**: Initial indexing takes hours on mobile
- 🔴 **Thermal throttling**: Phone will heat up during indexing
- 🟡 **RAM usage**: ~500MB during indexing

**Realistic timeline for 100K LOC on mobile:**
- Setup: 30-60 min (downloading packages)
- Indexing: 2-4 hours (with thermal throttling)
- Per query: 1-2 sec

**Verdict**: Works, but painful setup. Only if you'll query frequently.

---

### ✅ RECOMMENDED: Hierarchical Summarization with SQLite

**Why this is best for Termux:**

```bash
# Already have these!
pkg install sqlite  # Usually pre-installed
# No Python ML libraries needed!
```

**Architecture:**

```
Level 4: Project Summary (500 tokens)
   ├─ Stored in SQLite
   │
Level 3: Package Summaries (20 × 200 tokens)
   ├─ Stored in SQLite
   │
Level 2: File Summaries (200 × 100 tokens)
   ├─ Stored in SQLite
   │
Level 1: Actual Code (on disk)
```

**Implementation:**

```bash
#!/data/data/com.termux/files/usr/bin/bash
# Termux-optimized hierarchical summarization

DB="$HOME/.aiwb/summaries.db"

# Initialize SQLite database
init_termux_db() {
    sqlite3 "$DB" <<'EOF'
CREATE TABLE IF NOT EXISTS file_summaries (
    file_path TEXT PRIMARY KEY,
    summary TEXT,
    tokens INTEGER,
    last_modified INTEGER
);

CREATE TABLE IF NOT EXISTS package_summaries (
    package_path TEXT PRIMARY KEY,
    summary TEXT,
    tokens INTEGER,
    file_count INTEGER
);

CREATE TABLE IF NOT EXISTS project_summary (
    workspace TEXT PRIMARY KEY,
    summary TEXT,
    total_files INTEGER,
    total_loc INTEGER,
    indexed_at INTEGER
);

CREATE INDEX idx_file_path ON file_summaries(file_path);
CREATE INDEX idx_package ON package_summaries(package_path);
EOF
}

# Build summaries (one-time, battery-friendly)
build_summaries_mobile() {
    local dir="$1"
    local batch_size=10  # Process in small batches
    local sleep_time=5    # Cool down between batches

    info "Building summaries in battery-friendly mode..."
    info "This will take 30-60 min for 100K LOC, but won't drain battery"

    # Level 2: File summaries (in batches)
    find "$dir" -type f \( -name "*.py" -o -name "*.js" -o -name "*.sh" \) | \
    while IFS= read -r file; do
        # Check if already summarized
        existing=$(sqlite3 "$DB" \
            "SELECT summary FROM file_summaries WHERE file_path='$file'")

        if [[ -n "$existing" ]]; then
            continue  # Skip already processed
        fi

        # Summarize file
        content=$(cat "$file")
        summary=$(call_api "Summarize in 2 sentences: $content" \
                          "gemini" "2.5-flash")

        # Store in SQLite
        sqlite3 "$DB" \
            "INSERT OR REPLACE INTO file_summaries VALUES (
                '$file',
                '$summary',
                $((${#content} / 4)),
                $(date +%s)
            )"

        info "✓ Summarized: $file"

        # Battery-friendly: process in batches with cooldown
        if (( ++count % batch_size == 0 )); then
            info "Processed $count files, cooling down for ${sleep_time}s..."
            sleep "$sleep_time"
        fi
    done

    # Level 3: Package summaries
    find "$dir" -type d | while read pkg; do
        files_in_pkg=$(sqlite3 "$DB" \
            "SELECT summary FROM file_summaries WHERE file_path LIKE '$pkg/%'")

        if [[ -z "$files_in_pkg" ]]; then
            continue
        fi

        pkg_summary=$(call_api "Combine these: $files_in_pkg" \
                               "gemini" "2.5-flash")

        sqlite3 "$DB" \
            "INSERT OR REPLACE INTO package_summaries VALUES (
                '$pkg',
                '$pkg_summary',
                $((${#pkg_summary} / 4)),
                $(echo "$files_in_pkg" | wc -l)
            )"
    done

    # Level 4: Project summary
    all_pkgs=$(sqlite3 "$DB" "SELECT summary FROM package_summaries")
    project_summary=$(call_api "Summarize this project: $all_pkgs" \
                               "claude" "3.5-haiku")

    sqlite3 "$DB" \
        "INSERT OR REPLACE INTO project_summary VALUES (
            '$dir',
            '$project_summary',
            $(find "$dir" -type f | wc -l),
            $(find "$dir" -type f -exec wc -l {} + | tail -1 | awk '{print $1}'),
            $(date +%s)
        )"

    success "✓ Hierarchical index complete!"
}

# Query with drill-down (fast, no battery drain)
query_mobile() {
    local question="$1"

    # Start at Level 4
    l4=$(sqlite3 "$DB" \
        "SELECT summary FROM project_summary LIMIT 1")

    # Ask which packages are relevant (cheap model)
    relevant_pkgs=$(call_api "Which packages for: $question? Project: $l4" \
                            "gemini" "2.5-flash")

    # Get Level 3 summaries
    l3_context=$(sqlite3 "$DB" \
        "SELECT package_path, summary FROM package_summaries
         WHERE package_path IN ($relevant_pkgs)")

    # Ask which files are relevant
    relevant_files=$(call_api "Which files for: $question? Context: $l3_context" \
                              "gemini" "2.5-flash")

    # Get actual code (Level 1)
    final_context=""
    echo "$relevant_files" | while read file; do
        final_context+="--- $file ---\n$(cat $file)\n\n"
    done

    # Final answer (use better model)
    call_api "Answer: $question\n\nContext:\n$final_context" \
             "claude" "3.5-sonnet"
}
```

**Performance on Mobile (100K LOC):**

| Phase | Time | Battery | Network |
|-------|------|---------|---------|
| Setup | 2 min | Minimal | ~5MB |
| Initial indexing | 30-60 min | ~10-15% | ~$0.03 |
| Per query | 5-10 sec | Minimal | ~$0.001 |

**Why this wins on mobile:**
- ✅ **Lightweight**: Only SQLite (pre-installed)
- ✅ **Battery-friendly**: Indexing has cooldown periods
- ✅ **Incremental**: Can pause/resume indexing
- ✅ **Low memory**: <100MB RAM usage
- ✅ **Fast queries**: No ML inference needed
- ✅ **Offline-capable**: Summaries cached locally

---

### 🟡 ALTERNATIVE: Lightweight RAG with SQLite

If you want semantic search but lighter than full RAG:

```bash
# Use smaller embedding model
pkg install python
pip install sentence-transformers

# Use ONLY this tiny model:
# "paraphrase-MiniLM-L3-v2" - 17MB (vs 80MB)
```

**Hybrid approach:**

```python
# Store embeddings in SQLite (not ChromaDB)
import sqlite3
from sentence_transformers import SentenceTransformer

# Use tiny model
model = SentenceTransformer('paraphrase-MiniLM-L3-v2')  # 17MB!

# Store in SQLite
conn = sqlite3.connect('~/.aiwb/embeddings.db')
conn.execute('''
    CREATE TABLE IF NOT EXISTS code_chunks (
        id INTEGER PRIMARY KEY,
        file_path TEXT,
        content TEXT,
        embedding BLOB
    )
''')

# Embedding vectors stored as BLOB
# Search using SQL (slower than ChromaDB but works)
```

**Performance:**
- Setup: 10-15 min
- Dependencies: ~100MB (vs 300MB full RAG)
- Indexing: 1-2 hours
- Queries: 2-3 sec (slower than ChromaDB but acceptable)

**Verdict**: Good middle ground if you need semantic search

---

## Final Recommendation for Termux

### For Most Users: **Hierarchical + SQLite**

```bash
# Commands to add to AIWB for mobile
aiwb mobile-index        # Build hierarchy (30-60 min, battery-safe)
aiwb mobile-query "..."  # Fast queries (5-10 sec)
aiwb mobile-status       # Show index status
```

**Why:**
- No heavy dependencies
- Battery-friendly indexing
- Fast enough for mobile use
- Can run in background (Termux:Boot)

### For Power Users: **Lightweight RAG**

```bash
aiwb rag-mobile-setup    # Install tiny embedding model
aiwb rag-mobile-index    # Index with 17MB model
aiwb rag-mobile-query    # Semantic search
```

**Why:**
- Better search quality
- Still reasonable on battery
- Only 100MB overhead

### AVOID: **Agent Swarm**

Too heavyweight for mobile. Don't even try.

---

## Practical Example: Termux Workflow

```bash
# ===== ONE-TIME SETUP (30-60 min) =====

# 1. Install AIWB
cd ~/storage/shared/Projects/my-large-app
aiwb init

# 2. Build mobile-optimized index
aiwb mobile-index --battery-safe

# Battery-safe mode:
# - Processes 10 files at a time
# - 5-second cooldown between batches
# - Can be interrupted (Ctrl+C) and resumed

# Watch progress
# [████████░░░░░░] 45% (90/200 files)
# Next cooldown in 3s...

# ===== DAILY USAGE (seconds) =====

# Query your codebase
aiwb mq "How does authentication work?"
# → Searches SQLite hierarchy
# → Returns answer in 5-10 seconds
# → Battery: ~1%

aiwb mq "Find all database queries"
aiwb mq "What are the API endpoints?"

# ===== INCREMENTAL UPDATES =====

# After git pull
git pull
aiwb mobile-update  # Only re-indexes changed files (< 1 min)
```

---

## Storage Requirements (Termux)

For 100K LOC codebase:

| Approach | Storage | Setup Time | Query Time |
|----------|---------|------------|------------|
| **Hierarchical + SQLite** | 5MB | 30-60 min | 5-10 sec |
| **Lightweight RAG** | 120MB | 1-2 hours | 2-3 sec |
| **Full RAG** | 350MB | 2-4 hours | 1-2 sec |
| **Agent Swarm** | 500MB+ | N/A | N/A |

---

## Battery Impact Estimates

For 100K LOC initial indexing:

| Approach | Battery Drain | Can Background? |
|----------|---------------|-----------------|
| **Hierarchical** | 10-15% | ✅ Yes (Termux:Boot) |
| **Lightweight RAG** | 25-35% | ✅ Yes |
| **Full RAG** | 50-60% | ⚠️ Not recommended |
| **Agent Swarm** | 80%+ | ❌ No |

---

## Implementation Priority for AIWB Mobile

**Phase 1: Add Hierarchical + SQLite**
- New file: `lib/mobile.sh`
- Commands: `mobile-index`, `mobile-query`, `mobile-status`
- Dependencies: SQLite (already installed)
- Time to implement: 2-3 days

**Phase 2: Optimize for Termux**
- Battery-safe mode (cooldown periods)
- Background indexing support
- Incremental updates
- Progress indicators

**Phase 3: Optional Lightweight RAG**
- Tiny embedding model (17MB)
- SQLite-based vector storage
- Hybrid search (keyword + semantic)

---

## Bottom Line

**For Termux/Mobile → Use Hierarchical Summarization + SQLite**

- ✅ Lightest dependencies (SQLite only)
- ✅ Battery-friendly
- ✅ Fast enough (5-10 sec queries)
- ✅ Works on all Android devices
- ✅ Can run in background
- ✅ Incremental updates

**Only use RAG if:**
- You have a powerful phone (8GB+ RAM)
- You're on WiFi (not mobile data)
- You'll query very frequently (>100 times)
- You need semantic search

**Never use Agent Swarm on mobile** - it's designed for servers.
