@echo off
chcp 65001 >nul
setlocal

title My Clean PC - Reinstall Fresh (Run as Administrator)

echo ============================================================
echo   My Clean PC - UNINSTALL OLD + INSTALL FRESH
echo   Run this as: Right-click -^> Run as administrator
echo ============================================================
echo.

:: ------------------------------------------------------------------
:: 1. Admin check
:: ------------------------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo [ERROR] ADMIN REQUIRED.
  echo Right-click this file and choose "Run as administrator".
  echo.
  pause
  exit /b 1
)
echo [OK] Administrator privileges confirmed.
echo.

:: ------------------------------------------------------------------
:: 2. UNINSTALL OLD - remove ALL old scheduled tasks + deployed folder
:: ------------------------------------------------------------------
echo === STEP 1 / 3: Uninstalling old installation ===
echo.

set "TASKS=MyCleanPC MyCleanPC-7Min MyCleanPC-24Min MyCleanPC-Weekly MyCleanPC-AI-Cache 24-Silent-Cleaner"
for %%t in (%TASKS%) do (
  schtasks /delete /tn "%%t" /f >nul 2>&1 && echo   Removed task: %%t
)

set "INSTALL_DIR=%LOCALAPPDATA%\MyCleanPC"
if exist "%INSTALL_DIR%" (
  rd /s /q "%INSTALL_DIR%" && echo   Removed folder: %INSTALL_DIR%
)
echo   [Done: old installation wiped clean]
echo.

:: ------------------------------------------------------------------
:: 3. DEPLOY FRESH SCRIPTS from e:\Rajkumar\My-Clean-PC\scripts
:: ------------------------------------------------------------------
echo === STEP 2 / 3: Deploying fixed scripts ===
echo.

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
copy /y "e:\Rajkumar\My-Clean-PC\scripts\ai-cache-cleaner.ps1" "%INSTALL_DIR%\"
copy /y "e:\Rajkumar\My-Clean-PC\scripts\clean-pc-core.ps1"    "%INSTALL_DIR%\"
copy /y "e:\Rajkumar\My-Clean-PC\scripts\cleanup_task.ps1"      "%INSTALL_DIR%\"
echo   [Done: 3 fresh scripts copied to %INSTALL_DIR%]
echo.

:: ------------------------------------------------------------------
:: 4. REGISTER SCHEDULED TASKS (SYSTEM account, silent bg execution)
:: ------------------------------------------------------------------
echo === STEP 3 / 3: Registering scheduled tasks ===
echo.

:: --- 24-Minute cleaner (AI cache + browser caches + Temp/Prefetch) ---
set "SCRIPT24=%INSTALL_DIR%\ai-cache-cleaner.ps1"
set "RUN24=powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%SCRIPT24%\""
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set dt=%%a
set hh=%dt:~8,2%
set mm=%dt:~10,2%
set /a mm=(1%mm% %% 100) + 2
if %mm% geq 60 (set /a hh=(1%hh% %% 100) + 1 & set /a mm=mm-60)
if %hh% geq 24 set hh=0
if %mm% lss 10 set mm=0%mm%
if %hh% lss 10 set hh=0%hh%
set START24=%hh%:%mm%
schtasks /Create /TN "MyCleanPC-24Min" /TR "%RUN24%" /SC ONCE /ST %START24% /RI 24 /DU 9999:00 /RU SYSTEM /RL HIGHEST /F >nul 2>&1 && echo   [OK] MyCleanPC-24Min  -> runs every 24 minutes (AI cache + Temp + Prefetch)

:: --- Weekly Full Deep Clean (Temp + Prefetch + Browsers + AI + Disk Cleanup + WU cache) ---
set "SCRIPTWK=%INSTALL_DIR%\cleanup_task.ps1"
set "RUNWK=powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%SCRIPTWK%\""
schtasks /Create /TN "MyCleanPC-Weekly" /TR "%RUNWK%" /SC WEEKLY /D MON /ST 09:00 /RU SYSTEM /RL HIGHEST /F >nul 2>&1 && echo   [OK] MyCleanPC-Weekly -> runs every Monday 9:00 AM (full deep clean)

echo.
echo ============================================================
echo   FRESH INSTALL COMPLETE
echo ============================================================
echo.
schtasks /query /tn "MyCleanPC-24Min"  /fo list 2>nul | findstr /i "TaskName Next"
echo.
schtasks /query /tn "MyCleanPC-Weekly" /fo list 2>nul | findstr /i "TaskName Next"
echo.
echo Downloads folder + passwords (Login Data, key4.db, logins.json)
echo are explicitly NEVER touched - triple-guard enforced.
echo.
echo Temp + Prefetch now use Ctrl+A -^> Shift+Del -^> Skip Skip
echo 4-stage clean including next-boot cleanup of locked leftovers.
echo.
pause
