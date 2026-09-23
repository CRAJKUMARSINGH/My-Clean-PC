# My Clean PC - Uninstaller
# Run as Administrator: powershell -ExecutionPolicy Bypass -File uninstall.ps1

$ErrorActionPreference = "SilentlyContinue"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "ERROR: Run as Administrator required." -ForegroundColor Red
    exit 1
}

$taskNames = @("MyCleanPC-7Min", "MyCleanPC-24Min", "MyCleanPC-Weekly", "MyCleanPC-AI-Cache", "24-Silent-Cleaner", "MyCleanPC")
foreach ($t in $taskNames) {
    Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction SilentlyContinue
}

$installDir = "$env:LOCALAPPDATA\MyCleanPC"
if (Test-Path $installDir) { Remove-Item -Recurse -Force $installDir }

Write-Host "My Clean PC uninstalled. All scheduled tasks and files removed." -ForegroundColor Green
exit 0
