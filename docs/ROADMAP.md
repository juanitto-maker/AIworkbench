# AIWB Development Roadmap

This document outlines the planned future direction and key milestones for the AIWB project. It is a living document and may be updated as the project evolves and community feedback is integrated.

## Philosophy

Our goal is to create the most powerful, flexible, and user-friendly command-line AI development environment. We believe in:
* **AI-Native Workflow:** Integrating AI at every step, from concept to code.
* **Hybrid Intelligence:** Leveraging the strengths of multiple AI models.
* **User Empowerment:** Giving developers granular control and clear insights.

---

## Phase 1: Foundation & Refinement (Current Focus)

**Objective:** Solidify the core system, ensure stability, and streamline the developer experience.

* **Code Consolidation & Optimization:**
    * Merge/retire redundant scripts (e.g., `gpre.sh` and `quote.sh`, `ai-clean.sh` and `tclean.sh`).
    * Refactor helper functions into shared libraries (`scripts/`).
    * Ensure consistent error handling and logging across all scripts.
* **Robust Installer & Setup:**
    * Develop an `install.sh` script to automate dependency checks (jq, curl), directory creation, `.env` setup, and PATH configuration.
    * Improve `.env` management, possibly with an `aiwb-config` command.
* **Cross-Platform Compatibility:**
    * Ensure full compatibility with standard Linux environments (Bash/Zsh).
    * Address Termux-specific dependencies to allow for broader adoption.
* **Core Documentation Enhancement:**
    * Detailed internal comments for all scripts.
    * Comprehensive `docs/` section for installation, core concepts, and basic usage.

---

## Phase 2: Feature Expansion & Model Agnosticism

**Objective:** Broaden AIWB's capabilities and support a wider range of AI models and integrations.

* **Modular AI Runner System:**
    * Refactor `gemini-runner.sh` and `claude-runner.sh` into a single, extensible `ai-runner.sh` with a clear plugin architecture for new models.
    * Integrate popular models:
        * OpenAI (GPT-3.5, GPT-4o)
        * Anthropic (Claude 3 family)
        * **Local LLM Support (High Priority):** Integrate with Ollama or LM Studio for privacy and cost-effective local model inference.
* **Git Integration:**
    * `aiwb-git-commit`: An AI-powered tool to analyze `git diff` and generate intelligent commit messages.
    * `aiwb-git-review`: An AI to review proposed changes (diffs) before committing.
* **Interactive TUI (Text User Interface):**
    * Explore using tools like `gum` or `dialog` to create an interactive terminal dashboard for project, task, and prompt management.
* **Multi-Modal Input:**
    * Expand `uin.sh` to not just upload but potentially describe image content using multi-modal models.

---

## Phase 3: The Autonomous AIWB Agent

**Objective:** Transform AIWB from a workbench into a semi-autonomous development partner.

* **The `aiwb-refine` Command (Autonomous Loop):**
    * An agent that orchestrates the Generator-Verifier loop autonomously for a specified number of iterations or until output stabilizes.
    * Implement intelligent stopping criteria (e.g., minimal changes between iterations, task completion detection).
* **File System Agent Capabilities:**
    * Empower the AI (with user confirmation) to execute commands to modify files directly (e.g., `sed`, `awk`, `mv`) based on a prompt.
    * Enable AI to refactor code across multiple files.
* **Test-Driven Generation (TDG):**
    * A workflow where AIWB generates failing unit tests for a feature, then generates the code to make those tests pass.
* **Advanced Prompt Engineering Features:**
    * Version control for prompts.
    * Prompt templating system.

---

We encourage contributors to pick up tasks from the roadmap or suggest new ideas. Your feedback and contributions are vital to AIWB's success!
