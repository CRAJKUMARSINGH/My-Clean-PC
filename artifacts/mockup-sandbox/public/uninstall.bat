@echo off
:: My Clean PC - Uninstaller
:: Right-click > Run as administrator

net session >nul 2>&1
if %errorlevel% neq 0 (
  echo ERROR: Run as administrator required.
  exit /b 1
)

:: Remove scheduled task
schtasks /delete /tn "MyCleanPC" /f >nul 2>&1

:: Remove installed files
set "INSTALL_DIR=%LOCALAPPDATA%\MyCleanPC"
if exist "%INSTALL_DIR%" rd /s /q "%INSTALL_DIR%"

echo My Clean PC uninstalled. Scheduled task and files removed.
exit /b 0
