@echo off
chcp 65001 >nul
setlocal

title Install 24-Min Cleaner - RUN AS ADMINISTRATOR

echo ============================================================
echo   My Clean PC - Install 24-Minute Cleaner (Task Only)
echo   Right-click this file -^> Run as administrator
echo ============================================================
echo.

:: Admin check
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo [ERROR] Admin required.
  echo Right-click this BAT -^> Run as administrator.
  echo.
  pause
  exit /b 1
)
echo [OK] Administrator confirmed.
echo.

:: Make sure scripts folder exists
set "INSTALL_DIR=%LOCALAPPDATA%\MyCleanPC"
if not exist "%INSTALL_DIR%" (
  echo [INFO] %INSTALL_DIR% missing - copying from repo now...
  mkdir "%INSTALL_DIR%"
  copy /y "e:\Rajkumar\My-Clean-PC\scripts\ai-cache-cleaner.ps1" "%INSTALL_DIR%\" >nul
  copy /y "e:\Rajkumar\My-Clean-PC\scripts\clean-pc-core.ps1"    "%INSTALL_DIR%\" >nul
  copy /y "e:\Rajkumar\My-Clean-PC\scripts\cleanup_task.ps1"      "%INSTALL_DIR%\" >nul
  echo [OK] Fresh scripts deployed.
) else (
  echo [INFO] Ensuring scripts are repo-fresh...
  copy /y "e:\Rajkumar\My-Clean-PC\scripts\ai-cache-cleaner.ps1" "%INSTALL_DIR%\" >nul
  copy /y "e:\Rajkumar\My-Clean-PC\scripts\clean-pc-core.ps1"    "%INSTALL_DIR%\" >nul
  copy /y "e:\Rajkumar\My-Clean-PC\scripts\cleanup_task.ps1"      "%INSTALL_DIR%\" >nul
  echo [OK] Scripts refreshed from repo.
)
echo.

:: Build next-run start time = now + 2 min, 24h format HH:mm
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set dt=%%a
set hh=%dt:~8,2%
set mm=%dt:~10,2%
set /a mm=(1%mm% %% 100) + 2
if %mm% geq 60 ( set /a hh=(1%hh% %% 100) + 1 & set /a mm=mm-60 )
if %hh% geq 24 set hh=0
if %mm% lss 10 set mm=0%mm%
if %hh% lss 10 set hh=0%hh%
set START=%hh%:%mm%

:: Task command = hidden PowerShell run ai-cache-cleaner.ps1
set "SCRIPT=%INSTALL_DIR%\ai-cache-cleaner.ps1"
set "RUN=powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%SCRIPT%\""

:: Remove any stale task first
schtasks /delete /tn "MyCleanPC-24Min" /f >nul 2>&1

:: Register via schtasks.exe (SYSTEM, HIGHEST, repeat every 24 min forever)
echo === Registering MyCleanPC-24Min (every 24 min, SYSTEM, first run at %START%) ===
schtasks /Create /TN "MyCleanPC-24Min" /TR "%RUN%" /SC ONCE /ST %START% /RI 24 /DU 9999:00 /RU SYSTEM /RL HIGHEST /F
if %errorlevel% neq 0 (
  echo.
  echo [FAIL] Could not create task via schtasks.exe (exit=%errorlevel%)
  pause
  exit /b 1
)
echo [OK] Task registered successfully.
echo.

echo === Verifying ===
schtasks /query /tn "MyCleanPC-24Min" /fo list /v | findstr /i "TaskName Status NextRun RunAs UserName Repeat"
echo.
echo ============================================================
echo   SUCCESS: 24-MINUTE CLEANER TASK INSTALLED
echo ============================================================
echo   - Starts first run at: %START%
echo   - Repeats EVERY 24 minutes forever
echo   - Runs as: SYSTEM (highest privileges, no login needed)
echo   - NEVER touches: Downloads folder, password databases
echo   - Temp/Prefetch use Ctrl+A Shift+Del Skip Skip (4 stage)
echo.
pause
exit /b 0
