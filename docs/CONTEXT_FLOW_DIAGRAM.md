# AIWB Context Flow Diagram

## Complete Context Processing Pipeline

```
USER INPUT
    │
    └──> /make mode menu
            │
            ├─ [Set Prompt]
            │   └─> MODE_PROMPT = "Create REST API"
            │
            ├─ [Set Instruction File]
            │   └─> MODE_INSTRUCT_FILE = "./spec.md"
            │
            ├─ [Upload Context]
            │   ├─ Browse files
            │   ├─ Browse directories
            │   └─> MODE_UPLOADS = ["./src", "./docs"]
            │
            ├─ [Select Model]
            │   └─> MODE_MODEL_PROVIDER = "gemini"
            │       MODE_MODEL_NAME = "2.5-flash"
            │
            ├─ [Verification (Optional)]
            │   └─> MODE_CHECK_PROVIDER = "claude"
            │       MODE_CHECK_MODEL = "3.5-sonnet"
            │
            └─ [Run] ──────────────────────────────────────┐
                                                            │
                                                            ▼
            ┌───────────────────────────────────────────────────────┐
            │        MODE_RUN() - Context Assembly                  │
            │       (lib/modes.sh:740-960)                          │
            └───────────────────────────────────────────────────────┘
                                    │
                ┌───────────────────┼───────────────────┐
                │                   │                   │
                ▼                   ▼                   ▼
            LOAD PROMPT         IDENTIFY               BUILD
            FROM SOURCE         IMAGE FILES           CONTEXT
            ├─ Text            │                    │
            └─ File            ├─ PNG/JPG/GIF       ├─ "=== CONTEXT FILES ===" header
                               └─ WebP/BMP          │
                                                     ├─ For each text file:
                                                     │   └─ "--- File: [path] ---"
                                                     │       $(cat "$file")
                                                     │
                                                     ├─ For each directory:
                                                     │   └─ "--- Directory: [path] ---"
                                                     │       $(find ... | head -5 | while read f
                                                     │             echo "File: $f"
                                                     │             head -20 "$f"
                                                     │       done)
                                                     │
                                                     └─ For each image:
                                                         └─ "--- Image: [path] ---"
                                                             [Image will be analyzed]
                
                                │
                                ▼
            ┌─────────────────────────────────────┐
            │   FINAL PROMPT ASSEMBLY             │
            │                                     │
            │  Generate code from scratch:        │
            │  [User prompt/instructions]         │
            │                                     │
            │  === CONTEXT FILES ===              │
            │  --- File: ./src/server.js ---      │
            │  [Full content]                     │
            │  --- Directory: ./docs ---          │
            │  [First 5 files, head -20 each]     │
            │  === CONTEXT IMAGES (N) ===        │
            │  - image1.png                       │
            │  - image2.jpg                       │
            └─────────────────────────────────────┘
                                │
                                ▼
            ┌─────────────────────────────────────┐
            │   TOKEN ESTIMATION (Rough!)         │
            │                                     │
            │   estimate_tokens() {               │
            │     chars = len(final_prompt)       │
            │     tokens = chars / 4              │ ← Very basic!
            │   }                                 │
            │                                     │
            │   input_tokens = X                  │
            │   output_tokens = X * 2             │ ← Rough estimate
            │   total_cost = calculate_cost(...)  │
            └─────────────────────────────────────┘
                                │
                                ▼
            ┌─────────────────────────────────────┐
            │   COST CONFIRMATION DIALOG          │
            │                                     │
            │   Estimated cost: $0.0045           │
            │   Proceed? (yes/no)                 │
            └─────────────────────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
       NO                              YES
        │                               │
        └──> Cancel                     ▼
                            ┌──────────────────────────┐
                            │  SEPARATE CONTENT        │
                            │  for API CALL            │
                            │                          │
                            ├─ Has images?            │
                            │  ├─ YES → Base64 encode │
                            │  │        Store for      │
                            │  │        vision API     │
                            │  └─ NO → Skip           │
                            │                          │
                            └─ Text context → prompt  │
                                        │
                                        ▼
                    ┌───────────────────────────────┐
                    │  DISPATCH TO API              │
                    │  call_api_with_images()?      │
                    │    YES: vision provider       │
                    │    NO:  text-only             │
                    └───────────────────────────────┘
                                │
                    ┌───────────┬───────────┐
                    │           │           │
                    ▼           ▼           ▼
            ┌──────────────────────────────────┐
            │   CALL PROVIDER API              │
            │                                  │
            │  case "$provider" in             │
            │    gemini)  call_gemini() ;;;    │
            │    claude)  call_claude() ;;;    │
            │    openai)  call_openai() ;;;    │
            │    groq)    call_groq() ;;;      │
            │    xai)     call_xai() ;;;       │
            │    ollama)  call_ollama() ;;;    │
            │  esac                            │
            │                                  │
            │  ↓ (sync/blocking)               │
            │  curl -X POST [endpoint]         │
            │    -H "Authorization: Bearer..." │
            │    -H "Content-Type: app/json"   │
            │    -d [full prompt as JSON]      │
            └──────────────────────────────────┘
                            │
                            ▼
            ┌──────────────────────────────────┐
            │   API RESPONSE HANDLING           │
            │                                  │
            │  if [error in response]:         │
            │    → display_api_error()         │
            │    → return error                │
            │                                  │
            │  if [valid response]:            │
            │    → extract text/content        │
            │    → return to caller            │
            └──────────────────────────────────┘
                            │
                            ▼
            ┌──────────────────────────────────┐
            │   OPTIONAL VERIFICATION          │
            │   (if CHECK mode set)            │
            │                                  │
            │  if [ -n "$MODE_CHECK_PROVIDER" ]:
            │    output = call_api()           │
            │      [provider: CHECK provider]  │
            │      [model: CHECK model]        │
            │      [prompt: generated output]  │
            └──────────────────────────────────┘
                            │
                            ▼
            ┌──────────────────────────────────┐
            │   SAVE OUTPUT                    │
            │                                  │
            │  filename = "${mode}_${model}   │
            │            _${timestamp}.md"    │
            │  path = "$workspace/outputs/"    │
            │                                  │
            │  echo "$output" > "$path/$file"  │
            └──────────────────────────────────┘
                            │
                            ▼
            ┌──────────────────────────────────┐
            │   TRACK COSTS                    │
            │                                  │
            │  actual_input_tokens =           │
            │    estimate_tokens(prompt)       │
            │  actual_output_tokens =          │
            │    estimate_tokens(output)       │
            │                                  │
            │  Append to usage.jsonl:          │
            │  {                               │
            │    "timestamp": "...",           │
            │    "provider": "gemini",         │
            │    "model": "2.5-flash",         │
            │    "input_tokens": 1250,         │
            │    "output_tokens": 450,         │
            │    "cost": 0.0045,               │
            │    "mode": "make"                │
            │  }                               │
            └──────────────────────────────────┘
                            │
                            ▼
                        DISPLAY OUTPUT
                        Show preview
                        Offer clipboard copy
```

