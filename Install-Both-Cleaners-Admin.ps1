# My Clean PC - Installer for Both Cleaner Tasks (24-Minute & Weekly)
# Auto-elevates to Administrator if needed

$ErrorActionPreference = "Stop"

# Self-elevate if not running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges to install Windows Scheduled Tasks..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -Wait
    exit
}

$InstallDir = "$env:LOCALAPPDATA\MyCleanPC"
$RepoRoot   = Split-Path -Parent $PSCommandPath
$ScriptsDir = Join-Path $RepoRoot "scripts"

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

Write-Host "1. Copying updated cleaner scripts to $InstallDir..." -ForegroundColor Cyan
Copy-Item -Force (Join-Path $ScriptsDir "ai-cache-cleaner.ps1") (Join-Path $InstallDir "ai-cache-cleaner.ps1")
Copy-Item -Force (Join-Path $ScriptsDir "clean-pc-core.ps1") (Join-Path $InstallDir "clean-pc-core.ps1")
Copy-Item -Force (Join-Path $ScriptsDir "cleanup_task.ps1") (Join-Path $InstallDir "cleanup_task.ps1")

# Create SYSTEM principal for background task execution
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# --- TASK 1: 24-Minute Interval Cleaner ---
Write-Host "2. Registering Task 1: MyCleanPC-24Min (Runs every 24 minutes)..." -ForegroundColor Cyan
$Task1Name   = "MyCleanPC-24Min"
$Task1Script = Join-Path $InstallDir "ai-cache-cleaner.ps1"
$Action1     = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$Task1Script`""
$StartAt1    = (Get-Date).AddMinutes(2)
$Trigger1    = New-ScheduledTaskTrigger -Once -At $StartAt1 -RepetitionInterval (New-TimeSpan -Minutes 24) -RepetitionDuration (New-TimeSpan -Days 9999)
$Settings1   = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 30) -MultipleInstances IgnoreNew -StartWhenAvailable -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries -Priority 7

Unregister-ScheduledTask -TaskName $Task1Name -Confirm:$false -ErrorAction SilentlyContinue
try {
    Register-ScheduledTask -TaskName $Task1Name -Action $Action1 -Trigger $Trigger1 -Settings $Settings1 -Principal $principal -Force | Out-Null
    Write-Host "  Task 1 registered cleanly via PowerShell API." -ForegroundColor Green
} catch {
    Write-Host "  Retrying Task 1 via schtasks.exe..." -ForegroundColor Yellow
    $tr1 = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$Task1Script`""
    $startAtStr = (Get-Date).AddMinutes(2).ToString('HH:mm')
    & schtasks.exe /Create /TN $Task1Name /TR $tr1 /SC ONCE /ST $startAtStr /RI 24 /DU 9999:00 /RU SYSTEM /F | Out-Null
}

# --- TASK 2: Weekly (7-Day) Cleaner ---
Write-Host "3. Registering Task 2: MyCleanPC-Weekly (Runs every Monday at 9:00 AM)..." -ForegroundColor Cyan
$Task2Name   = "MyCleanPC-Weekly"
$Task2Script = Join-Path $InstallDir "cleanup_task.ps1"
$Action2     = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$Task2Script`""
$Trigger2    = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "09:00AM"
$Settings2   = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 1) -MultipleInstances IgnoreNew -StartWhenAvailable -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries -Priority 7

Unregister-ScheduledTask -TaskName $Task2Name -Confirm:$false -ErrorAction SilentlyContinue
try {
    Register-ScheduledTask -TaskName $Task2Name -Action $Action2 -Trigger $Trigger2 -Settings $Settings2 -Principal $principal -Force | Out-Null
    Write-Host "  Task 2 registered cleanly via PowerShell API." -ForegroundColor Green
} catch {
    Write-Host "  Retrying Task 2 via schtasks.exe..." -ForegroundColor Yellow
    $tr2 = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$Task2Script`""
    & schtasks.exe /Create /TN $Task2Name /TR $tr2 /SC WEEKLY /D MON /ST 09:00 /RU SYSTEM /F | Out-Null
}

# --- VERIFICATION ---
Write-Host "4. Verifying scheduled task registration..." -ForegroundColor Cyan
$t1 = Get-ScheduledTask -TaskName $Task1Name -ErrorAction SilentlyContinue
$t2 = Get-ScheduledTask -TaskName $Task2Name -ErrorAction SilentlyContinue

if ($t1 -and $t2) {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host " SUCCESS: BOTH CLEANER TASKS VERIFIED IN TASK SCHEDULER!" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host " Task 1: $Task1Name -> Every 24 Minutes [State: $($t1.State)]" -ForegroundColor White
    Write-Host " Task 2: $Task2Name -> Every Week [State: $($t2.State)]" -ForegroundColor White
    Write-Host " Mode  : Silent background execution when PC is ON" -ForegroundColor White
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR: Verification failed! Task 1 ($Task1Name): $(if ($t1) {'Found'} else {'Missing'}), Task 2 ($Task2Name): $(if ($t2) {'Found'} else {'Missing'})" -ForegroundColor Red
    Write-Host "Please ensure you run PowerShell as Administrator." -ForegroundColor Red
    exit 1
}
