# My Clean PC - Uninstaller
# Run with: PowerShell -ExecutionPolicy Bypass -File uninstall.ps1
# Or: Right-click > Run with PowerShell (as Administrator)

$ErrorActionPreference = "SilentlyContinue"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
  Write-Host "ERROR: Run as Administrator required." -ForegroundColor Red
  exit 1
}

Unregister-ScheduledTask -TaskName "MyCleanPC" -Confirm:$false -ErrorAction SilentlyContinue

$installDir = "$env:LOCALAPPDATA\MyCleanPC"
if (Test-Path $installDir) { Remove-Item -Recurse -Force $installDir }

Write-Host "My Clean PC uninstalled. Scheduled task and files removed." -ForegroundColor Green
exit 0
