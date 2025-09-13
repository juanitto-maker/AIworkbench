# AIWB (AI Workbench) 🤖

> Tired of one-shot AI prompts that miss the mark? Stop wrestling with single models. **Start orchestrating them.**

AIWB is a command-line toolkit for developers who want to elevate their AI-driven workflow. It introduces a powerful **Generator-Verifier** loop, turning a simple prompt into a sophisticated, multi-stage collaboration between different AI models.

<div align="center">

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg?style=for-the-badge)](https://www.gnu.org/licenses/gpl-3.0)
[![Issues](https://img.shields.io/github/issues/juanitto-maker/AIworkbench-core?style=for-the-badge&color=brightgreen)](https://github.com/juanitto-maker/AIworkbench-core/issues)
[![Last Commit](https://img.shields.io/github/last-commit/juanitto-maker/AIworkbench-core?style=for-the-badge)](https://github.com/juanitto-maker/AIworkbench-core/commits/main)

</div>

---

## 💡 The Core Concept: AI Collaboration

The magic of AIWB is its unique feedback loop. It mimics a professional developer and code reviewer team, resulting in higher-quality, refined output.

```mermaid
graph TD
    subgraph AIWB Workflow
        A[User Prompt] --> B{Generator};
        B -- Drafts --> C[Code/Text Draft];
        C --> D{Verifier};
        D -- Critiques --> E[Feedback & Revisions];
        E --> F{AIWB Refines Prompt};
        F -- Instructs --> B;
    end
```

---

## ✨ Features at a Glance

| Feature | Description |
| :--- | :--- |
| **Direct Repo Integration** | Set AIWB's context to an existing Git repository to have the AI edit, debug, and refactor your files directly. |
| **Hybrid AI Engine** | Go beyond single-model prompting. Our unique Generator-Verifier loop uses multiple AIs to create, critique, and improve work autonomously. |
| **Smart Cost Control** | Never get a surprise API bill again. The `gpre` and `quote` commands provide detailed, tiered cost estimates *before* you run anything. |
| **Streamlined Workflow** | A full suite of CLI tools (`pset`, `tnew`, `tedit`) lets you manage your projects and tasks without ever leaving the terminal. |
| **Built for the Command Line** | A fast, keyboard-driven interface designed for power users on Linux and Termux. |
| **Open & Extensible** | Easily add new models, including your own local LLMs running on Ollama or other servers. |

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
```

---

## 🗺️ Roadmap

We're on a mission to build the ultimate command-line AI assistant. Join us!

For a detailed breakdown of our future plans, see the [docs/ROADMAP.md](docs/ROADMAP.md) file.

---
# 🚀 Install & First Run

Works on **Android (Termux)**, **Linux**, and **macOS**. Chat is the default interaction; no project/task required.

---

## 0) Dependencies

- **Required:** `bash` (v4+), `curl`, `jq`
- **Optional (recommended):** `gum` (pretty TUI), `git`, `fzf`
- **Termux only:** run once → `termux-setup-storage`

**Install packages**

**Termux**
~~~
pkg update
pkg install bash curl jq git sed coreutils
pkg install gum          # optional but recommended
termux-setup-storage     # allow access to /storage/shared
~~~

**Ubuntu/Debian**
~~~
sudo apt update
sudo apt install bash curl jq git
# gum (optional)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo tee /etc/apt/keyrings/charm.gpg >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum
~~~

**macOS (Homebrew)**
~~~
brew install bash curl jq git gum
~~~

---

## 1) One-liner install

~~~
curl -fsSL https://raw.githubusercontent.com/juanitto-maker/AIworkbench/main/install.sh | bash
~~~

This sets up `~/.aiwb`, installs tools into `~/.local/bin`, and creates a default config.

**Ensure `~/.local/bin` is on PATH (persistently):**
~~~
printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> ~/.bashrc
printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> ~/.profile 2>/dev/null || true
. ~/.bashrc 2>/dev/null || true
hash -r
~~~

**Verify:**
~~~
command -v aiwb && command -v chat-runner.sh
~~~

---

## 2) Add your API keys (stored locally, not in repo)

**Inside AIWB (nice UI):**
~~~
aiwb
/keys     # paste GEMINI_API_KEY and/or ANTHROPIC_API_KEY
/exit
~~~

**Or via shell:**
~~~
printf 'export GEMINI_API_KEY="%s"\n' "paste-your-gemini-key"    >> ~/.aiwb.env
printf 'export ANTHROPIC_API_KEY="%s"\n' "paste-your-claude-key" >> ~/.aiwb.env
chmod 600 ~/.aiwb.env
. ~/.aiwb.env
~~~

---

## 3) Create the default task (required once)

Some helpers expect a default task file. Create it now:

~~~
mkdir -p ~/.aiwb/workspace/tasks
printf "# inbox\n\n" > ~/.aiwb/workspace/tasks/inbox.prompt.md
~~~

---

## 4) Run it 🎉

~~~
aiwb
~~~

Type something like:

## ❤️ Join the Crew & Support

This is an open-source project built by and for the community. Please consider contributing or supporting our work.

<a href="https://github.com/sponsors/juanitto-maker">
<img src="https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86" alt="Sponsor">
</a>
<a href="https://ko-fi.com/guardos">
<img src="https://img.shields.io/static/v1?label=Ko-fi&message=%E2%98%95&logo=ko-fi&color=%2329abe0" alt="Ko-fi">
</a>

---

This project is licensed under the **GPL-3.0 License** - see the [LICENSE](LICENSE) file for details.
