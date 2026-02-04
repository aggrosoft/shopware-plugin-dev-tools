@echo off
setlocal

REM 1. Ermittle Repo Root (Pfad des Skripts + ..)
REM %~dp0 ist der Pfad zum tests\ Ordner mit Backslash am Ende
pushd "%~dp0.."
SET REPO_ROOT=%CD%
popd

REM 2. Definiere Dummy Workspace
SET TEST_DIR=%REPO_ROOT%\tests\dummy_project
IF NOT EXIST "%TEST_DIR%" mkdir "%TEST_DIR%"

REM Optional: Dummy Context erstellen
echo Dies ist ein Test-Plugin. > "%TEST_DIR%\PLUGIN_CONTEXT.md"

echo 🧪 TEST-MODUS
echo    Repo Root: %REPO_ROOT%
echo    Test Dir:  %TEST_DIR%
echo ------------------------------------------------

REM 3. Docker Run
docker run --rm ^
  -v /var/run/docker.sock:/var/run/docker.sock ^
  -v "%TEST_DIR%":/workdir ^
  -v "%REPO_ROOT%":/workdir/.devtools ^
  docker:cli ^
  sh /workdir/.devtools/src/generate.sh "shopware"

echo ------------------------------------------------
echo ✅ Pruefe das Ergebnis in: tests\dummy_project\AGENT_INSTRUCTIONS.md
endlocal
pause
