Param(
    [string]$ContainerName = "shopware"
)

$ErrorActionPreference = "Stop"

$rawBase = if ($env:AI_DEVTOOLS_RAW_BASE) {
    $env:AI_DEVTOOLS_RAW_BASE
} else {
    "https://raw.githubusercontent.com/aggrosoft/shopware-plugin-dev-tools/main"
}

Write-Host "[AI-DEVTOOLS] Starting generator for container pattern: $ContainerName"

$dockerArgs = @(
    "run", "--rm",
    "-v", "/var/run/docker.sock:/var/run/docker.sock",
    "-v", "${PWD}:/workdir"
)

$localScript = Join-Path $PWD ".devtools\src\generate.sh"
if (Test-Path $localScript) {
    Write-Host "[AI-DEVTOOLS] Using local tooling from .devtools"
    $cmd = "sed 's/\r$//' /workdir/.devtools/src/generate.sh | sh -s -- $ContainerName"
    & docker @dockerArgs "docker:cli" "sh" "-c" $cmd
    exit $LASTEXITCODE
}

Write-Host "[AI-DEVTOOLS] Local tooling not found, fetching scripts from GitHub"
$remoteCmd = "if command -v curl >/dev/null 2>&1; then curl -fsSL $rawBase/src/generate.sh; elif command -v wget >/dev/null 2>&1; then wget -qO- $rawBase/src/generate.sh; else echo [AI-DEVTOOLS] ERROR: curl or wget missing >&2; exit 1; fi | sed 's/\r$//' | sh -s -- $ContainerName"

& docker @dockerArgs `
    "-e" "AI_DEVTOOLS_RAW_BASE=$rawBase" `
    "-e" "AI_DEVTOOLS_INFRA_URL=$rawBase/src/infrastructure.md" `
    "docker:cli" "sh" "-c" $remoteCmd

exit $LASTEXITCODE
