# Direct installer for 24-Min task - shows verbose output and auto-elevates
param([switch]$Elevated)
$ErrorActionPreference = 'Continue'
$Repo = 'e:\Rajkumar\My-Clean-PC'

if (-not $Elevated) {
    Write-Host "Requesting Admin for task registration..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`" -Elevated" -Verb RunAs
    exit
}

Write-Host "=== ADMIN CONFIRMED ===" -ForegroundColor Green
Write-Host ""
Write-Host "Running Install-Cleaners-Admin.ps1 -Task 24Min ..." -ForegroundColor Cyan
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Repo "Install-Cleaners-Admin.ps1") -Task 24Min

Write-Host ""
Write-Host "=== POST-INSTALL CHECK ===" -ForegroundColor Cyan
$t = Get-ScheduledTask -TaskName "MyCleanPC-24Min" -ErrorAction SilentlyContinue
if ($t) {
    Write-Host "SUCCESS: MyCleanPC-24Min registered!" -ForegroundColor Green
    Write-Host "  State:   $($t.State)"
    Write-Host "  Enabled: $($t.Settings.Enabled)"
    $tr = $t.Triggers[0]
    Write-Host "  Repeat:  Every $($tr.Repetition.Interval)"
    $ti = Get-ScheduledTaskInfo -TaskName "MyCleanPC-24Min" -ErrorAction SilentlyContinue
    if ($ti) { Write-Host "  Next:    $($ti.NextRunTime)" }
    $a = $t.Actions[0]
    Write-Host "  Runs:    $($a.Execute) $($a.Arguments)"
} else {
    Write-Host "FAILURE: Task not registered" -ForegroundColor Red
    Write-Host "Trying schtasks.exe fallback..."
    $instDir = "$env:LOCALAPPDATA\MyCleanPC"
    $scriptPath = Join-Path $instDir "ai-cache-cleaner.ps1"
    $tr = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
    $startAt = (Get-Date).AddMinutes(2).ToString('HH:mm')
    & schtasks.exe /Create /TN "MyCleanPC-24Min" /TR $tr /SC ONCE /ST $startAt /RI 24 /DU 9999:00 /RU SYSTEM /F
    $t2 = Get-ScheduledTask -TaskName "MyCleanPC-24Min" -ErrorAction SilentlyContinue
    if ($t2) { Write-Host "Fallback SUCCESS: Task now registered via schtasks.exe" -ForegroundColor Green } else { Write-Host "Fallback also FAILED" -ForegroundColor Red }
}
Write-Host ""
Write-Host "Press Enter to close..."
Read-Host
