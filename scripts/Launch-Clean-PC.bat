@echo off
:: My Clean PC - GUI launcher (uses My-Clean-PC-GUI.ps1 + clean-pc-core.ps1 in this folder)
set "PSFILE=%~dp0My-Clean-PC-GUI.ps1"

if not exist "%PSFILE%" (
    echo Error: My-Clean-PC-GUI.ps1 not found beside this .bat file.
    pause
    exit /b 1
)

start "" /min powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%PSFILE%" -FullClean
exit /b 0
