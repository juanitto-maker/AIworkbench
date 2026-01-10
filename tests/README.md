# AIWB Tests

This directory contains automated tests for the AIworkbench (AIWB) project using the [bats-core](https://github.com/bats-core/bats-core) testing framework.

## Prerequisites

Install bats-core:

### Linux (Debian/Ubuntu)
```bash
sudo apt-get install bats
```

### macOS
```bash
brew install bats-core
```

### Termux (Android)
```bash
pkg install bats
```

### Manual Installation
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

## Running Tests

### Run All Tests
```bash
bats tests/*.bats
```

### Run Specific Test File
```bash
bats tests/test_common.bats
bats tests/test_api.bats
bats tests/test_swarm.bats
```

### Run with Verbose Output
```bash
bats -t tests/*.bats
```

### Run in Tap Format (for CI)
```bash
bats -F tap tests/*.bats
```

## Test Structure

Each test file follows this structure:

```bash
#!/usr/bin/env bats

# Setup: Run before each test
setup() {
    # Initialize test environment
    load_lib() {
        source "${BATS_TEST_DIRNAME}/../lib/module.sh"
    }
}

# Teardown: Run after each test
teardown() {
    # Clean up test environment
}

# Test case
@test "description of what is being tested" {
    load_lib
    run function_to_test "args"
    [ "$status" -eq 0 ]
    [ "$output" = "expected_output" ]
}
```

## Test Files

- **test_common.bats** - Tests for `lib/common.sh` (platform detection, utilities)
- **test_api.bats** - Tests for `lib/api.sh` (API key management, image handling)
- **test_swarm.bats** - Tests for `lib/swarm.sh` (swarm mode, multi-agent processing)
- **test_config.bats** - Tests for `lib/config.sh` (configuration management)
- **test_error_handlers.bats** - Tests for error handling functions

## Adding New Tests

To add tests for a new module:

1. Create a new test file: `tests/test_<module>.bats`
2. Add the bats shebang: `#!/usr/bin/env bats`
3. Set up your test environment in `setup()`
4. Write test cases using `@test "description" { ... }`
5. Clean up in `teardown()` if needed

### Test Naming Conventions

- Test files: `test_<module>.bats`
- Test names: Descriptive sentence of what is being tested
- Example: `@test "get_api_key returns key for valid provider"`

### Assertions

Common bats assertions:

```bash
[ "$status" -eq 0 ]           # Command succeeded
[ "$status" -eq 1 ]           # Command failed
[ "$output" = "text" ]        # Exact match
[[ "$output" =~ pattern ]]    # Regex match
[[ -n "$output" ]]            # Output is not empty
[[ -z "$output" ]]            # Output is empty
[[ -f "$file" ]]              # File exists
[[ -d "$dir" ]]               # Directory exists
```

## Test Coverage Goals

| Component | Target Coverage | Current Status |
|-----------|----------------|----------------|
| Critical Functions | 90% | 🟢 Good |
| Utility Functions | 70% | 🟢 Good |
| Swarm Mode | 80% | 🟢 Complete |
| UI Functions | 30% | 🔴 Not Started |

### Recent Test Coverage

- **Swarm Mode**: 19 unit tests + 15 integration tests = 34 tests total ✅
- **API Functions**: 17 tests ✅
- **Common Functions**: 44 tests ✅
- **Total**: 80+ tests passing

## CI/CD Integration

Tests are automatically run on:
- Pull requests
- Pushes to main branch
- Manual workflow dispatch

See `.github/workflows/tests.yml` for CI configuration.

## Troubleshooting

### Tests fail with "command not found"
Make sure bats-core is installed properly:
```bash
which bats
bats --version
```

### Tests fail with "No such file or directory"
Check that you're running tests from the project root:
```bash
cd /path/to/AIworkbench
bats tests/*.bats
```

### Tests fail with permission errors
Ensure test files are executable:
```bash
chmod +x tests/*.bats
```

## Best Practices

1. **Isolation**: Each test should be independent
2. **Cleanup**: Always clean up in `teardown()`
3. **Descriptive Names**: Test names should clearly describe what is being tested
4. **Minimal Setup**: Only set up what's needed for the test
5. **Fast Execution**: Keep tests fast to encourage frequent running
6. **One Assertion Focus**: Each test should focus on one behavior

## Resources

- [bats-core Documentation](https://bats-core.readthedocs.io/)
- [Writing Good Tests](https://github.com/bats-core/bats-core#writing-tests)
- [Testing Best Practices](https://google.github.io/styleguide/shellguide.html#test-files)

## Contributing

When adding new features or fixing bugs:
1. Write tests first (TDD approach recommended)
2. Ensure all tests pass before submitting PR
3. Aim for high test coverage on critical functions
4. Update this README if adding new test categories
