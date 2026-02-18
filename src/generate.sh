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

fetch_url() {
    url="$1"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" 2>/dev/null
        return $?
    fi

    if command -v wget >/dev/null 2>&1; then
        wget -qO- "$url" 2>/dev/null
        status=$?
        if [ $status -eq 0 ]; then
            return 0
        fi

        wget --no-check-certificate -qO- "$url" 2>/dev/null
        return $?
    fi

    return 127
}

append_remote_markdown() {
    url="$1"
    heading="$2"
    source_label="$3"
    section_number="$4"

    tmp_file="/tmp/ai-guideline-$$.md"
    if fetch_url "$url" > "$tmp_file"; then
        if [ -s "$tmp_file" ]; then
            LOADED_GUIDELINES=$((LOADED_GUIDELINES + 1))
            printf "\n### 2.%s %s\n" "$section_number" "$heading" >> "$OUTPUT_FILE"
            echo "> Source: $source_label" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            cat "$tmp_file" >> "$OUTPUT_FILE"
            printf "\n---\n" >> "$OUTPUT_FILE"
            rm -f "$tmp_file"
            return 0
        fi
    fi

    rm -f "$tmp_file"
    return 1
}

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
SW_VERSION=$(docker exec "$CONTAINER_ID" cat "$WEB_ROOT/composer.lock" 2>/dev/null | grep -A2 '"name": "shopware/core"' | grep '"version"' | head -1 | sed 's/.*"version": "\([^"]*\)".*/\1/' | tr -d '\r')

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
TAG_CHECK_FILE="/tmp/ai-tag-check-$$.md"
if fetch_url "$GITHUB_RAW_BASE/$SW_VERSION/AGENTS.md" > "$TAG_CHECK_FILE"; then
    if [ ! -s "$TAG_CHECK_FILE" ]; then
        echo "   -> Tag $SW_VERSION hat keine AGENTS.md, nutze 'trunk'"
        SW_VERSION="trunk"
    fi
else
    echo "   -> Tag $SW_VERSION hat keine AGENTS.md, nutze 'trunk'"
    SW_VERSION="trunk"
fi
rm -f "$TAG_CHECK_FILE"

GITHUB_RAW="$GITHUB_RAW_BASE/$SW_VERSION"

echo "   ... lade Guidelines von GitHub ($SW_VERSION)..."

LOADED_GUIDELINES=0

# 4. Lade die einzelnen AGENTS.md Dateien direkt (ohne Loop-Probleme)
SECTION_NUM=0

# --- ROOT AGENTS.md ---
if append_remote_markdown "$GITHUB_RAW/AGENTS.md" "SHOPWARE ROOT" "$GITHUB_RAW/AGENTS.md" "1"; then
    SECTION_NUM=1
    echo "   -> Geladen: SHOPWARE ROOT"
fi

# --- CODING GUIDELINES CORE INDEX ---
if append_remote_markdown "$GITHUB_RAW/coding-guidelines/core/AGENTS.md" "CODING GUIDELINES (CORE INDEX)" "$GITHUB_RAW/coding-guidelines/core/AGENTS.md" "2"; then
    SECTION_NUM=2
    echo "   -> Geladen: CODING GUIDELINES (CORE INDEX)"
fi

# --- CODING GUIDELINES CORE - Detaillierte Dateien ---
# Feste Liste mit fortlaufender Nummerierung (2.3 bis 2.13)
echo "   ... lade detaillierte Core Guidelines..."

load_guideline() {
    filename="$1"
    title="$2"
    num="$3"

    if append_remote_markdown "$GITHUB_RAW/coding-guidelines/core/$filename" "$title" "$GITHUB_RAW/coding-guidelines/core/$filename" "$num"; then
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
if append_remote_markdown "$GITHUB_RAW/src/Administration/Resources/app/administration/AGENTS.md" "ADMINISTRATION" "$GITHUB_RAW/src/Administration/Resources/app/administration/AGENTS.md" "14"; then
    echo "   -> Geladen: ADMINISTRATION"
fi

echo "   -> Alle Guidelines geladen"

if [ "$LOADED_GUIDELINES" -eq 0 ]; then
    echo "⚠️  WARNUNG: Es konnten keine Shopware Guidelines von GitHub geladen werden." >> "$OUTPUT_FILE"
    echo "⚠️  WARNUNG: Bitte Netzwerk/TLS in Docker pruefen (curl/wget im docker:cli Container)." >> "$OUTPUT_FILE"
    echo "⚠️ [AI-Tool] Keine Guideline-Dateien geladen. Prüfe Internetzugang/TLS im docker:cli Container."
fi

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