## Context Memory Model

```
┌─────────────────────────────────────────────────────┐
│              BASH MEMORY LAYOUT                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  MODE State (Global Variables)                     │
│  ├─ MODE_CURRENT         (8 bytes)   - "make"     │
│  ├─ MODE_PROMPT          (varies)    - Full text  │
│  ├─ MODE_INSTRUCT_FILE   (256 bytes) - Path       │
│  ├─ MODE_UPLOADS[]       (varies)    - Array      │
│  ├─ MODE_MODEL_PROVIDER  (32 bytes)  - "gemini"   │
│  ├─ MODE_MODEL_NAME      (64 bytes)  - Model name │
│  ├─ MODE_CHECK_PROVIDER  (32 bytes)  - Verifier   │
│  └─ MODE_CHECK_MODEL     (64 bytes)  - Verifier   │
│                                                     │
│  ────────────────────────────────────────────      │
│                                                     │
│  Prompt Building (Local Variables)                 │
│  ├─ final_prompt         (varies)    - Assembled  │
│  ├─ context_images[]     (varies)    - Image list │
│  └─ has_text_context     (1 byte)    - Boolean    │
│                                                     │
│  ────────────────────────────────────────────      │
│                                                     │
│  Temp Files                                        │
│  ├─ /tmp/aiwb_curl_err_* (varies)    - Error logs │
│  ├─ /tmp/aiwb_curl_out_* (varies)    - Output     │
│  └─ mktemp files         (varies)    - JSON tmp   │
│                                                     │
│  ────────────────────────────────────────────      │
│                                                     │
│  Configuration Files (On Disk)                     │
│  ├─ ~/.aiwb/config.json  (1-2 KB)    - Config     │
│  ├─ ~/.aiwb/.session     (0.5 KB)    - Session    │
│  └─ ~/.aiwb/.aiwb.env    (varies)    - Keys       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Typical Memory Usage During Execution

| Scenario | Memory | Duration | Notes |
|----------|--------|----------|-------|
| Small prompt (< 1KB) | ~2 MB | < 1 sec assembly | Native Bash |
| Medium files (100 files, 10MB total) | ~15 MB | 5-10 sec | All in memory |
| Large context (> 50MB) | 100+ MB | 30+ sec | May cause slowdown |
| API call overhead | +5 MB | Per request | curl + JSON parsing |
| With images (10x 5MB) | +50 MB | N/A | Base64 encoding |

## No Caching/Deduplication

```
Request 1:
  ├─ Load context files
  ├─ Build prompt with all context
  ├─ Send to Gemini
  └─ Get response

