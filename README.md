# 🤖 Shopware 6 AI Developer Tools

This repository provides shared tooling to standardize AI-assisted development (Cursor, Windsurf, Copilot, etc.) in Shopware 6 projects.

It solves the core local-agent problem: **the AI agent runs on the host (Windows/macOS/Linux), while your code runs inside Docker containers.**

## ✨ Features

- **Zero host dependencies:** Requires Docker only. No local PHP, Make, Node, or npm needed.
- **Version-aware guidelines:** Detects the Shopware version from the running container and fetches matching coding guidelines from GitHub.
- **Docker bridge:** Generates agent instructions that use `docker exec` with the correct container ID.
- **Cross-platform:** Works on Windows (PowerShell/CMD), macOS, Linux, and Git Bash.
- **Rich context bundle:** Loads official guideline documents (architecture, DAL, tests, static analysis, migrations, and more).

---

## 🚀 Quick Start

Run from your plugin root.

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/aggrosoft/shopware-plugin-dev-tools/main/bin/ai-setup.ps1 | iex
```

### macOS / Linux / Git Bash

```bash
curl -fsSL https://raw.githubusercontent.com/aggrosoft/shopware-plugin-dev-tools/main/bin/ai-setup.sh | sh
```

Optional: use a custom container name pattern.

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/aggrosoft/shopware-plugin-dev-tools/main/bin/ai-setup.ps1))) -ContainerName my-project-web
```

```bash
curl -fsSL https://raw.githubusercontent.com/aggrosoft/shopware-plugin-dev-tools/main/bin/ai-setup.sh | sh -s -- my-project-web
```

Recommended `.gitignore` entry in your plugin:

```gitignore
AGENT_INSTRUCTIONS.md
```

---

## 🛠 Usage

After running the one-liner, the tool generates `AGENT_INSTRUCTIONS.md` in your plugin root.

### 1. Start Docker

Make sure your Shopware container is running (for example via Dockware).

### 2. Run the generator

Remote execution:

```powershell
irm https://raw.githubusercontent.com/aggrosoft/shopware-plugin-dev-tools/main/bin/ai-setup.ps1 | iex
```

```bash
curl -fsSL https://raw.githubusercontent.com/aggrosoft/shopware-plugin-dev-tools/main/bin/ai-setup.sh | sh
```

Local checkout execution (if you have this repo under `.devtools`):

```powershell
.\.devtools\bin\ai-setup.bat
```

```bash
./.devtools/bin/ai-setup.sh
```

### 3. Result

`AGENT_INSTRUCTIONS.md` will contain container-aware execution rules and Shopware coding context for your AI assistant.

---

## ⚙️ Configuration

### Custom container name pattern

By default, the script searches for a running container with `shopware` in its name.

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/aggrosoft/shopware-plugin-dev-tools/main/bin/ai-setup.ps1))) -ContainerName my-project-web
```

```powershell
.\.devtools\bin\ai-setup.bat my-project-web
```

```bash
curl -fsSL https://raw.githubusercontent.com/aggrosoft/shopware-plugin-dev-tools/main/bin/ai-setup.sh | sh -s -- my-project-web
```

```bash
./.devtools/bin/ai-setup.sh my-project-web
```

### Project-specific context (`PLUGIN_CONTEXT.md`)

Create `PLUGIN_CONTEXT.md` in your plugin root to inject project-specific notes into the generated instructions.

---

## ⚡ VS Code Task

To avoid typing commands repeatedly, add this task to your plugin's `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "🤖 AI: Update Instructions",
      "type": "shell",
      "command": "curl -fsSL https://raw.githubusercontent.com/aggrosoft/shopware-plugin-dev-tools/main/bin/ai-setup.sh | sh",
      "windows": {
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -Command \"irm https://raw.githubusercontent.com/aggrosoft/shopware-plugin-dev-tools/main/bin/ai-setup.ps1 | iex\""
      },
      "presentation": {
        "reveal": "silent",
        "panel": "shared"
      },
      "problemMatcher": []
    }
  ]
}
```

Then run `Run Task` -> `🤖 AI: Update Instructions`.

---

## 🏗 How It Works

1. `ai-setup` starts a lightweight temporary container (`docker:cli`).
2. The container gets access to the host Docker socket.
3. `src/generate.sh` finds the running Shopware container.
4. It reads the Shopware version from `composer.lock` inside that container.
5. It fetches relevant `AGENTS.md` and coding guideline files from GitHub (version match, fallback to `trunk`).
6. It combines everything with infrastructure execution rules (`src/infrastructure.md`) and writes `AGENT_INSTRUCTIONS.md` to your host project.
