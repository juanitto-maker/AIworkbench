# Context Persistence Implementation Proposal

## Problem Statement

AIWB currently loses context between chat messages. Commands like `/scanrepo` provide initial analysis, but subsequent chat messages cannot reference that context.

## Solution Architecture

### Tier 1: Session Context Persistence (Immediate)

**Goal**: Maintain context within a single AIWB session

**Implementation**:

1. **Session Context File**
   ```bash
   Location: ~/.aiwb/workspace/.context_state
   Format: JSON
   {
     "session_id": "uuid",
     "created_at": "ISO-8601",
     "updated_at": "ISO-8601",
     "context_files": [
       {"path": "...", "added_at": "...", "type": "scan|manual|auto"}
     ],
     "conversation_history": [
       {"role": "user", "content": "...", "timestamp": "..."},
       {"role": "assistant", "content": "...", "timestamp": "..."}
     ],
     "last_scan": {
       "type": "full|selective",
       "output_file": "workspace/outputs/repo_analysis_*.md",
       "timestamp": "...",
       "file_count": 42
     },
     "active": true
   }
   ```

2. **Context Injection Commands**
   ```bash
   /contextload    # Load saved context into current session
   /contextsave    # Manually save current context state
   /contextshow    # Display current context metadata
   /contextclear   # Clear context and start fresh
   /contextrefresh # Re-scan and update context
   ```

3. **Automatic Context Behavior**
   - After `/scanrepo` or `/smartscan`: Auto-save analysis to context state
   - In chat messages: Option to include last N messages as conversation history
   - On session start: Prompt to resume previous context if available

**Files to Modify**:
- `aiwb` (main file): Add context state management functions
- `lib/modes.sh`: Integrate context loading in mode operations
- `lib/config.sh`: Add context state persistence functions

---

### Tier 2: Conversation Threading (Enhanced)

**Goal**: Build multi-turn conversations with context windows

**Implementation**:

1. **Conversation History Buffer**
   ```bash
   # In-memory during session
   CONVERSATION_HISTORY=()  # Array of {role, content, timestamp}
   MAX_HISTORY_TURNS=10     # Configurable limit
   MAX_CONTEXT_TOKENS=32000 # Token budget for context
   ```

2. **Message Assembly with History**
   ```bash
   handle_chat_message() {
     local message="$1"
     local include_history=$(config_get conversation.include_history)

     if [[ "$include_history" == "true" ]]; then
       # Build conversation payload with history
       local conversation_payload=$(build_conversation_with_history "$message")
       response=$(call_api_with_history "$conversation_payload" ...)
     else
       # Current behavior (single message)
       response=$(call_api "$message" ...)
     fi

     # Add to history
     add_to_history "user" "$message"
     add_to_history "assistant" "$response"
   }
   ```

3. **Context Window Management**
   - Estimate token usage (rough: 1 token ≈ 4 chars)
   - Automatic history truncation when approaching limits
   - Smart truncation: Keep first message + recent N messages

4. **Configuration Options**
   ```json
   {
     "conversation": {
       "include_history": true,
       "max_turns": 10,
       "max_context_tokens": 32000,
       "truncate_strategy": "recent|summarize|first_and_recent"
     }
   }
   ```

**Files to Modify**:
- `aiwb`: Add conversation history management
- `lib/api.sh`: Update API calls to support multi-turn conversations
- `lib/config.sh`: Add conversation configuration

---

### Tier 3: Persistent Context Repository (Advanced)

**Goal**: Long-term context storage with semantic search

**Implementation**:

1. **Context Database**
   ```bash
   Location: ~/.aiwb/workspace/.context_db/
   Structure:
     ├── sessions/
     │   └── [session_id].json          # Session metadata + history
     ├── scans/
     │   └── [repo_hash]_[timestamp].json  # Scan results (structured)
     ├── contexts/
     │   └── [context_id].json          # Saved context configurations
     └── index.json                      # Searchable index
   ```

2. **Context Snapshots**
   ```bash
   /contextsnapshot create [name]   # Save current context with name
   /contextsnapshot list            # List all saved contexts
   /contextsnapshot load [name]     # Load a named context
   /contextsnapshot delete [name]   # Delete a snapshot
   ```