Request 2 (with SAME context):
  ├─ Load context files AGAIN  ← Redundant!
  ├─ Build prompt with all context AGAIN  ← Redundant!
  ├─ Send to Claude  ← Full context resent!
  └─ Get response
  
Result: 2x token usage for same context!
```

## No Smart File Selection

```
Directory: ./src (100 files, 50 MB)

Algorithm:
  1. find . | head -5                    ← Only first 5 files!
  2. head -20 "$each_file"               ← Only first 20 lines!
  3. Concatenate into prompt

Issues:
  ✗ Alphabetical order, not relevance
  ✗ May miss important files
  ✗ No language detection
  ✗ No relationship awareness
  ✗ No automatic summarization
```

---

## Performance Characteristics

### Context Building Time (Empirical)

```
Size         Files    Time     Bottleneck
────────────────────────────────────────
< 1 MB       < 50     < 1s     File reads
1-10 MB      50-500   2-5s     Shell operations
10-50 MB     500-5K   10-30s   Variable assignment
> 50 MB      5K+      30s+     Bash hitting limits
```

### Token Estimation Accuracy

```
Actual:  "Hello, world! 123" = 4 tokens
AIWB:    len("Hello, world! 123") / 4 = 18/4 = 4-5 tokens  ✓ Close
         
Actual:  Code block with punctuation = ~50 tokens
AIWB:    Estimate: chars/4 = ~60 tokens  ~ Close

Actual:  Mixed English + code = ~150 tokens  
AIWB:    Estimate: chars/4 = ~180 tokens  △ Off by 20%
```

**Conclusion**: Estimates are rough but usable for pre-flight checks.

---

## Limitations Summary

### Hard Limits (Can't be exceeded)
1. **Bash variable size** - ~256KB in most systems
2. **File descriptor limits** - 1024 open files
3. **Process memory** - Depends on system (typically 1-4 GB for Bash)
4. **API token limits** - Provider-specific (4K-200K per request)

### Soft Limits (Degrade gracefully)
1. **Large files** - Slow, but don't fail
2. **Deep directories** - Only see first 5 files
3. **Token overflow** - Gets caught by API, user must retry

### Missing Features
1. No context compression
2. No caching of results
3. No parallel processing
4. No smart file selection
5. No incremental context loading
6. No semantic relevance scoring

