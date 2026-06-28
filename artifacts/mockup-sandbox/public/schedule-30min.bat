@echo off
:: My Clean PC - Silent Installer: Every 30 Minutes
:: Right-click > Run as administrator

net session >nul 2>&1
if %errorlevel% neq 0 (
  echo ERROR: Run as administrator required.
  exit /b 1
)

if not exist "%~dp0cleanup_task.ps1" (
  echo ERROR: cleanup_task.ps1 not found in the same folder.
  exit /b 1
)
if not exist "%~dp0clean-pc-core.ps1" (
  echo ERROR: clean-pc-core.ps1 not found in the same folder.
  exit /b 1
)

set "INSTALL_DIR=%LOCALAPPDATA%\MyCleanPC"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
copy /y "%~dp0cleanup_task.ps1" "%INSTALL_DIR%\cleanup_task.ps1" >nul
copy /y "%~dp0clean-pc-core.ps1" "%INSTALL_DIR%\clean-pc-core.ps1" >nul
if exist "%~dp0my-clean-pc.bat" copy /y "%~dp0my-clean-pc.bat" "%INSTALL_DIR%\my-clean-pc.bat" >nul

schtasks /delete /tn "MyCleanPC" /f >nul 2>&1
schtasks /create /tn "MyCleanPC" ^
  /tr "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%INSTALL_DIR%\cleanup_task.ps1\"" ^
  /sc MINUTE /mo 30 /ru "%USERNAME%" /f >nul

echo My Clean PC scheduled: every 30 minutes (fully silent — no prompts).
exit /b 0