3. **Smart Context Search**
   ```bash
   /contextfind [query]  # Search past conversations/scans
   # Uses grep-based search (simple) or embeddings (advanced)
   ```

4. **Session Resume**
   ```bash
   /sessionresume [session_id]  # Resume previous session with full context
   /sessionlist                 # Show available sessions
   ```

**Files to Create**:
- `lib/context_db.sh`: Context database management
- `lib/context_search.sh`: Search and retrieval functions

---

## Context Refresh/Cleanup Strategies

### 1. Manual Cleanup Commands

```bash
/contextclear              # Clear all context, start fresh
/contextrefresh            # Re-scan repository, update context
/contextremove [file]      # Remove specific file from context
/contextreset              # Reset to default (clear history, keep config)
```

### 2. Automatic Cleanup Policies

**Configuration**:
```json
{
  "context_cleanup": {
    "auto_clear_on_exit": false,
    "max_session_age_days": 7,
    "max_conversation_turns": 50,
    "auto_truncate_history": true,
    "cleanup_old_scans": true,
    "max_scans_per_repo": 5
  }
}
```

**Behaviors**:
- **On session start**: Check for stale context (>7 days old), prompt to clear
- **During conversation**: Auto-truncate when exceeding max turns
- **On scan**: Remove old scan results, keep only N most recent
- **On exit**: Optional auto-cleanup based on configuration

### 3. Context Size Awareness

```bash
context_size_check() {
  local total_size=0
  local file_count=0

  # Calculate total context size
  for file in "${MODE_UPLOADS[@]}"; do
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    total_size=$((total_size + size))
    file_count=$((file_count + 1))
  done

  # Estimate tokens (rough: 1 char ≈ 1 token for code)
  estimated_tokens=$((total_size / 4))

  # Warn if approaching limits
  if [[ $estimated_tokens -gt 50000 ]]; then
    echo "⚠️  Context size: ~${estimated_tokens} tokens (${file_count} files)"
    echo "    Consider using /contextoptimize to reduce size"
  fi
}
```

### 4. Intelligent Context Optimization

```bash
/contextoptimize           # Analyze and suggest context reductions
# Features:
# - Identify duplicate content
# - Suggest removing large/binary files
# - Recommend selective scan over full scan
# - Show token usage breakdown by file
```

---

## Implementation Priority

### Phase 1: Core Persistence (Week 1-2)
1. ✅ Session context file (`.context_state`)
2. ✅ `/contextload`, `/contextsave`, `/contextclear` commands
3. ✅ Auto-save scan results to context
4. ✅ Basic session resumption

### Phase 2: Conversation Threading (Week 3-4)
1. ✅ In-memory conversation history
2. ✅ Multi-turn API calls
3. ✅ Context window management
4. ✅ Configuration options

### Phase 3: Advanced Features (Week 5-6)
1. ✅ Context snapshots
2. ✅ Session database
3. ✅ Context search
4. ✅ Cleanup policies

---

## API Provider Considerations

### Multi-turn Support by Provider

| Provider | Multi-turn Support | Implementation Notes |
|----------|-------------------|---------------------|
| **Gemini** | ✅ Yes | `contents[]` array with `role` field |
| **Claude (Anthropic)** | ✅ Yes | `messages[]` array with `role` field |
| **OpenAI** | ✅ Yes | `messages[]` array with `role` field |
| **DeepSeek** | ✅ Yes | OpenAI-compatible API |
| **Groq** | ✅ Yes | OpenAI-compatible API |
| **OpenRouter** | ✅ Yes | OpenAI-compatible API |
| **Ollama** | ✅ Yes | `messages[]` array |
| **Custom** | ⚠️ Varies | Depends on endpoint |

**Key Point**: All major providers support conversation history natively. We just need to structure the payload correctly.

### Example: Gemini Multi-turn Payload

```json
{
  "contents": [
    {"role": "user", "parts": [{"text": "What is this codebase?"}]},
    {"role": "model", "parts": [{"text": "This is a Bash-based AI workbench..."}]},
    {"role": "user", "parts": [{"text": "How does /scanrepo work?"}]}
  ],
  "generationConfig": {...}
}
```

---

## Configuration Schema Updates

