# Context Persistence Implementation Roadmap

## Quick Start: Minimal Viable Implementation (1-2 days)

If you want the fastest path to solving the immediate problem, implement just these:

### Day 1: Core Persistence
1. **Add `lib/context_state.sh`** (already created)
   - Copy the file provided
   - Source it in main `aiwb` script

2. **Modify `/scanrepo` command** (aiwb:1101-1180)
   ```bash
   # Add after analysis is saved:
   context_state_save_scan "full" "$output_file" "$file_count"
   ```

3. **Modify `/smartscan` command** (aiwb:1183-1244)
   ```bash
   # Add after analysis is saved:
   context_state_save_scan "selective" "$output_file" "$file_count"
   ```

4. **Add `/contextshow` command**
   ```bash
   # Just copy from CONTEXT_COMMANDS_IMPLEMENTATION.sh
   cmd_contextshow() { context_state_show; }
   ```

**Result**: Scans are now persisted. Users can run `/contextshow` to see what was scanned.

### Day 2: Context Loading
5. **Add `/contextload` command**
   - Loads saved scan output into current chat
   - Users can reference scan results in subsequent messages

6. **Add `/contextclear` command**
   - Allows users to start fresh

**Result**: Users can now persist and reuse context!

---

## Full Phase 1 Implementation (1-2 weeks)

### Week 1: Foundation
- [x] Create `lib/context_state.sh` ✅ (already done)
- [ ] Add context commands to main `aiwb`:
  - `/contextload`
  - `/contextsave`
  - `/contextshow`
  - `/contextclear`
  - `/contextrefresh`
  - `/contextremove`
- [ ] Update `/scanrepo` to auto-save
- [ ] Update `/smartscan` to auto-save
- [ ] Add startup context check (resume prompt)
- [ ] Update help text
- [ ] Add config schema updates

### Week 2: Polish & Testing
- [ ] Test on Linux, macOS, Termux
- [ ] Test with all providers (Gemini, Claude, OpenAI, etc.)
- [ ] Test with large repos (>1000 files)
- [ ] Add error handling for edge cases
- [ ] Add size warnings for large contexts
- [ ] Write documentation
- [ ] Update CHANGELOG

---

## Phase 2: Conversation Threading (2-3 weeks)

### Prerequisites
- Phase 1 complete and stable
- Testing infrastructure in place

### Week 3: Multi-turn API Support
- [ ] Implement `build_conversation_payload()`
- [ ] Add provider-specific payload builders:
  - Gemini
  - Claude/Anthropic
  - OpenAI
  - DeepSeek, Groq, OpenRouter
- [ ] Update `lib/api.sh` to support multi-turn
- [ ] Add conversation history tracking

### Week 4: Context Window Management
- [ ] Implement token estimation
- [ ] Add automatic history truncation
- [ ] Add configurable truncation strategies
- [ ] Implement size warnings
- [ ] Add conversation reset option

### Week 5: Testing & Refinement
- [ ] Test threading with each provider
- [ ] Test token limit handling
- [ ] Test long conversations (>50 turns)
- [ ] Optimize API payload sizes
- [ ] Performance tuning
- [ ] Documentation updates

---

## Phase 3: Advanced Features (4-6 weeks)

### Week 6-7: Context Snapshots
- [ ] Create `lib/context_db.sh`
- [ ] Implement snapshot creation
- [ ] Implement snapshot loading
- [ ] Add snapshot management commands
- [ ] Build snapshot index

### Week 8-9: Session Database
- [ ] Design session database schema
- [ ] Implement session storage
- [ ] Add session search
- [ ] Add session resume
- [ ] Build session browser

### Week 10-11: Context Search & Optimization
- [ ] Implement context search (grep-based)
- [ ] Add context optimization analyzer
- [ ] Build context size estimator
- [ ] Add smart cleanup policies
- [ ] Implement auto-cleanup scheduler

### Week 12: Polish & Release
- [ ] Full integration testing
- [ ] Performance benchmarks
- [ ] Security audit
- [ ] Documentation complete
- [ ] Migration guide
- [ ] Release v3.1.0

---

## File Modification Checklist

