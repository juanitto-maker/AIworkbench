# Contributing to AIWB

Thank you for considering contributing to AIWB! We're excited to build a powerful AI orchestration platform with the community.

## Table of Contents

- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Code Structure](#code-structure)
- [Coding Guidelines](#coding-guidelines)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Code of Conduct](#code-of-conduct)

---

## How Can I Contribute?

### Reporting Bugs

If you find a bug, please [open an issue](https://github.com/juanitto-maker/AIworkbench/issues) with:

- **OS and Platform**: Linux, macOS, or Termux version
- **Shell**: Bash version (`bash --version`)
- **AIWB Version**: Run `aiwb --version`
- **Steps to Reproduce**: Clear, step-by-step instructions
- **Expected vs Actual Behavior**: What should happen vs what happens
- **Logs**: Relevant error messages or logs from `~/.aiwb/workspace/logs/`

**Example:**
```
OS: Ubuntu 22.04
Shell: GNU bash, version 5.1.16
AIWB: v2.0.1

Steps:
1. Run `aiwb`
2. Execute `/make`
3. Run `make> run`

Expected: Cost estimate dialog appears
Actual: Script crashes with "jq: parse error"

Logs: [attach error.log]
```

### Suggesting Enhancements

Have an idea? Great! Please:

1. Check [ROADMAP.md](docs/ROADMAP.md) to see if it's already planned
2. Search [existing issues](https://github.com/juanitto-maker/AIworkbench/issues)
3. Open a new issue with:
   - **Clear description** of the feature
   - **Use case**: Why is this needed?
   - **Proposed solution**: How might it work?
   - **Alternatives considered**: Other approaches

### Contributing Code

We welcome pull requests for:

- Bug fixes
- New features (discuss in an issue first)
- Documentation improvements
- Test additions
- Performance optimizations

---

## Development Setup

### Prerequisites

- `bash` (v4+)
- `jq`
- `curl`
- `git`
- `gum` (optional but recommended)

### Clone and Setup

```bash
# Fork the repo on GitHub first, then:
git clone https://github.com/YOUR-USERNAME/AIworkbench.git
cd AIworkbench

# Run the install script (creates ~/.aiwb/)
./install.sh

# Or for development, run directly from repo
./aiwb
```

### Development Mode

```bash
# Enable debug output
export AIWB_DEBUG=1
./aiwb --debug

# Run tests
./test_aiwb_comprehensive.sh

# Check code style
shellcheck aiwb lib/*.sh
```

---

## Code Structure

```
AIworkbench/
├── aiwb                    # Main entry point (1,886 lines)
├── lib/                    # Core libraries
│   ├── common.sh          # Platform detection, utilities
│   ├── config.sh          # Configuration management
│   ├── ui.sh              # User interface components
│   ├── api.sh             # API integrations
│   ├── modes.sh           # Mode-based workflows
│   ├── error.sh           # Error handling
│   └── security.sh        # Key encryption
├── templates/             # Prompt templates
├── completions/           # Shell completions
├── docs/                  # Documentation
└── examples/              # Usage examples
```

### Key Files

- **`aiwb`**: Main script, command routing, initialization
- **`lib/api.sh`**: All AI provider integrations
- **`lib/modes.sh`**: Mode-based workflow logic (/make, /tweak, /debug)
- **`lib/ui.sh`**: Terminal UI components (gum wrappers + fallbacks)
- **`lib/config.sh`**: Workspace and configuration management

---

## Coding Guidelines

### Bash Best Practices

1. **Use `set -euo pipefail`** in scripts
2. **Quote variables**: `"$var"` not `$var`
3. **Use functions** for reusable code
4. **Add comments** for complex logic
5. **Handle errors** explicitly

### Style Guidelines

```bash
# Good
function my_function() {
    local var="$1"
    [[ -z "$var" ]] && { err "Variable required"; return 1; }

    echo "Processing: $var"
}

# Bad
my_function() {
    echo Processing: $1
}
```

### Naming Conventions

- **Functions**: `snake_case` (e.g., `load_config`, `api_call_gemini`)
- **Global variables**: `SCREAMING_SNAKE_CASE` (e.g., `AIWB_VERSION`)
- **Local variables**: `snake_case` (e.g., `local output`)
- **Private functions**: `_snake_case` (e.g., `_internal_helper`)

### Cross-Platform Compatibility

Always ensure code works on:
- Linux (Ubuntu, Arch, Fedora)
- macOS (via Homebrew bash)
- Android/Termux

```bash
# Use platform detection
if is_termux; then
    # Termux-specific code
elif is_macos; then
    # macOS-specific code
else
    # Linux code
fi

# Use portable commands
have gum && gum input || read -r input  # Fallback
```

### Adding a New AI Provider

1. Add API key env var to `lib/security.sh`
2. Add provider to `lib/api.sh`:
   ```bash
   api_call_newprovider() {
       local model="$1"
       local prompt="$2"
       # Implementation
   }
   ```
3. Add to `lib/config.sh` default models
4. Update documentation

---

## Testing

### Manual Testing

```bash
# Run comprehensive tests
./test_aiwb_comprehensive.sh

# Test specific feature
./aiwb --debug
> /make
make> prompt Test prompt
make> model
make> run
```

### Test Checklist

Before submitting a PR, verify:

- [ ] Works on Linux (or note platform in PR)
- [ ] Works on macOS (if possible)
- [ ] Works on Termux (if possible)
- [ ] No hardcoded paths
- [ ] Error messages are clear
- [ ] `shellcheck` passes (warnings OK if explained)
- [ ] Documentation updated
- [ ] CHANGELOG.md updated (for significant changes)

### Platform Testing

```bash
# Linux/macOS
shellcheck aiwb lib/*.sh

# Termux (on Android)
pkg install shellcheck
shellcheck aiwb lib/*.sh
```

---

## Pull Request Process

### Before Submitting

1. **Create an issue** first for significant changes
2. **Fork** the repository
3. **Create a branch**: `git checkout -b feature/my-feature`
4. **Make changes** following coding guidelines
5. **Test thoroughly**
6. **Update documentation**

### PR Guidelines

**Title Format:**
- `Fix: description` - Bug fixes
- `Feature: description` - New features
- `Docs: description` - Documentation only
- `Refactor: description` - Code refactoring
- `Test: description` - Test additions

**Description Should Include:**
- **What**: What does this PR do?
- **Why**: Why is this change needed?
- **How**: How does it work?
- **Testing**: How was it tested?
- **Screenshots**: For UI changes (if applicable)

**Example:**
```markdown
## Feature: Add support for Mistral AI

**What**: Adds Mistral AI as a new provider option

**Why**: Mistral offers competitive pricing and quality

**How**:
- Added `api_call_mistral()` in lib/api.sh
- Added MISTRAL_API_KEY support
- Added to provider selection menu
- Updated documentation

**Testing**:
- Tested on Linux with Mistral API
- Verified cost tracking works
- Confirmed error handling
```

### Review Process

1. Maintainers will review your PR
2. Address any requested changes
3. Once approved, maintainers will merge

---

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

**In short:**
- Be respectful and inclusive
- Welcome newcomers
- Focus on what's best for the community
- Show empathy towards others

---

## Questions?

- **Discussions**: https://github.com/juanitto-maker/AIworkbench/discussions
- **Issues**: https://github.com/juanitto-maker/AIworkbench/issues
- **Documentation**: [docs/](docs/)

---

**Thank you for contributing to AIWB!** Every contribution, no matter how small, helps make AIWB better for everyone. 🚀
