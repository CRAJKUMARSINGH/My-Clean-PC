@echo off
:: My Clean PC - Silent Installer: Every 30 Minutes
:: Right-click > Run as administrator

net session >nul 2>&1
if %errorlevel% neq 0 (
  echo ERROR: Run as administrator required.
  exit /b 1
)

if not exist "%~dp0my-clean-pc.bat" (
  echo ERROR: my-clean-pc.bat not found in the same folder.
  exit /b 1
)

set "INSTALL_DIR=%LOCALAPPDATA%\MyCleanPC"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
copy /y "%~dp0my-clean-pc.bat" "%INSTALL_DIR%\my-clean-pc.bat" >nul

schtasks /delete /tn "MyCleanPC" /f >nul 2>&1
schtasks /create /tn "MyCleanPC" ^
  /tr "\"%INSTALL_DIR%\my-clean-pc.bat\"" ^
  /sc MINUTE /mo 30 /ru "%USERNAME%" /f >nul

echo My Clean PC scheduled: every 30 minutes.
exit /b 0
