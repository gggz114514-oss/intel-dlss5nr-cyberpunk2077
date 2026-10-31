@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Install-Cyberpunk.ps1" %*
if errorlevel 1 echo Installation failed. Read the error above; do not start the game with an incomplete installation.
pause
