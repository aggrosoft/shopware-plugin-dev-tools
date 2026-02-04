#!/bin/bash
# Aufruf vom Plugin-Root: ./.devtools/bin/ai-setup.sh

CONTAINER_NAME="${1:-shopware}" # Default "shopware", oder Argument 1

echo "[AI-DEVTOOLS] Starte Generator für Container: $CONTAINER_NAME..."

# Wir mounten das aktuelle Verzeichnis (Plugin Root) nach /workdir
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/workdir \
  docker:cli \
  sh /workdir/.devtools/src/generate.sh "$CONTAINER_NAME"
