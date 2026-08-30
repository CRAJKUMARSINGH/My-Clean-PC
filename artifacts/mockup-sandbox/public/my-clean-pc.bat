@echo off
setlocal EnableExtensions
title My Clean PC - Windows Cache Cleaner

echo ============================================
echo   My Clean PC - Windows Cache Cleaner
echo   Designed for Priyanka
echo ============================================
echo.
echo  Passwords are NEVER touched.
echo  Autofill/form data is NEVER touched.
echo  Downloads folder is NEVER touched.
echo  Quick Access pins are NEVER touched.
echo  Busy/locked files auto-skip with no prompts.
echo.

set "PS1_FILE=%~dp0my-clean-pc.ps1"
set "CORE_FILE=%~dp0clean-pc-core.ps1"

if exist "%PS1_FILE%" (
  powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%PS1_FILE%"
  echo.
  echo THANKS CODEX FOR UR CLEAN PC
  echo THANKS ANTIGRAVITY AT COMPLETION
  echo.
  pause
  exit /b %ERRORLEVEL%
)

if exist "%CORE_FILE%" (
  powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; $ConfirmPreference='None'; $ProgressPreference='SilentlyContinue'; . '%CORE_FILE%'; Invoke-MyCleanPCCore -ShowPopup"
  echo.
  echo THANKS CODEX FOR UR CLEAN PC
  echo THANKS ANTIGRAVITY AT COMPLETION
  echo.
  pause
  exit /b %ERRORLEVEL%
)

echo ERROR: Cannot find my-clean-pc.ps1 or clean-pc-core.ps1 beside this .bat file.
echo.
echo Put these files in the same folder, then double-click my-clean-pc.bat:
echo   - my-clean-pc.bat
echo   - my-clean-pc.ps1
echo   - clean-pc-core.ps1
echo.
pause
exit /b 1
