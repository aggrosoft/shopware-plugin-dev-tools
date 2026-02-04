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
echo -e "\n## 1. 🏗️ INFRASTRUCTURE & EXECUTION (PRIORITY 1)" >> "$OUTPUT_FILE"
echo "The following commands are tailored to the currently running Docker container ($CONTAINER_ID)." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if [ -f "$INFRA_TEMPLATE" ]; then
    # Wir injizieren die echte Container ID in das Template
    sed "s/{{CONTAINER_ID}}/$CONTAINER_ID/g" "$INFRA_TEMPLATE" >> "$OUTPUT_FILE"
else
    echo "⚠️ Warning: Infrastructure template not found at $INFRA_TEMPLATE" >> "$OUTPUT_FILE"
fi

# --- PART 2: SHOPWARE GUIDELINES (Harvested from Container) ---
echo -e "\n\n---\n\n## 2. 📘 SHOPWARE CODING GUIDELINES" >> "$OUTPUT_FILE"
echo "These guidelines are extracted directly from the installed Shopware version." >> "$OUTPUT_FILE"

echo "   ... extrahiere Guidelines aus dem Container..."

# Wir führen einen find-Befehl IM Shopware-Container aus
# 1. Suche alle AGENTS.md unterhalb von vendor/shopware/.../coding-guidelines
# 2. Iteriere über die Ergebnisse
docker exec "$CONTAINER_ID" sh -c 'find vendor/shopware -type f -path "*/coding-guidelines/*/AGENTS.md" 2>/dev/null | sort' | while read file; do

    # Pfad-Parsing um den Typ zu ermitteln (core, storefront, administration)
    # Beispiel: vendor/shopware/core/coding-guidelines/core/AGENTS.md -> CORE
    DOMAIN=$(echo "$file" | sed -E 's/.*coding-guidelines\/([a-z0-9-]+)\/AGENTS.md/\1/' | tr '[:lower:]' '[:upper:]')

    echo -e "\n### 2.x $DOMAIN GUIDELINES" >> "$OUTPUT_FILE"
    echo "> Source: $file" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Inhalt der Datei aus dem Container lesen und anhängen
    docker exec "$CONTAINER_ID" cat "$file" >> "$OUTPUT_FILE"

    echo -e "\n---\n" >> "$OUTPUT_FILE"
done

# --- PART 3: PROJEKT KONTEXT ---
echo -e "\n## 3. 🎯 PROJECT SPECIFICS" >> "$OUTPUT_FILE"

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
