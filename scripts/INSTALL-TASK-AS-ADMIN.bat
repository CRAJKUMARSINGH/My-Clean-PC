@echo off
echo Requesting administrator privileges...
powershell -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0schedule-6hours.ps1\"' -Verb RunAs -Wait"
echo Done. Check for any error messages above.
pause
