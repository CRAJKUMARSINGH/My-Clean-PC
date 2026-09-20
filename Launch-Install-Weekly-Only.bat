@echo off
title Installing Weekly Cleaner Task Only (Admin)
cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator rights...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Cleaners-Admin.ps1" -Task Weekly
echo.
echo Press any key to exit...
pause >nul
