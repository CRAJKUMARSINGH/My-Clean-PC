# My Clean PC - Silent Scheduler: Every 6 Hours
# Run with: PowerShell -ExecutionPolicy Bypass -File schedule-6hours.ps1
# Registers a Windows Scheduled Task that runs cleanup_task.ps1 every 6 hours.

$ErrorActionPreference = "SilentlyContinue"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

foreach ($f in @("cleanup_task.ps1", "clean-pc-core.ps1")) {
    if (-not (Test-Path (Join-Path $scriptDir $f))) {
        Write-Host "ERROR: $f not found in $scriptDir" -ForegroundColor Red
        exit 1
    }
}

$installDir = "$env:LOCALAPPDATA\MyCleanPC"
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
}

Copy-Item -Force (Join-Path $scriptDir "cleanup_task.ps1")  (Join-Path $installDir "cleanup_task.ps1")
Copy-Item -Force (Join-Path $scriptDir "clean-pc-core.ps1") (Join-Path $installDir "clean-pc-core.ps1")

$taskName   = "MyCleanPC-Every6Hours"
$taskScript = Join-Path $installDir "cleanup_task.ps1"
$psArgs     = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File " + ('"' + $taskScript + '"')

$action   = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $psArgs

$startAt  = (Get-Date).Date.AddHours([Math]::Ceiling((Get-Date).TimeOfDay.TotalHours))
$trigger  = New-ScheduledTaskTrigger -Once -At $startAt `
                -RepetitionInterval (New-TimeSpan -Hours 6) `
                -RepetitionDuration ([TimeSpan]::MaxValue)

$settings = New-ScheduledTaskSettingsSet `
                -ExecutionTimeLimit          (New-TimeSpan -Hours 3) `
                -MultipleInstances           IgnoreNew `
                -StopIfGoingOnBatteries:     $false `
                -DisallowStartIfOnBatteries: $false `
                -RunOnlyIfIdle:              $false `
                -StartWhenAvailable:         $true

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

$existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existing) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Existing task removed, re-registering..." -ForegroundColor Yellow
}

Register-ScheduledTask `
    -TaskName    $taskName `
    -Action      $action `
    -Trigger     $trigger `
    -Settings    $settings `
    -Principal   $principal `
    -Description "My Clean PC: cleanup every 6 hours" | Out-Null

$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    $info = Get-ScheduledTaskInfo -TaskName $taskName
    Write-Host ""
    Write-Host "SUCCESS: Task '$taskName' registered." -ForegroundColor Green
    Write-Host "  Script : $taskScript"               -ForegroundColor Cyan
    Write-Host "  Runs   : every 6 hours"             -ForegroundColor Cyan
    Write-Host "  Next   : $($info.NextRunTime)"      -ForegroundColor Cyan
    Write-Host "  As     : SYSTEM (Highest)"          -ForegroundColor Cyan
} else {
    Write-Host "ERROR: Registration failed. Run as Administrator." -ForegroundColor Red
    exit 1
}
