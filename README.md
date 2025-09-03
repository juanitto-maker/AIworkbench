AI workbech (AIWB) is a powerful command-line framework for orchestrating a hybrid AI development workflow. It uses a novel **Generator-Verifier** loop, leveraging one AI to create content and another to review and critique it, leading to higher-quality, self-corrected results right from your terminal.


---
## The Core Concept: Generator-Verifier Loop

The most unique feature of AIWB is its collaborative AI workflow. Instead of relying on a single model, it creates a feedback loop:

1.  **Generate**: The user provides a prompt for a task. The "Generator" AI (e.g., Gemini) creates the initial draft.
2.  **Verify**: The "Verifier" AI (e.g., Claude) analyzes the draft and provides a structured review, suggesting improvements, catching errors, or pointing out omissions.
3.  **Refine**: AIWB automatically uses the Verifier's feedback to create a new, refined prompt for the Generator, instructing it to revise its work.

This iterative process mimics a human developer-and-reviewer team, resulting in more robust and well-thought-out output.

---
## Key Features

* **Hybrid AI Workflow**: Unique Generator-Verifier loop using multiple models (currently Gemini and Claude).
* **Project & Task Management**: A complete CLI system for scaffolding and managing your development tasks (`pset`, `tnew`, `tlist`).
* **Pre-flight Cost Estimation**: Get detailed, tiered cost estimates for your API calls *before* you run them, helping you manage your budget (`gpre`, `quote`).
* **Built for the Terminal**: Designed for a fast, keyboard-driven workflow in environments like Linux and Termux.
* **Extensible**: Easily add support for new models, including local LLMs.

---
## Getting Started

Follow these steps to get AIWB running on your system.

### 1. Clone the Repository
First, clone the project to your local machine.
```bash
git clone [https://github.com/juanitto-maker/AIworkbenchDEV.git](https://github.com/juanitto-maker/AIworkbenchDEV.git)
cd AIworkbenchDEV

2. Configure Your API Keys
You'll need to provide your own API keys for the AI models.
# Copy the example environment file
cp .env.example .env

# Open the file and add your keys
nano .env

3. Add to Your PATH
To run the AIWB commands from anywhere, add the bin directory to your system's PATH.
# Add this line to your ~/.bashrc or ~/.zshrc file
export PATH="$PATH:$(pwd)/bin"

# Then, reload your shell configuration
source ~/.bashrc

You can now run commands like pset or tnew from any directory!
Example Workflow
Here's how you might use AIWB to write a new script:
 * pset my-cool-project - Create and select a new project.
 * tnew t001 - Create a new task with the ID "t001".
 * tedit t001 - Open the prompt file in an editor to describe the script you want.
 * gpre - Get a cost and feature breakdown before generating.
 * ggo - Run the Generator AI (Gemini) to create the first draft.
 * claude-runner - Run the Verifier AI (Claude) to review the draft.
 * ...and so on!
🚀 Roadmap
AIWB is actively being developed. Here's where we're headed:
 * Phase 1: Foundation & Refinement
   * Consolidate redundant scripts (gpre/quote, ai-clean/tclean).
   * Create a robust install.sh script.
   * Improve documentation and ensure full Linux compatibility.
 * Phase 2: Feature Expansion
   * Add support for more models (OpenAI, Local LLMs via Ollama).
   * Integrate with Git for automatic commit messages.
   * Develop an interactive TUI (Text User Interface) for easier navigation.
 * Phase 3: The Autonomous Vision
   * Create an ai-refine agent to run the hybrid loop autonomously.
   * Empower the AI to modify the file system and refactor code directly.
   * Implement a Test-Driven Generation (TDG) workflow.
Contributing
Contributions are welcome! If you'd like to help, please check out the Roadmap above, look at the open issues, and feel free to submit a pull request.
Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.
License
This project is licensed under the MIT License - see the LICENSE file for details.
Support the Project
If you find AIWB useful, please consider supporting the project by becoming a sponsor! It helps fund development time and API costs.
<a href="https://www.google.com/search?q=https://github.com/sponsors/juanitto-maker">
<img src="https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86" alt="Sponsor">
</a>

-----

