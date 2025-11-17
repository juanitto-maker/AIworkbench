# AIWB Development Roadmap

This document outlines the development direction and milestones for the AIWB project. It reflects both completed work and future plans.

**Last Updated:** November 2025 (v2.0.1)

## Philosophy

Our goal is to create the most powerful, flexible, and user-friendly command-line AI development environment. We believe in:
* **AI-Native Workflow:** Integrating AI at every step, from concept to code.
* **Hybrid Intelligence:** Leveraging the strengths of multiple AI models through Generator-Verifier loops.
* **User Empowerment:** Giving developers granular control, cost transparency, and clear insights.

---

## ✅ Phase 1: Foundation & Refinement (COMPLETED - v2.0)

**Objective:** Solidify the core system, ensure stability, and streamline the developer experience.

### Completed Features

* ✅ **Code Consolidation & Optimization:**
    * Refactored into modular library system (`lib/common.sh`, `lib/api.sh`, `lib/modes.sh`, etc.)
    * Consistent error handling across all modules
    * Centralized configuration management
    * Eliminated redundant code paths

* ✅ **Robust Installer & Setup:**
    * Fully automated `install.sh` script
    * Dependency checking (bash, curl, jq, gum)
    * Automatic workspace initialization
    * PATH configuration with ~/.local/bin

* ✅ **Cross-Platform Compatibility:**
    * Full support for Linux, macOS, and Android (Termux)
    * Platform-specific adaptations (safe_read, clipboard, paths)
    * CRLF auto-fix for Termux
    * Fallback UI when gum not available

* ✅ **Core Documentation:**
    * Comprehensive README.md and QUICKSTART.md
    * Detailed USAGE.md guide
    * OVERVIEW.md with design philosophy
    * WORKFLOW-GUIDE.md with patterns
    * Platform-specific guides (TERMUX_INSTALL.md)

---

## ✅ Phase 2: Feature Expansion & Model Agnosticism (COMPLETED - v2.0)

**Objective:** Broaden AIWB's capabilities and support a wider range of AI models.

### Completed Features

* ✅ **Modular AI System:**
    * Unified API layer (`lib/api.sh`) supporting multiple providers
    * Plugin architecture for easy provider addition
    * Integrated providers:
        * ✅ Google Gemini (gemini-2.5-flash, gemini-2.0-flash-lite)
        * ✅ Anthropic Claude (claude-3.5-sonnet, claude-3.5-haiku)
        * ✅ OpenAI (gpt-4o, gpt-3.5-turbo)
        * ✅ Groq (llama-3.3-70b-versatile, mixtral-8x7b, vision models)
        * ✅ xAI/Grok (grok-beta, grok-2, grok-code-fast-1)
        * ✅ Ollama (local model support)

* ✅ **Interactive TUI:**
    * Beautiful terminal UI using `gum` with fallback support
    * Interactive menus for model/provider selection
    * File browser with multi-storage support
    * Progress indicators and status displays
    * Colored output and formatting

* ✅ **Mode-Based Workflows:**
    * `/make` mode - Generate from scratch
    * `/tweak` mode - Modify existing code
    * `/debug` mode - Find and fix bugs
    * Structured workflow with prompt, uploads, verification
    * Cost estimation before execution

* ✅ **Cost Management:**
    * Pre-flight cost estimation
    * Real-time usage tracking (usage.jsonl)
    * Per-provider spending breakdown
    * Cost-aware model selection

* ✅ **Security:**
    * Age-encrypted API key storage
    * Secure key management interface
    * Proper file permissions (600 for sensitive files)

---

## 🚧 Phase 3: Enhanced Workflows & Intelligence (In Progress - v2.1)

**Objective:** Add more intelligent workflows, better context handling, and enhanced user experience.

### Planned Features

* **Enhanced Context Management:**
    * 🔲 Automatic context relevance detection
    * 🔲 Smart file filtering based on task type
    * 🔲 Context size optimization
    * 🔲 Incremental context loading