### New config.json Sections

```json
{
  "version": "3.1.0",

  "context_management": {
    "persistence_enabled": true,
    "auto_save_on_scan": true,
    "resume_on_start": "prompt",
    "state_file": ".context_state"
  },

  "conversation": {
    "threading_enabled": true,
    "include_history": true,
    "max_turns": 10,
    "max_context_tokens": 32000,
    "truncate_strategy": "recent"
  },

  "context_cleanup": {
    "auto_clear_on_exit": false,
    "max_session_age_days": 7,
    "max_conversation_turns": 50,
    "auto_truncate_history": true,
    "cleanup_old_scans": true,
    "max_scans_per_repo": 5
  }
}
```

---

## File Structure Changes

### New Files to Create

```
lib/
├── context_state.sh      # Session context persistence
├── context_db.sh         # Advanced context database (Phase 3)
├── conversation.sh       # Conversation threading logic
└── context_cleanup.sh    # Cleanup policies and optimization

workspace/
├── .context_state        # Current session context (JSON)
├── .context_db/          # Context database (Phase 3)
│   ├── sessions/
│   ├── scans/
│   ├── contexts/
│   └── index.json
└── contexts/             # Named context snapshots
    └── [name].context.json
```

### Modified Files

```
aiwb                      # Add new commands, integrate context loading
lib/api.sh               # Support multi-turn conversations
lib/config.sh            # Context configuration management
lib/modes.sh             # Load context in modes
```

---

## Testing Strategy

### Test Cases

1. **Basic Persistence**
   - [ ] `/scanrepo` saves context to `.context_state`
   - [ ] Context persists across `/make`, `/debug`, `/tweak` calls
   - [ ] `/contextclear` properly resets state

2. **Conversation Threading**
   - [ ] Multi-turn conversations maintain history
   - [ ] History truncation works correctly
   - [ ] Token limits are respected

3. **Session Resumption**
   - [ ] Can resume context after exiting and restarting
   - [ ] Old context is detected and prompted for cleanup
   - [ ] Multiple sessions don't interfere

4. **Cleanup**
   - [ ] `/contextrefresh` updates scan results
   - [ ] Auto-cleanup removes stale data
   - [ ] Context size warnings appear correctly

### Integration Tests

- Test with each API provider (Gemini, Claude, OpenAI, etc.)
- Test with large repositories (>1000 files)
- Test with long conversations (>20 turns)
- Test context persistence across different platforms (Linux, macOS, Termux)

---

## Performance Considerations

### Token Usage Impact

**Current**: Each message = ~500-2000 tokens (message only)

**With Threading**: Each message = ~5000-50000 tokens (message + history + context)

**Mitigation**:
- Smart truncation strategies
- Configurable history limits
- Selective context loading
- Token budget awareness

### Storage Impact

**Current**: ~10MB for 10 chat logs + 5MB for outputs = 15MB

**With Persistence**: ~15MB base + 5MB per saved context + 10MB per session DB = ~50MB typical

**Mitigation**:
- Compression for old sessions
- Automatic cleanup of old data
- Configurable retention policies

---

## Migration Path

### For Existing Users

1. **Automatic Migration** (v3.0 → v3.1):
   - Create `.context_state` from current session
   - Migrate existing chat logs to structured format (optional)
   - Add new config sections with defaults

2. **Backward Compatibility**:
   - Persistence disabled by default (opt-in)
   - All new commands are additive (no breaking changes)
   - Old behavior available via config flags

3. **User Communication**:
   - Release notes explaining new features
   - Migration guide for enabling persistence
   - Examples of new workflows

---

## Security Considerations

### Context File Security

**Risks**:
- Context files may contain sensitive code/data
- Session state could leak API keys if prompts include them
- Persistent storage increases attack surface

**Mitigations**:
1. **File Permissions**: Set `.context_state` to 600 (owner only)
2. **Sensitive Data Detection**: Warn if context includes files with secrets
3. **Encryption Option**: Support age encryption for context files
4. **Exclusion Patterns**: Honor `.gitignore` and add `.aiwbignore`

### Example Security Config

```json
{
  "context_security": {
    "encrypt_context": false,
    "warn_on_sensitive_files": true,
    "exclude_patterns": [".env", "*.key", "*.pem", "credentials.*"],
    "file_permissions": "600"
  }
}
```

