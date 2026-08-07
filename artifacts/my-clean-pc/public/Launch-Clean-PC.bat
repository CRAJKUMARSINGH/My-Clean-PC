@echo off
setlocal EnableExtensions
title My Clean PC - GUI Launcher

:: Always run the GUI script from the same folder as this .bat file.
set "PSFILE=%~dp0My-Clean-PC-GUI.ps1"

if not exist "%PSFILE%" (
    echo Error: My-Clean-PC-GUI.ps1 not found beside this launcher.
    echo Put Launch-Clean-PC.bat and My-Clean-PC-GUI.ps1 in the same folder.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PSFILE%"
exit /b %ERRORLEVEL%
