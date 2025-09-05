# AIWB (AI Workbench) 🤖

> Tired of one-shot AI prompts that miss the mark? Stop wrestling with single models. **Start orchestrating them.**

AIWB is a command-line toolkit for developers who want to elevate their AI-driven workflow. It introduces a powerful **Generator-Verifier** loop, turning a simple prompt into a sophisticated, multi-stage collaboration between different AI models.

<div align="center">

[![License: MIT]([[[https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge](https://github.com/juanitto-maker/AIworkbench-core/blob/37ae644e0375d27e177939f1a4f0f3f52e4b2caf/LICENSE.md)](https://github.com/juanitto-maker/AIworkbench-core/blob/37ae644e0375d27e177939f1a4f0f3f52e4b2caf/LICENSE.md)](https://github.com/juanitto-maker/AIworkbench-core/blob/37ae644e0375d27e177939f1a4f0f3f52e4b2caf/LICENSE.md))](https://opensource.org/licenses/MIT)
[![Issues](https://img.shields.io/github/issues/juanitto-maker/AIworkbench-core?style=for-the-badge&color=brightgreen)](https://github.com/juanitto-maker/AIworkbench-core/issues)
[![Last Commit](https://img.shields.io/github/last-commit/juanitto-maker/AIworkbench-core?style=for-the-badge)](https://github.com/juanitto-maker/AIworkbench-core/commits/main)

</div>

---

## 💡 The Core Concept: AI Collaboration

The magic of AIWB is its unique feedback loop. It mimics a professional developer and code reviewer team, resulting in higher-quality, refined output.

graph TD
    A[User Prompt] --> B(AI-Driven Workflow);
    B --> C[Generator];
    C --> D{Verifier};
    D -- Yes --> E(Refined Prompt);
    D -- No --> C;
    E --> F[Output];


---

## ✨ Features at a Glance

| Feature | Description |
| :--- | :--- |
| **Hybrid AI Engine** | Go beyond single-model prompting. Our unique Generator-Verifier loop uses multiple AIs to create, critique, and improve work autonomously. |
| **Smart Cost Control** | Never get a surprise API bill again. The `gpre` and `quote` commands provide detailed, tiered cost estimates *before* you run anything. |
| **Streamlined Workflow** | A full suite of CLI tools (`pset`, `tnew`, `tedit`) lets you manage your projects and tasks without ever leaving the terminal. |
| **Built for the Command Line** | A fast, keyboard-driven interface designed for power users on Linux and Termux. |
| **Open & Extensible** | Easily add new models, including your own local LLMs running on Ollama or other servers. |

---

## 🎬 See It in Action

A quick look at the AIWB workflow, from creating a task to generating the first draft.

**(A short GIF or Asciinema recording of the terminal workflow would be perfect here\!)**

---

## 🚀 Get Started in 3 Steps

Get up and running in minutes.

### 1\. Clone the Repo

```bash
git clone [https://github.com/juanitto-maker/AIworkbench-core.git](https://github.com/juanitto-maker/AIworkbench-core.git)
cd AIworkbench-core
```

### 2\. Configure Your Keys

```bash
# Create your personal environment file from the template
cp .env.example .env

# Add your API keys
nano .env
```

### 3\. Update Your PATH

Make the AIWB commands available from anywhere.

```bash
# Add this line to your ~/.bashrc or ~/.zshrc file
export PATH="$PATH:$(pwd)/bin"

# Reload your shell to apply the changes
source ~/.bashrc

# You're ready! Test it out:
pset my-first-project
```

---

## 🗺️ Roadmap

This project is just getting started. We're on a mission to build the ultimate command-line AI assistant. Join us!

* **💡 Phase 1:** Consolidate core scripts, create a robust installer, and ensure full Linux compatibility.
* **💡 Phase 2:** Add support for more models (OpenAI, Ollama), integrate Git for auto-commits, and build an interactive TUI.
* **💡 Phase 3:** Launch the "Autonomous Agent" that can run the refinement loop independently and perform file system operations.

For a more detailed breakdown of our future plans and milestones, see the [ROADMAP.md](ROADMAP.md) file.

---

## ❤️ Join the Crew & Support

**This is an open-source project built by and for the community.**

* **Contribute:** Have an idea or a bug fix? We'd love your help! Check out our **Roadmap** and open a pull request.
* **Support:** If you find AIWB useful, a coffee helps fuel development and covers API costs. Thank you for your support!

<a href="https://github.com/sponsors/juanitto-maker">
<img src="https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86" alt="Sponsor">
</a>

---

## 📄 Documentation & Overview

For a deeper dive into AIWB's architecture, philosophy, and detailed usage, please consult our dedicated documentation files:

* [OVERVIEW.md](OVERVIEW.md): A high-level look at AIWB's design principles and how it differentiates itself.
* [USAGE.md](USAGE.md): Detailed guides on every command and advanced workflows.
* [CONTRIBUTING.md](CONTRIBUTING.md): How you can get involved.
* [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md): Our guidelines for a respectful community.
* [LICENSE](LICENSE): The legal terms for using AIWB.