---

## Documentation Updates Required

1. **README.md**: Add section on context persistence
2. **docs/features/CONTEXT_MANAGEMENT.md**: Comprehensive guide
3. **docs/troubleshooting/CONTEXT_ISSUES.md**: Common problems
4. **docs/tutorials/PERSISTENT_CONTEXT.md**: Step-by-step tutorial
5. **CHANGELOG.md**: Document new features in v3.1.0

---

## Example Workflows

### Workflow 1: Resume After Exit

```bash
# Session 1
$ aiwb
> /scanrepo
> "What does the API module do?"
> [AI responds with context]
> exit

# Session 2 (next day)
$ aiwb
⚠️  Found context from previous session (1 day old)
   Resume with previous context? [Y/n] y

✅ Loaded context:
   - Scan: full (127 files, 1 day ago)
   - Conversation: 3 messages

> "Can you show me the authentication flow?"
> [AI responds with memory of previous conversation]
```

### Workflow 2: Named Context Snapshots

```bash
$ aiwb
> /scanrepo
> /contextsnapshot create "initial-analysis"
✅ Saved context snapshot: initial-analysis

# ... work on feature A ...
> /contextclear
> [different work]

# Later, return to feature A
> /contextsnapshot load "initial-analysis"
✅ Loaded context: initial-analysis (127 files, 3 messages)
```

### Workflow 3: Context Optimization

```bash
$ aiwb
> /scanrepo
⚠️  Context size: ~87,000 tokens (342 files)
   This exceeds recommended limits. Run /contextoptimize? [Y/n] y

📊 Context Analysis:
   Large files (>10KB):           23 files, ~45,000 tokens
   Test files:                    89 files, ~22,000 tokens
   Documentation:                 34 files, ~8,000 tokens
   Source code:                  196 files, ~12,000 tokens

💡 Suggestions:
   1. Exclude test files: -89 files, -22,000 tokens
   2. Use /smartscan instead: -215 files, -62,000 tokens
   3. Add specific files to context instead of full scan

Apply suggestion #2? [y/N] y
> /contextclear
> /smartscan
✅ Context optimized: 42 files, ~18,000 tokens
```

---

## Success Metrics

### User Experience Metrics

- **Context Retention**: % of sessions where context persists across messages
- **Resume Rate**: % of sessions resumed from previous state
- **Cleanup Usage**: Frequency of `/contextclear` and `/contextrefresh` usage
- **Context Size**: Average token usage per session

### Technical Metrics

- **API Cost Impact**: Change in token usage (target: <20% increase)
- **Storage Usage**: Average `.context_state` file size (target: <5MB)
- **Performance**: Time to load context (target: <500ms)
- **Error Rate**: Context corruption/loss incidents (target: <0.1%)

---

## Future Enhancements (v3.2+)

1. **Vector Embeddings**: Semantic search over conversation history
2. **Context Sharing**: Export/import contexts between users
3. **Context Templates**: Pre-configured contexts for common tasks
4. **Smart Context Suggestions**: AI-powered context optimization
5. **Multi-repo Context**: Manage context across multiple repositories
6. **Context Diff**: Show changes between context snapshots
7. **Context Analytics**: Visualize context usage over time

---

## Conclusion

This proposal provides a **pragmatic, phased approach** to solving AIWB's context persistence problem:

- **Tier 1** solves immediate pain points (session persistence, basic commands)
- **Tier 2** enables true conversational AI (threading, history)
- **Tier 3** adds advanced features (snapshots, search, databases)

The implementation is **backward compatible**, **platform-agnostic**, and **provider-neutral**, ensuring it works across AIWB's diverse user base and API ecosystem.

**Estimated Development Time**:
- Phase 1 (Core): 40-60 hours
- Phase 2 (Threading): 30-40 hours
- Phase 3 (Advanced): 60-80 hours
- **Total**: 130-180 hours (~4-6 weeks for one developer)

**Risk Assessment**: **Low-Medium**
- Changes are additive, not breaking
- Existing functionality remains unchanged
- Can be rolled out incrementally
- Fallback to current behavior if issues arise
