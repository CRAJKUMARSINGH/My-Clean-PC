# Wrapper: Uninstall old, then install 24-Min only with latest scripts
param(
    [switch]$Elevated
)
$ErrorActionPreference = 'Stop'

if (-not $Elevated) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Elevated" -Verb RunAs -Wait
    exit
}

$Repo = "e:\Rajkumar\My-Clean-PC"

Write-Host "=== STEP 1: UNINSTALL (clean slate) ===" -ForegroundColor Cyan
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Repo "uninstall.ps1")
Write-Host "Uninstall done." -ForegroundColor Green

Write-Host ""
Write-Host "=== STEP 2: INSTALL 24-MINUTE REPEAT (latest scripts) ===" -ForegroundColor Cyan
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Repo "Install-Cleaners-Admin.ps1") -Task 24Min

Write-Host ""
Write-Host "=== POST-INSTALL VERIFICATION ===" -ForegroundColor Cyan
$t = Get-ScheduledTask -TaskName "MyCleanPC-24Min" -ErrorAction SilentlyContinue
if ($t) {
    Write-Host "TASK FOUND: $($t.TaskName) -> State: $($t.State)" -ForegroundColor Green
    $ti = Get-ScheduledTaskInfo -TaskName "MyCleanPC-24Min" -ErrorAction SilentlyContinue
    if ($ti) {
        Write-Host "  Last run:   $($ti.LastRunTime)"
        Write-Host "  Next run:   $($ti.NextRunTime)"
        Write-Host "  Last exit:  $($ti.LastTaskResult)"
    }
    $td = Get-ScheduledTask -TaskName "MyCleanPC-24Min" -ErrorAction SilentlyContinue
    if ($td) {
        $td.Actions | ForEach-Object {
            Write-Host "  Execute: $($_.Execute)"
            Write-Host "  Args:    $($_.Arguments)"
        }
        $td.Triggers | ForEach-Object {
            Write-Host "  Repetition: Every $($_.Repetition.Interval)"
        }
    }
    $installDir = "$env:LOCALAPPDATA\MyCleanPC"
    Write-Host ""
    Write-Host "Installed scripts in $installDir :" -ForegroundColor Cyan
    if (Test-Path $installDir) {
        Get-ChildItem $installDir -File | ForEach-Object {
            $sizeKB = [Math]::Round($_.Length/1KB, 1)
            Write-Host "  - $($_.Name)  ($sizeKB KB, LastWrite: $($_.LastWriteTime))"
        }
    }
} else {
    Write-Host "WARNING: MyCleanPC-24Min task not found after install!" -ForegroundColor Red
}
Write-Host ""
Write-Host "Press Enter to close..."
Read-Host
