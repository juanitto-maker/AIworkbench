# AIWB: Detailed Usage Guide

This document provides in-depth instructions for using all AIWB commands, advanced workflows, and configuration options.

---

## Table of Contents

* [Installation & Setup](01-installation.md) (Link to a sub-page if it gets long)
* [Core Concepts](#core-concepts)
    * [Projects](#projects)
    * [Tasks](#tasks)
    * [Prompts](#prompts)
* [Command Reference](#command-reference)
    * [`pset` - Project Set](#pset---project-set)
    * [`tnew` - Task New](#tnew---task-new)
    * [`tedit` - Task Edit](#tedit---task-edit)
    * [`ggo` - Gemini Go](#ggo---gemini-go)
    * [`claude-runner` - Claude Runner](#claude-runner---claude-runner)
    * [`bridgeg` - Bridge Gemini](#bridgeg---bridge-gemini)
    * [`bridgec` - Bridge Claude](#bridgec---bridge-claude)
    * (Add all other commands here)
* [Advanced Workflows](#advanced-workflows)
    * [The Generator-Verifier Loop](#the-generator-verifier-loop)
    * [Cost Management Strategies](#cost-management-strategies)
* [Configuration](#configuration)
    * [.env Variables](#env-variables)
    * [Customizing Paths](#customizing-paths)

---

## Core Concepts

### Projects

Projects in AIWB serve as containers for related tasks. You can switch between projects, and all tasks created will belong to the currently active project.

* **Setting a Project:**
    ```bash
    pset <project-name>
    ```
    This command creates a new project directory (if it doesn't exist) and sets it as the active project.

### Tasks

Tasks are the fundamental units of work in AIWB. Each task typically corresponds to a specific prompt, an AI generation, and its subsequent review and refinement.

* **Creating a New Task:**
    ```bash
    tnew <task-id>
    ```
    This creates a new directory for the task within the active project and sets up initial files like `prompt.md`.

---

## Command Reference

*(Continue to detail each command with examples)*

### `pset` - Project Set

**Description:** Creates and selects a new AIWB project. If the project already exists, it simply selects it.
**Usage:** `pset <project-name>`
**Example:**
```bash
pset my-first-project
# Output: ✅ Project selected: my-first-project
