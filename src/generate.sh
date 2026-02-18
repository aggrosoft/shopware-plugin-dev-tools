#!/bin/sh

# ------------------------------------------------------------------------------
# 🤖 SHOPWARE AI INSTRUCTION GENERATOR (Running inside Docker)
# ------------------------------------------------------------------------------

# Argumente & Pfade
SERVICE_NAME_PATTERN="${1:-shopware}" # Default: suche nach "shopware"
WORK_DIR="/workdir"                   # Hierhin ist das Plugin gemountet
OUTPUT_FILE="$WORK_DIR/AGENT_INSTRUCTIONS.md"

# Interne Pfade (Relativ zum Submodule)
INFRA_TEMPLATE="$WORK_DIR/.devtools/src/infrastructure.md"
PROJECT_CONTEXT="$WORK_DIR/PLUGIN_CONTEXT.md"

echo "🔍 [AI-Tool] Suche Container mit Namensmuster: '$SERVICE_NAME_PATTERN'..."

# 1. Container ID ermitteln
# Wir nutzen docker ps, filtern nach Namen und nehmen die erste ID
CONTAINER_ID=$(docker ps -q -f name="$SERVICE_NAME_PATTERN" | head -n 1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ [AI-Tool] FEHLER: Kein Container gefunden!"
    echo "   Bitte stelle sicher, dass Docker läuft und der Container '$SERVICE_NAME_PATTERN' im Namen hat."
    echo "   Verfügbare Container:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    exit 1
fi

echo "✅ [AI-Tool] Ziel-Container gefunden: $CONTAINER_ID"
echo "🚀 [AI-Tool] Generiere Instruktionen..."

# ------------------------------------------------------------------------------
# GENERIERUNG STARTEN
# ------------------------------------------------------------------------------

# Header schreiben
echo "# 🤖 SHOPWARE 6 AI AGENT INSTRUCTIONS" > "$OUTPUT_FILE"
echo "> **CONTEXT**: Generated via Docker Tooling on $(date -u). Execution rules are strict." >> "$OUTPUT_FILE"

# --- PART 1: INFRASTRUKTUR (Local Rules) ---
printf "\n## 1. 🏗️ INFRASTRUCTURE & EXECUTION (PRIORITY 1)\n" >> "$OUTPUT_FILE"
echo "The following commands are tailored to the currently running Docker container ($CONTAINER_ID)." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if [ -f "$INFRA_TEMPLATE" ]; then
    # Wir injizieren die echte Container ID in das Template
    sed "s/{{CONTAINER_ID}}/$CONTAINER_ID/g" "$INFRA_TEMPLATE" >> "$OUTPUT_FILE"
else
    echo "⚠️ Warning: Infrastructure template not found at $INFRA_TEMPLATE" >> "$OUTPUT_FILE"
fi

# --- PART 2: SHOPWARE GUIDELINES (From GitHub) ---
printf "\n\n---\n\n## 2. 📘 SHOPWARE CODING GUIDELINES\n" >> "$OUTPUT_FILE"

echo "   ... ermittle Shopware Version aus Container..."

# 1. Definiere den Web-Root im Container (Standard bei Dockware/Shopware)
WEB_ROOT="/var/www/html"

# 2. Shopware Version aus composer.lock ermitteln
SW_VERSION=$(docker exec -i "$CONTAINER_ID" cat "$WEB_ROOT/composer.lock" 2>/dev/null | grep -A2 '"name": "shopware/core"' | grep '"version"' | head -1 | sed 's/.*"version": "\([^"]*\)".*/\1/' | tr -d '\r')

if [ -z "$SW_VERSION" ]; then
    echo "⚠️  WARNUNG: Shopware Version konnte nicht ermittelt werden." >> "$OUTPUT_FILE"
    SW_VERSION="trunk"  # Fallback auf trunk/main
fi

echo "   -> Shopware Version: $SW_VERSION"
echo "These guidelines are from the official Shopware repository (version: $SW_VERSION)." >> "$OUTPUT_FILE"

# 3. GitHub Raw URL Base
GITHUB_RAW_BASE="https://raw.githubusercontent.com/shopware/shopware"

# Versuche den passenden Branch/Tag zu finden
# Shopware nutzt Tags wie "v6.6.10.5" aber AGENTS.md existiert nur auf trunk/neueren Tags
# Wir prüfen ob der Tag die AGENTS.md hat, sonst fallback auf trunk
echo "   -> Prüfe GitHub Tag $SW_VERSION..."
TAG_CONTENT=$(wget -qO- "$GITHUB_RAW_BASE/$SW_VERSION/AGENTS.md" 2>/dev/null)

if [ -z "$TAG_CONTENT" ]; then
    echo "   -> Tag $SW_VERSION hat keine AGENTS.md, nutze 'trunk'"
    SW_VERSION="trunk"
fi

GITHUB_RAW="$GITHUB_RAW_BASE/$SW_VERSION"

echo "   ... lade Guidelines von GitHub ($SW_VERSION)..."

# 4. Lade die einzelnen AGENTS.md Dateien direkt (ohne Loop-Probleme)
SECTION_NUM=0

# --- ROOT AGENTS.md ---
CONTENT=$(wget -qO- "$GITHUB_RAW/AGENTS.md" 2>/dev/null)
if [ -n "$CONTENT" ]; then
    SECTION_NUM=$((SECTION_NUM + 1))
    printf "\n### 2.%d SHOPWARE ROOT\n" "$SECTION_NUM" >> "$OUTPUT_FILE"
    echo "> Source: $GITHUB_RAW/AGENTS.md" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "$CONTENT" >> "$OUTPUT_FILE"
    printf "\n---\n" >> "$OUTPUT_FILE"
    echo "   -> Geladen: SHOPWARE ROOT"
fi

# --- CODING GUIDELINES CORE INDEX ---
CONTENT=$(wget -qO- "$GITHUB_RAW/coding-guidelines/core/AGENTS.md" 2>/dev/null)
if [ -n "$CONTENT" ]; then
    SECTION_NUM=$((SECTION_NUM + 1))
    printf "\n### 2.%d CODING GUIDELINES (CORE INDEX)\n" "$SECTION_NUM" >> "$OUTPUT_FILE"
    echo "> Source: $GITHUB_RAW/coding-guidelines/core/AGENTS.md" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "$CONTENT" >> "$OUTPUT_FILE"
    printf "\n---\n" >> "$OUTPUT_FILE"
    echo "   -> Geladen: CODING GUIDELINES (CORE INDEX)"
fi

# --- CODING GUIDELINES CORE - Detaillierte Dateien ---
# Feste Liste mit fortlaufender Nummerierung (2.3 bis 2.13)
echo "   ... lade detaillierte Core Guidelines..."

load_guideline() {
    filename="$1"
    title="$2"
    num="$3"
    
    CONTENT=$(wget -qO- "$GITHUB_RAW/coding-guidelines/core/$filename" 2>/dev/null)
    if [ -n "$CONTENT" ]; then
        printf "\n### 2.%d %s\n" "$num" "$title" >> "$OUTPUT_FILE"
        echo "> Source: $GITHUB_RAW/coding-guidelines/core/$filename" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "$CONTENT" >> "$OUTPUT_FILE"
        printf "\n---\n" >> "$OUTPUT_FILE"
        echo "   -> Geladen: $title"
    fi
}

load_guideline "decorator-pattern.md" "Decorator Pattern" 3
load_guideline "extendability.md" "Extendability" 4
load_guideline "unit-tests.md" "Unit Tests" 5
load_guideline "writing-code-for-static-analysis.md" "Static Analysis" 6
load_guideline "domain-exceptions.md" "Domain Exceptions" 7
load_guideline "feature-flags.md" "Feature Flags" 8
load_guideline "database-migations.md" "Database Migrations" 9
load_guideline "internal.md" "Internal API" 10
load_guideline "final-and-internal.md" "Final and Internal" 11
load_guideline "adr.md" "Architecture Decision Records" 12
load_guideline "6.5-new-php-language-features.md" "PHP 8 Language Features" 13

# --- ADMINISTRATION ---
CONTENT=$(wget -qO- "$GITHUB_RAW/src/Administration/Resources/app/administration/AGENTS.md" 2>/dev/null)
if [ -n "$CONTENT" ]; then
    printf "\n### 2.14 ADMINISTRATION\n" >> "$OUTPUT_FILE"
    echo "> Source: $GITHUB_RAW/src/Administration/Resources/app/administration/AGENTS.md" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "$CONTENT" >> "$OUTPUT_FILE"
    printf "\n---\n" >> "$OUTPUT_FILE"
    echo "   -> Geladen: ADMINISTRATION"
fi

echo "   -> Alle Guidelines geladen"

# --- PART 3: PROJEKT KONTEXT ---
printf "\n## 3. 🎯 PROJECT SPECIFICS\n" >> "$OUTPUT_FILE"

if [ -f "$PROJECT_CONTEXT" ]; then
    cat "$PROJECT_CONTEXT" >> "$OUTPUT_FILE"
else
    echo "No specific project context provided (create PLUGIN_CONTEXT.md to add some)." >> "$OUTPUT_FILE"
fi

# ------------------------------------------------------------------------------
# CLEANUP
# ------------------------------------------------------------------------------

# WICHTIG: Da Docker oft als 'root' schreibt, ändern wir die Rechte auf "für alle schreibbar",
# damit der User die Datei auf dem Host auch löschen oder bearbeiten kann.
chmod 666 "$OUTPUT_FILE"

echo "✅ [AI-Tool] Fertig! Datei erstellt: AGENT_INSTRUCTIONS.md"