### New Files to Create
- [x] `lib/context_state.sh` ✅
- [ ] `lib/conversation.sh` (Phase 2)
- [ ] `lib/context_db.sh` (Phase 3)
- [ ] `lib/context_search.sh` (Phase 3)
- [ ] `docs/features/CONTEXT_MANAGEMENT.md`
- [ ] `docs/tutorials/PERSISTENT_CONTEXT.md`

### Files to Modify
- [ ] `aiwb` (main script)
  - Add context command handlers (lines ~2400-2500)
  - Modify `/scanrepo` (lines 1101-1180)
  - Modify `/smartscan` (lines 1183-1244)
  - Add startup context check (lines ~100-150)
  - Update help text (lines ~2100-2200)
- [ ] `lib/api.sh`
  - Add multi-turn conversation support (Phase 2)
  - Update provider handlers for threading
- [ ] `lib/config.sh`
  - Add context config getters/setters
  - Add config migration for v3.0 → v3.1
- [ ] `lib/modes.sh`
  - Integrate context loading in modes
  - Add context awareness to /make /debug /tweak
- [ ] `README.md`
  - Add context management section
  - Update feature list
- [ ] `CHANGELOG.md`
  - Document v3.1.0 changes

### Configuration Changes
- [ ] Add `context_management` section to config schema
- [ ] Add `conversation` section (Phase 2)
- [ ] Add `context_cleanup` section
- [ ] Add `context_security` section
- [ ] Update config version to 3.1.0

---

## Testing Strategy

### Unit Tests (if test framework exists)
- Context state file creation/deletion
- Context file add/remove operations
- Conversation history management
- Token estimation accuracy
- Config migration

### Integration Tests
- Full workflow: scan → save → exit → resume → use
- Multi-turn conversations across providers
- Large repository scanning (>1000 files)
- Context size limit handling
- Platform compatibility (Linux/macOS/Termux)

### User Acceptance Tests
- Scan repo and use context in subsequent messages
- Resume previous session after restart
- Clear context and start fresh
- Context persists across multiple /make operations
- Size warnings appear for large contexts

---

## Dependencies & Requirements

### Required Tools (check availability)
- [x] `jq` - JSON processing (critical for context state)
  - Installation: `apt install jq` / `brew install jq`
  - Fallback: Basic grep-based parsing (limited functionality)
- [x] `gum` (optional) - Interactive prompts
  - Already used in AIWB
  - Fallback: read -p prompts
- [x] `date` - Timestamp generation (already used)
- [x] `stat` - File size checking (already used)

### Platform Compatibility
- [x] Linux - Primary target
- [x] macOS - Full support needed
- [x] Termux - Mobile support (Android)

### API Provider Support
All providers must support multi-turn conversations for Phase 2:
- [x] Gemini - `contents[]` array
- [x] Claude - `messages[]` array
- [x] OpenAI - `messages[]` array
- [x] DeepSeek - OpenAI-compatible
- [x] Groq - OpenAI-compatible
- [x] OpenRouter - OpenAI-compatible
- [x] Ollama - `messages[]` array

---

## Risk Mitigation

### Risk: Breaking Existing Functionality
**Mitigation**:
- All features are additive
- Old behavior preserved
- Feature flags for opt-in
- Extensive testing

### Risk: Performance Degradation
**Mitigation**:
- Context size warnings
- Automatic truncation
- Token budgets
- Lazy loading

### Risk: Storage Bloat
**Mitigation**:
- Automatic cleanup policies
- Configurable retention
- Size monitoring
- User control

### Risk: Cross-platform Issues
**Mitigation**:
- Platform detection (already exists in AIWB)
- Fallback implementations
- Testing on all platforms
- Clear error messages

### Risk: jq Dependency
**Mitigation**:
- Fallback grep-based parsing
- Check jq availability
- Install instructions
- Graceful degradation

---

## Success Criteria

### Phase 1 Success
- [ ] Users can run `/scanrepo` and reference results in later messages
- [ ] Context persists across session restarts
- [ ] Users can clear/refresh context easily
- [ ] No breaking changes to existing workflows
- [ ] Works on all platforms (Linux/macOS/Termux)

### Phase 2 Success
- [ ] Multi-turn conversations work with all providers
- [ ] Token limits are respected
- [ ] History truncation works correctly
- [ ] Users can disable threading if desired
- [ ] API costs increase <20% on average

