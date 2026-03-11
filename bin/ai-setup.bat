@echo off
setlocal

SET CONTAINER_NAME=shopware
IF NOT "%~1"=="" SET CONTAINER_NAME=%~1
SET RAW_BASE=https://raw.githubusercontent.com/aggrosoft/shopware-plugin-dev-tools/main
IF NOT "%AI_DEVTOOLS_RAW_BASE%"=="" SET RAW_BASE=%AI_DEVTOOLS_RAW_BASE%

echo [AI-DEVTOOLS] Starting generator for container pattern: %CONTAINER_NAME%

IF EXIST "%CD%\.devtools\src\generate.sh" (
  echo [AI-DEVTOOLS] Using local tooling from .devtools
  docker run --rm ^
    -v /var/run/docker.sock:/var/run/docker.sock ^
    -v "%CD%":/workdir ^
    docker:cli ^
    sh -c "sed 's/\r$//' /workdir/.devtools/src/generate.sh | sh -s -- %CONTAINER_NAME%"
) ELSE (
  echo [AI-DEVTOOLS] Local tooling not found, fetching scripts from GitHub
  docker run --rm ^
    -v /var/run/docker.sock:/var/run/docker.sock ^
    -v "%CD%":/workdir ^
    -e AI_DEVTOOLS_RAW_BASE="%RAW_BASE%" ^
    -e AI_DEVTOOLS_INFRA_URL="%RAW_BASE%/src/infrastructure.md" ^
    docker:cli ^
    sh -c "if command -v curl >/dev/null 2>&1; then curl -fsSL %RAW_BASE%/src/generate.sh; elif command -v wget >/dev/null 2>&1; then wget -qO- %RAW_BASE%/src/generate.sh; else echo [AI-DEVTOOLS] ERROR: curl or wget missing >&2; exit 1; fi | sed 's/\r$//' | sh -s -- %CONTAINER_NAME%"
)

IF %ERRORLEVEL% NEQ 0 (
   echo [ERROR] Execution failed.
) ELSE (
   echo [OK] Done.
)
endlocal
