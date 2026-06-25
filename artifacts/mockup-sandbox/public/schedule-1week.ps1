# My Clean PC - Silent Scheduler: Every Week (Monday 9:00 AM)
# Run with: PowerShell -ExecutionPolicy Bypass -File schedule-1week.ps1
# Or: Right-click > Run with PowerShell (as Administrator)

$ErrorActionPreference = "SilentlyContinue"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
  Write-Host "ERROR: Run as Administrator required." -ForegroundColor Red
  exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$cleanerSrc = Join-Path $scriptDir "my-clean-pc.bat"

if (-not (Test-Path $cleanerSrc)) {
  Write-Host "ERROR: my-clean-pc.bat not found in the same folder." -ForegroundColor Red
  exit 1
}

$installDir = "$env:LOCALAPPDATA\MyCleanPC"
if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir | Out-Null }
Copy-Item -Force $cleanerSrc "$installDir\my-clean-pc.bat"

$action   = New-ScheduledTaskAction -Execute "`"$installDir\my-clean-pc.bat`""
$trigger  = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "09:00"
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -RunOnlyIfNetworkAvailable $false

Unregister-ScheduledTask -TaskName "MyCleanPC" -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName "MyCleanPC" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force | Out-Null

Write-Host "My Clean PC scheduled: every Monday at 9:00 AM." -ForegroundColor Green
exit 0