### Phase 3 Success
- [ ] Users can save/load named context snapshots
- [ ] Session resume works reliably
- [ ] Context search returns relevant results
- [ ] Cleanup policies prevent storage bloat
- [ ] Advanced features are discoverable

---

## Rollback Plan

If issues arise after deployment:

1. **Immediate Rollback**:
   - Set `context_management.persistence_enabled = false` in config
   - All new features disabled
   - Falls back to v3.0 behavior

2. **Partial Rollback**:
   - Disable specific features via config
   - Keep working features active
   - Fix and redeploy incrementally

3. **Full Rollback**:
   - Revert to v3.0.0 git tag
   - Preserve user data (logs, configs)
   - Schedule fix and rerelease

---

## Documentation Plan

### User-Facing Docs
- [ ] **README.md**: Feature overview and quick start
- [ ] **docs/features/CONTEXT_MANAGEMENT.md**: Comprehensive guide
- [ ] **docs/tutorials/PERSISTENT_CONTEXT.md**: Step-by-step tutorial
- [ ] **docs/troubleshooting/CONTEXT_ISSUES.md**: Common problems & solutions

### Developer Docs
- [ ] **ARCHITECTURE.md**: System design and data flows
- [ ] **API.md**: lib/context_state.sh function reference
- [ ] **CONTRIBUTING.md**: How to extend context features

### Release Notes
- [ ] **CHANGELOG.md**: Detailed v3.1.0 changes
- [ ] **MIGRATION.md**: Upgrade guide from v3.0
- [ ] **BREAKING_CHANGES.md**: None expected, but document any

---

## Performance Benchmarks

Target metrics for Phase 1:

| Metric | Target | Measurement |
|--------|--------|-------------|
| Context load time | <500ms | Time to load `.context_state` |
| Context save time | <100ms | Time to save context changes |
| Startup delay | <200ms | Additional time for context check |
| Storage per session | <5MB | Size of `.context_state` file |
| Memory overhead | <10MB | Additional RAM usage |

---

## Communication Plan

### Announcement Strategy
1. **Pre-release**: GitHub issue discussing proposal (get feedback)
2. **Beta release**: v3.1.0-beta for early testers
3. **Stable release**: v3.1.0 with full docs
4. **Follow-up**: Tutorial videos/blog posts

### User Education
1. **In-app**: Show tips on first use of new commands
2. **Help command**: Update `/help` with context commands
3. **Examples**: Add to `/examples` if that exists
4. **Community**: Reddit/Discord announcements

---

## Next Steps

### Immediate (Today)
1. Review this roadmap with team/maintainers
2. Decide on scope (Phase 1 only? All phases?)
3. Create GitHub issue/project board
4. Set up development branch

### Short-term (This Week)
1. Implement minimal viable version (Days 1-2 above)
2. Manual testing on local repos
3. Get user feedback
4. Iterate based on feedback

### Medium-term (This Month)
1. Complete Phase 1 implementation
2. Beta testing with community
3. Documentation writing
4. Release v3.1.0

### Long-term (Next Quarter)
1. Phase 2 implementation (if validated)
2. Phase 3 planning (if Phase 2 successful)
3. Consider AI-powered context optimization
4. Explore vector embeddings for semantic search

---

## Questions to Resolve

Before starting implementation:

1. **Scope**: Implement all phases or just Phase 1?
2. **Timeline**: What's the target release date?
3. **Team**: How many developers available?
4. **Testing**: Is there an existing test framework?
5. **Backwards compatibility**: Support old AIWB versions?
6. **jq requirement**: Make it required or optional?
7. **Default behavior**: Persistence on or off by default?
8. **Migration**: Auto-migrate configs or manual?

---

## Conclusion

This roadmap provides a **clear, phased approach** to implementing context persistence:

- **Quick win** (1-2 days): Basic persistence working
- **Phase 1** (1-2 weeks): Full persistence feature set
- **Phase 2** (2-3 weeks): Conversation threading
- **Phase 3** (4-6 weeks): Advanced features

Start with the minimal implementation to validate the approach, then expand based on user feedback.

**Recommended Starting Point**: Implement the "Quick Start" (Days 1-2) first, get feedback, then decide on full Phase 1.
