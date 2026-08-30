@echo off
:: My Clean PC - GUI Launcher (FullClean)
:: This batch runs the PowerShell cleanup script with the -FullClean switch.

:: Determine the location of the PowerShell script (always the one in the project folder).
set "PROJECT_ROOT=C:\Users\Rajkumar\My-Clean-PC"
set "PSFILE=%PROJECT_ROOT%\scripts\My-Clean-PC-GUI.ps1"

if not exist "%PSFILE%" (
    echo Error: PowerShell script not found at "%PSFILE%".
    echo Please ensure the project is installed correctly.
    pause
    exit /b 1
)

:: Launch PowerShell (minimized) with the FullClean flag
start "" /min powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%PSFILE%" -FullClean
exit /b 0
