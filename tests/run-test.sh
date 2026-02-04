#!/bin/bash

# 1. Wir ermitteln den absoluten Pfad zum Repo-Root (ein Ordner über diesem Skript)
# $(dirname "$0") ist das Verzeichnis des Skripts (tests/)
# ".." geht eins hoch
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 2. Definiere den Dummy-Workspace
TEST_DIR="$REPO_ROOT/tests/dummy_project"
mkdir -p "$TEST_DIR"

# Optional: Erstelle dummy Kontext, um alles zu testen
echo "Dies ist ein Test-Plugin." > "$TEST_DIR/PLUGIN_CONTEXT.md"

echo "🧪 TEST-MODUS"
echo "   Repo Root:  $REPO_ROOT"
echo "   Test Dir:   $TEST_DIR"
echo "------------------------------------------------"

# 3. Docker Run mit korrekten Mounts
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$TEST_DIR":/workdir \
  -v "$REPO_ROOT":/workdir/.devtools \
  docker:cli \
  sh /workdir/.devtools/src/generate.sh "shopware"

echo "------------------------------------------------"
echo "✅ Prüfe das Ergebnis in: tests/dummy_project/AGENT_INSTRUCTIONS.md"
