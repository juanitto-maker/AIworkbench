# AIWB Testing Guide

This document describes the testing tools available for AIWB and how to use them.

## Test Scripts Overview

### 1. `test_aiwb_functionality.sh` - Basic Functionality Tests

**Purpose**: Tests basic workspace setup, API connectivity, and simple operations.

**What it tests**:
- Workspace directory structure creation
- Config file integrity
- API key detection
- Basic chat interaction (sends "hi" and exits)
- Cost tracking logs
- Chat history logging

**When to use**: Quick smoke test to verify basic setup is working.

**Usage**:
```bash
./test_aiwb_functionality.sh
```

**Limitations**:
- ❌ Does not test full workflows
- ❌ Does not test menu navigation
- ❌ Does not test different modes
- ❌ Does not validate output quality
- ❌ Does not test error handling

---

### 2. `test_aiwb_comprehensive.sh` - Comprehensive Functionality Tests ⭐

**Purpose**: Thoroughly tests ALL AIWB features including modes, menus, dialogs, workflows, and error handling.

**What it tests**:

#### Mode Tests
- ✅ **Chat Mode**: Full conversation with question answering
- ✅ **Quick Mode**: One-shot code generation
- ✅ **Make Mode**: Complete workflow (prompt → status → run → preview → exit)
- ✅ **Plan Mode**: Planning and structured output

#### Menu & Dialog Tests
- ✅ **Settings Menu**: Navigation and interaction
- ✅ **Help Command**: Display and content

#### Error Handling Tests
- ✅ **Invalid Commands**: Graceful error messages
- ✅ **Empty Input**: No crashes on empty input
- ✅ **Forced Exits**: Detects hangs and timeouts

#### Quality Validation
- ✅ **AI-Powered Validation**: Uses Gemini 2.5-flash to validate output quality (optional)
- ✅ **Completeness Checks**: Ensures outputs aren't truncated
- ✅ **Relevance Checks**: Verifies outputs match request type

**When to use**:
- Before releasing a new version
- After major changes
- When investigating bugs or issues
- For comprehensive quality assurance

**Usage**:
```bash
./test_aiwb_comprehensive.sh
```

---

## Recommended Testing Workflow

### For Daily Development
```bash
# 1. Quick health check
./debug_aiwb.sh

# 2. Basic functionality test
./test_aiwb_functionality.sh
```

### For Release/Major Changes
```bash
# 1. Health check
./debug_aiwb.sh

# 2. Comprehensive testing
./test_aiwb_comprehensive.sh

# 3. Review summary
cat aiwb_comprehensive_summary_*.txt
```

---

## Understanding Test Results

The comprehensive test will output:
- ✓ PASSED - Feature works correctly
- ✗ FAILED - Feature has issues
- ⚠ Issues Detected - Specific problems found

Issue types tracked:
- **Critical**: Crashes, hangs, complete failures
- **Functional**: Missing features, incomplete workflows
- **Quality**: Invalid outputs, truncation

---

## Adding New Tests

See the test script comments for examples of how to add new test functions.
