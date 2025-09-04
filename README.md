# AIWB (AI Workbench) 🤖

> Tired of one-shot AI prompts that miss the mark? Stop wrestling with single models. **Start orchestrating them.**

AIWB is a command-line toolkit for developers who want to elevate their AI-driven workflow. It introduces a powerful **Generator-Verifier** loop, turning a simple prompt into a sophisticated, multi-stage collaboration between different AI models.

<div align="center">

![License: MIT](https://img.shields.io/github/license/juanitto-maker/AIworkbenchDEV?style=for-the-badge&color=blue)
![Issues](https://img.shields.io/github/issues/juanitto-maker/AIworkbenchDEV?style=for-the-badge&color=brightgreen)
![Last Commit](https://img.shields.io/github/last-commit/juanitto-maker/AIworkbenchDEV?style=for-the-badge)

</div>

---

## 💡 The Core Concept: AI Collaboration

The magic of AIWB is its unique feedback loop. It mimics a professional developer and code reviewer team, resulting in higher-quality, refined output.

```mermaid
graph TD
    subgraph AIWB Workflow
        A[User Prompt] --> B{Generator};
        B -- Drafts --> C[Draft Output];
        C --> D{Verifier};
        D -- Critiques --> E[Feedback];
        E --> F{AIWB Refines Prompt};
        F -- Instructs --> B;
    end




✨ Features at a Glance
| Feature | Description |
| :--- | :--- |
| **Hybrid AI Engine** | Go beyond single-model prompting. Our unique Generator-Verifier loop uses multiple AIs to create, critique, and improve work autonomously. |
| **Smart Cost Control** | Never get a surprise API bill again. The `gpre` and `quote` commands provide detailed, tiered cost estimates *before* you run anything. |
| **Streamlined Workflow** | A full suite of CLI tools (`pset`, `tnew`, `tedit`) lets you manage your projects and tasks without ever leaving the terminal. |

| Built for the Command Line | A fast, keyboard-driven interface designed for power users on Linux and Termux. |
| Open & Extensible | Easily add new models, including your own local LLMs running on Ollama or other servers. |
🎬 See It in Action
A quick look at the AIWB workflow, from creating a task to generating the first draft.
(A short GIF or Asciinema recording of the terminal workflow would be perfect here!)
🚀 Get Started in 3 Steps
Get up and running in minutes.
1. Clone the Repo
git clone [https://github.com/juanitto-maker/AIworkbenchDEV.git](https://github.com/juanitto-maker/AIworkbenchDEV.git)
cd AIworkbenchDEV

2. Configure Your Keys
# Create your personal environment file from the template
cp .env.example .env

# Add your API keys
nano .env

3. Update Your PATH
Make the AIWB commands available from anywhere.
# Add this line to your ~/.bashrc or ~/.zshrc file
export PATH="$PATH:$(pwd)/bin"

# Reload your shell to apply the changes
source ~/.bashrc

# You're ready! Test it out:
pset my-first-project

🗺️ The Future of AIWB
This project is just getting started. We're on a mission to build the ultimate command-line AI assistant. Join us!
 * 💡 Phase 1: Consolidate core scripts, create a robust installer, and ensure full Linux compatibility.
 * 💡 Phase 2: Add support for more models (OpenAI, Ollama), integrate Git for auto-commits, and build an interactive TUI.
 * 💡 Phase 3: Launch the "Autonomous Agent" that can run the refinement loop independently and perform file system operations.
❤️ Join the Crew & Support
This is an open-source project built by and for the community.
 * Contribute: Have an idea or a bug fix? We'd love your help! Check out our Roadmap and open a pull request.
 * Support: If you find AIWB useful, a coffee helps fuel development and covers API costs. Thank you for your support!
<a href="https://www.google.com/search?q=https://github.com/sponsors/juanitto-maker">
<img src="https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86" alt="Sponsor">
</a>

