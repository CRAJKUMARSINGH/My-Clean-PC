@echo off
setlocal enabledelayedexpansion
title My Clean PC - Auto-Clean Scheduler Setup

:: ── Require admin ────────────────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo.
  echo  ERROR: Please right-click this file and choose
  echo         "Run as administrator"
  echo.
  pause
  exit /b 1
)

:: ── Check cleaner script is present ──────────────────────────────────
if not exist "%~dp0my-clean-pc.bat" (
  echo.
  echo  ERROR: my-clean-pc.bat not found in the same folder.
  echo.
  echo  Please download BOTH files and keep them together:
  echo    - my-clean-pc.bat
  echo    - install-scheduler.bat
  echo.
  pause
  exit /b 1
)

:: ── Install cleaner to permanent location ────────────────────────────
set "INSTALL_DIR=%LOCALAPPDATA%\MyCleanPC"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
copy /y "%~dp0my-clean-pc.bat" "%INSTALL_DIR%\my-clean-pc.bat" >nul

echo.
echo  ============================================
echo    My Clean PC - Auto-Clean Scheduler Setup
echo  ============================================
echo.
echo    Cleaner installed to:
echo    %INSTALL_DIR%
echo.
echo    How often should My Clean PC run automatically?
echo.
echo    [1]  Every 30 minutes
echo    [2]  Every week  (Mondays at 9:00 AM)
echo    [3]  Every 15 days  (at 9:00 AM)
echo    [4]  Remove automatic cleaning (uninstall)
echo    [0]  Cancel
echo.
set /p "choice=    Enter your choice (0-4): "

if "%choice%"=="1" goto :every30min
if "%choice%"=="2" goto :every1week
if "%choice%"=="3" goto :every15days
if "%choice%"=="4" goto :uninstall
goto :cancel

:every30min
  schtasks /delete /tn "MyCleanPC" /f >nul 2>&1
  schtasks /create /tn "MyCleanPC" ^
    /tr "\"%INSTALL_DIR%\my-clean-pc.bat\"" ^
    /sc MINUTE /mo 30 ^
    /ru "%USERNAME%" /f >nul
  echo.
  echo    OK — My Clean PC will run automatically every 30 minutes.
  goto :done

:every1week
  schtasks /delete /tn "MyCleanPC" /f >nul 2>&1
  schtasks /create /tn "MyCleanPC" ^
    /tr "\"%INSTALL_DIR%\my-clean-pc.bat\"" ^
    /sc WEEKLY /d MON /st 09:00 ^
    /ru "%USERNAME%" /f >nul
  echo.
  echo    OK — My Clean PC will run automatically every Monday at 9:00 AM.
  goto :done

:every15days
  schtasks /delete /tn "MyCleanPC" /f >nul 2>&1
  schtasks /create /tn "MyCleanPC" ^
    /tr "\"%INSTALL_DIR%\my-clean-pc.bat\"" ^
    /sc DAILY /mo 15 /st 09:00 ^
    /ru "%USERNAME%" /f >nul
  echo.
  echo    OK — My Clean PC will run automatically every 15 days at 9:00 AM.
  goto :done

:uninstall
  schtasks /delete /tn "MyCleanPC" /f >nul 2>&1
  echo.
  echo    OK — Automatic cleaning has been removed.
  goto :done

:cancel
  echo.
  echo    Cancelled — no changes made.
  goto :done

:done
  echo.
  echo  ============================================
  echo.
  pause
  exit /b 0
