# 🤖 Shopware 6 AI Developer Tools

Dieses Repository ist eine Sammlung von **Shared Tools**, um KI-gestützte Entwicklung (mit Cursor, Windsurf, Copilot, etc.) in Shopware 6 Projekten zu standardisieren.

Es löst das Hauptproblem lokaler KI-Agenten: **Der Agent läuft auf dem Host (Windows/Mac), aber der Code läuft im Docker Container.**

## ✨ Features

*   **Zero Dependencies:** Benötigt nur Docker. Kein PHP, kein Make, kein Node auf dem Host nötig.
*   **Version Match:** Ermittelt die Shopware-Version aus dem Container und lädt die passenden Coding-Guidelines (PHP Architektur, DAL, etc.) direkt von GitHub.
*   **Docker Bridge:** Generiert Befehle für den Agenten, die automatisch `docker exec` mit der korrekten Container-ID nutzen.
*   **Cross-Platform:** Funktioniert identisch auf Windows (PowerShell/CMD), macOS und Linux.
*   **Umfassender Kontext:** Lädt 14 Guideline-Dateien inkl. Decorator Pattern, Unit Tests, Static Analysis, Database Migrations uvm.

---

## 🚀 Installation in einem Plugin

Füge dieses Repository als **Git Submodule** in dein Shopware-Plugin hinzu. Wir nennen den Ordner `.devtools`, damit er "unsichtbar" bleibt.

```bash
# Im Root deines Plugins ausführen:
git submodule add git@github.com:DEIN-USER/shopware-ai-devtools.git .devtools
```

Füge folgende Zeilen zu deiner `.gitignore` im Plugin hinzu:

```gitignore
# .gitignore
.devtools/
AGENT_INSTRUCTIONS.md
```

---

## 🛠 Nutzung

Sobald das Submodule installiert ist, kannst du die **Agent Instructions** generieren lassen.

### 1. Docker Umgebung starten
Stelle sicher, dass dein Shopware-Container läuft (z.B. via Dockware).

### 2. Generator ausführen

**Windows:**
Doppelklick auf `.devtools\bin\ai-setup.bat` oder im Terminal:
```powershell
.\.devtools\bin\ai-setup.bat
```

**Mac / Linux:**
```bash
./.devtools/bin/ai-setup.sh
```

### 3. Ergebnis
Eine Datei `AGENT_INSTRUCTIONS.md` wird im Root deines Plugins erstellt.
*   Dein KI-Editor (Cursor/Copilot) liest diese Datei automatisch (wenn du sie als Kontext gibst oder via `.cursorrules`).
*   Der Agent weiß nun: "Ich darf kein `php` lokal ausführen, ich muss `docker exec -t ... phpunit` nutzen."

---

## ⚙️ Konfiguration

### Container Name anpassen
Standardmäßig sucht das Skript nach einem Container, der `shopware` im Namen hat. Wenn dein Container anders heißt (z.B. `my-project-web`), übergib den Namen beim Start:

```bash
# Windows
.\.devtools\bin\ai-setup.bat my-project-web

# Mac/Linux
./.devtools\bin\ai-setup.sh my-project-web
```

### Projekt-Spezifischer Kontext (`PLUGIN_CONTEXT.md`)
Wenn du dem Agenten spezifische Infos zu *diesem* Plugin geben willst (z.B. "Dies ist ein B2B-Plugin für Kunde X"), erstelle eine Datei `PLUGIN_CONTEXT.md` im Plugin-Root.
Das Skript hängt den Inhalt dieser Datei automatisch an die generierten Instruktionen an.

---

## ⚡ Pro-Tipp: VS Code Task

Damit du den Befehl nicht immer tippen musst, lege dir einen Task in VS Code an. Erstelle oder bearbeite `.vscode/tasks.json` in deinem Plugin:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "🤖 AI: Update Instructions",
      "type": "shell",
      "command": "${workspaceFolder}/.devtools/bin/ai-setup.sh",
      "windows": {
        "command": ".\\.devtools\\bin\\ai-setup.bat"
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

Jetzt kannst du einfach `Strg+Shift+P` -> `Run Task` -> `🤖 AI: Update Instructions` drücken.

---

## 🏗 Architektur (Wie es funktioniert)

1.  Das Start-Skript (`ai-setup`) startet einen winzigen, temporären Docker-Container (`docker:cli`).
2.  Dieser Container bekommt Zugriff auf den Docker-Socket des Hosts.
3.  Das interne Skript (`src/generate.sh`) sucht den laufenden Shopware-Container.
4.  Es ermittelt die Shopware-Version aus der `composer.lock` im Container.
5.  Es lädt alle relevanten `AGENTS.md` und Coding-Guideline Dateien von GitHub (passend zur Version oder fallback auf `trunk`).
6.  Es kombiniert diese mit den Infrastruktur-Regeln (`src/infrastructure.md`) und schreibt die finale Datei zurück auf deinen Host.
