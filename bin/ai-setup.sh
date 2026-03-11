#!/bin/sh

set -eu

CONTAINER_NAME="${1:-shopware}"
WORKDIR="$(pwd)"
LOCAL_TOOL_ROOT="$WORKDIR/.devtools"
RAW_BASE="${AI_DEVTOOLS_RAW_BASE:-https://raw.githubusercontent.com/aggrosoft/shopware-plugin-dev-tools/main}"

echo "[AI-DEVTOOLS] Starting generator for container pattern: $CONTAINER_NAME"

if [ -f "$LOCAL_TOOL_ROOT/src/generate.sh" ]; then
  echo "[AI-DEVTOOLS] Using local tooling from .devtools"
  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$WORKDIR":/workdir \
    docker:cli \
    sh /workdir/.devtools/src/generate.sh "$CONTAINER_NAME"
  exit $?
fi

echo "[AI-DEVTOOLS] Local tooling not found, fetching scripts from GitHub"
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$WORKDIR":/workdir \
  -e AI_DEVTOOLS_RAW_BASE="$RAW_BASE" \
  -e AI_DEVTOOLS_INFRA_URL="$RAW_BASE/src/infrastructure.md" \
  -e CONTAINER_NAME="$CONTAINER_NAME" \
  docker:cli \
  sh -c '
    set -eu
    TMP_SCRIPT="/tmp/ai-devtools-generate.sh"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "$AI_DEVTOOLS_RAW_BASE/src/generate.sh" > "$TMP_SCRIPT"
    elif command -v wget >/dev/null 2>&1; then
      wget -qO "$TMP_SCRIPT" "$AI_DEVTOOLS_RAW_BASE/src/generate.sh"
    else
      echo "[AI-DEVTOOLS] ERROR: curl or wget is required in docker:cli container" >&2
      exit 1
    fi
    chmod +x "$TMP_SCRIPT"
    sh "$TMP_SCRIPT" "$CONTAINER_NAME"
  '
