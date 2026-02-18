@echo off
REM Dieser Befehl wird vom Plugin-Root aus ausgeführt: .devtools\bin\ai-setup.bat
REM %CD% ist also der Plugin-Root.

SET CONTAINER_NAME=shopware
REM Optional: Erlaube Übergabe eines Namens: ai-setup.bat mein-shop
IF NOT "%~1"=="" SET CONTAINER_NAME=%~1

echo [AI-DEVTOOLS] Starte Generator fuer Container: %CONTAINER_NAME%...

docker run --rm ^
  -v /var/run/docker.sock:/var/run/docker.sock ^
  -v "%CD%":/workdir ^
  docker:cli ^
   sh -c "sed 's/\r$//' /workdir/.devtools/src/generate.sh | sh -s -- %CONTAINER_NAME%"

IF %ERRORLEVEL% NEQ 0 (
   echo [ERROR] Fehler beim Ausfuehren.
   pause
) ELSE (
   echo [OK] Fertig.
)