* **Advanced Mode Features:**
    * 🔲 `/plan` mode - Planning and architecture design
    * 🔲 `/refine` mode - Multi-iteration autonomous refinement loop
    * 🔲 Mode-specific templates and presets
    * 🔲 Custom mode creation

* **Git Integration:**
    * ✅ Comprehensive integration plan completed (see GITHUB_INTEGRATION_PLAN.md)
    * 🔲 AI-powered commit message generation from `git diff`
    * 🔲 Pre-commit code review with AI
    * 🔲 Branch analysis and merge conflict resolution
    * 🔲 Changelog generation
    * 🔲 GitHub API integration (issues, PRs, releases)

* **Improved UI/UX:**
    * 🔲 Syntax highlighting in outputs
    * 🔲 Diff visualization for code changes
    * 🔲 Markdown rendering in terminal
    * 🔲 Progress bars for long operations
    * 🔲 Notification system for completion

* **Template System Enhancement:**
    * 🔲 Template marketplace/sharing
    * 🔲 Dynamic template variables
    * 🔲 Template inheritance and composition
    * 🔲 Interactive template builder

---

## 🔮 Phase 4: Autonomous Agent Capabilities (Future - v3.0)

**Objective:** Transform AIWB into a semi-autonomous development partner with agentic capabilities.

### Vision Features

* **Autonomous Refinement Loop:**
    * Fully autonomous Generator-Verifier iterations
    * Intelligent stopping criteria (convergence detection)
    * Quality metrics and improvement tracking
    * Configurable iteration limits and goals

* **File System Agent:**
    * AI can propose and execute file operations (with user confirmation)
    * Multi-file refactoring capabilities
    * Codebase-wide changes with safety checks
    * Automated testing after modifications

* **Test-Driven Generation (TDG):**
    * Generate failing tests based on requirements
    * Generate code to make tests pass
    * Iterative test refinement
    * Coverage analysis and optimization

* **Advanced Prompt Engineering:**
    * Version control for prompts (git-like)
    * Prompt templates with variables
    * A/B testing for prompt effectiveness
    * Community prompt library

* **Workflow Orchestration:**
    * Multi-step workflow definitions
    * Conditional logic and branching
    * Parallel task execution
    * Workflow resumption and rollback

* **Learning System:**
    * Learn from user corrections
    * Project-specific patterns and preferences
    * Custom style guides enforcement
    * Feedback loop for continuous improvement

---

## 🌟 Phase 5: Ecosystem & Integrations (Future - v3.5+)

**Objective:** Build an ecosystem around AIWB with integrations and community features.

### Future Ideas

* **Editor Integrations:**
    * VS Code extension
    * Vim/Neovim plugin
    * Emacs integration
    * JetBrains IDE plugin

* **CI/CD Integration:**
    * GitHub Actions workflow
    * GitLab CI integration
    * Pre-commit hooks
    * Automated code review in PRs

* **Collaboration Features:**
    * Shared workspaces
    * Team templates and presets
    * Usage analytics dashboard
    * Cost allocation for teams

* **API & SDK:**
    * REST API for AIWB operations
    * Python/JavaScript SDK
    * Webhook support
    * Custom provider plugins

* **Multi-Modal Support:**
    * Image analysis and generation
    * Diagram generation (Mermaid, PlantUML)
    * Audio transcription for prompts
    * Screen recording analysis

* **Quality Assurance:**
    * Security vulnerability scanning
    * Code quality metrics
    * Performance analysis
    * Best practices enforcement

---

## Contributing

We encourage contributors to:
* Pick up tasks from the roadmap
* Suggest new features and improvements
* Report bugs and issues
* Improve documentation
* Share templates and workflows

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

---

## Feedback

Your feedback is vital to AIWB's success! Please share:
* Feature requests
* Use cases
* Pain points
* Success stories

**Discussions:** https://github.com/juanitto-maker/AIworkbench/discussions
**Issues:** https://github.com/juanitto-maker/AIworkbench/issues

---

*This roadmap is a living document and will be updated as the project evolves.*
