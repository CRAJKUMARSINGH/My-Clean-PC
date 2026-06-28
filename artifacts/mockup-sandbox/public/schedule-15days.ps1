# My Clean PC - Silent Scheduler: Every 15 Days (9:00 AM)
# Run with: PowerShell -ExecutionPolicy Bypass -File schedule-15days.ps1
# Or: Right-click > Run with PowerShell (as Administrator)

$ErrorActionPreference = "SilentlyContinue"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
  Write-Host "ERROR: Run as Administrator required." -ForegroundColor Red
  exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
foreach ($f in @("cleanup_task.ps1", "clean-pc-core.ps1")) {
  if (-not (Test-Path (Join-Path $scriptDir $f))) {
    Write-Host "ERROR: $f not found in the same folder." -ForegroundColor Red
    exit 1
  }
}

$installDir = "$env:LOCALAPPDATA\MyCleanPC"
if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir | Out-Null }
Copy-Item -Force (Join-Path $scriptDir "cleanup_task.ps1") "$installDir\cleanup_task.ps1"
Copy-Item -Force (Join-Path $scriptDir "clean-pc-core.ps1") "$installDir\clean-pc-core.ps1"
if (Test-Path (Join-Path $scriptDir "my-clean-pc.bat")) {
  Copy-Item -Force (Join-Path $scriptDir "my-clean-pc.bat") "$installDir\my-clean-pc.bat"
}

$taskScript = Join-Path $installDir "cleanup_task.ps1"
$action   = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$taskScript`""
$trigger  = New-ScheduledTaskTrigger -Daily -DaysInterval 15 -At "09:00"
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -RunOnlyIfNetworkAvailable $false

Unregister-ScheduledTask -TaskName "MyCleanPC" -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName "MyCleanPC" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force | Out-Null

Write-Host "My Clean PC scheduled: every 15 days at 9:00 AM (fully silent — no prompts)." -ForegroundColor Green
exit 0
