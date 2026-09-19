# Install My Clean PC - Weekly Monday 9 AM task
# Auto-elevates if not already admin

$ErrorActionPreference = "Stop"

# --- Self-elevate if needed ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs -Wait
    exit
}

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$installDir = "$env:LOCALAPPDATA\MyCleanPC"

# Create install dir
if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }

# Copy scripts
foreach ($f in @("cleanup_task.ps1", "clean-pc-core.ps1", "my-clean-pc-standalone.ps1")) {
    $src = Join-Path $scriptDir $f
    if (Test-Path $src) { Copy-Item -Force $src "$installDir\$f" }
}

# Register scheduled task - Every Monday 9:00 AM, run as current user, highest privileges
$taskScript = Join-Path $installDir "cleanup_task.ps1"
$action   = New-ScheduledTaskAction -Execute "powershell.exe" `
              -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$taskScript`""
$trigger  = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "09:00AM"
$settings = New-ScheduledTaskSettingsSet `
              -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
              -RunOnlyIfNetworkAvailable $false `
              -StartWhenAvailable $true `
              -WakeToRun $false

Unregister-ScheduledTask -TaskName "MyCleanPC" -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName "MyCleanPC" `
    -Action $action -Trigger $trigger -Settings $settings `
    -RunLevel Highest -Force | Out-Null

Write-Host ""
Write-Host "====================================" -ForegroundColor Green
Write-Host " My Clean PC - INSTALLED" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host " Task: MyCleanPC" -ForegroundColor White
Write-Host " Runs: Every Monday at 9:00 AM" -ForegroundColor White
Write-Host " Mode: Silent (hidden window)" -ForegroundColor White
Write-Host " Log:  $installDir\cleanup_log.txt" -ForegroundColor White
Write-Host "====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to close..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
