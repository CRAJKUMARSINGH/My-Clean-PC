# My Clean PC - 24-Minute Cleaner Installer (self-elevating)
# Installs:
#   1. Latest scripts from e:\Rajkumar\My-Clean-PC\scripts into %LOCALAPPDATA%\MyCleanPC
#   2. Scheduled task MyCleanPC-24Min -> runs ai-cache-cleaner.ps1 every 24 minutes as SYSTEM

param([switch]$Elevated)

$RepoDir    = 'e:\Rajkumar\My-Clean-PC'
$RepoScript = Join-Path $RepoDir 'scripts'
$InstallDir = Join-Path $env:LOCALAPPDATA 'MyCleanPC'
$TaskName   = 'MyCleanPC-24Min'

# ---------- Self-elevate if not already running as Administrator ----------
if (-not $Elevated) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
    if (-not $isAdmin) {
        Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`" -Elevated" -Verb RunAs
        exit
    }
}

$ErrorActionPreference = "Stop"
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   My Clean PC - 24-Minute Cleaner FRESH INSTALL" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ---------- STEP 1: Deploy latest scripts ----------
Write-Host "[1/3] Deploying latest scripts to $InstallDir ..." -ForegroundColor Green
if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
foreach ($f in @('ai-cache-cleaner.ps1','clean-pc-core.ps1','cleanup_task.ps1')) {
    $src = Join-Path $RepoScript $f
    $dst = Join-Path $InstallDir $f
    if (Test-Path $src) {
        Copy-Item -LiteralPath $src -Destination $dst -Force
        $sz = [Math]::Round((Get-Item $dst).Length / 1KB, 1)
        Write-Host "       OK  $f  ($sz KB)" -ForegroundColor Green
    } else {
        Write-Host "       MISSING in repo: $src" -ForegroundColor Red
    }
}
Write-Host ""

# ---------- STEP 2: Register 24-Min scheduled task (SYSTEM) ----------
Write-Host "[2/3] Registering scheduled task '$TaskName' (runs every 24 minutes as SYSTEM) ..." -ForegroundColor Green

$taskScript = Join-Path $InstallDir 'ai-cache-cleaner.ps1'
$action     = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$taskScript`""
$startAt    = (Get-Date).AddMinutes(2)
$trigger    = New-ScheduledTaskTrigger -Once -At $startAt -RepetitionInterval (New-TimeSpan -Minutes 24) -RepetitionDuration (New-TimeSpan -Days 9999)
$settings   = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 30) -MultipleInstances IgnoreNew -StartWhenAvailable -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries -Priority 7
$principal  = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
try {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
    Write-Host "       OK  registered via PowerShell ScheduledTask API" -ForegroundColor Green
} catch {
    Write-Host "       API failed, retrying via schtasks.exe ..." -ForegroundColor Yellow
    $tr = 'powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $taskScript + '"'
    $startStr = $startAt.ToString('HH:mm')
    & schtasks.exe /Create /TN $TaskName /TR $tr /SC ONCE /ST $startStr /RI 24 /DU 9999:00 /RU SYSTEM /RL HIGHEST /F | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host "       OK  registered via schtasks.exe fallback" -ForegroundColor Green }
    else { Write-Host "       FAILED to register task (exit=$LASTEXITCODE)" -ForegroundColor Red }
}
Write-Host ""

# ---------- STEP 3: Verify ----------
Write-Host "[3/3] Verifying installation ..." -ForegroundColor Green
$t = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($t) {
    Write-Host "       Task Name : $($t.TaskName)"
    Write-Host "       State     : $($t.State)"
    Write-Host "       Enabled   : $($t.Settings.Enabled)"
    $tr = $t.Triggers[0]
    Write-Host "       Repeat    : Every $($tr.Repetition.Interval)"
    $ti = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($ti) { Write-Host "       Next Run  : $($ti.NextRunTime)" }
    $a = $t.Actions[0]
    Write-Host "       Executes  : $($a.Execute) $($a.Arguments)"
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  SUCCESS: 24-MINUTE CLEANER INSTALLED" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "What it does (background, no popups except progress toasts):"
    Write-Host "  - Every 24 minutes  ->  AI tool caches + browser caches + Temp/Prefetch"
    Write-Host "  - Downloads folder  ->  NEVER touched (triple guard on ALL users)"
    Write-Host "  - Passwords         ->  NEVER touched (Login Data / key4.db / logins.json / key3.db ...)"
    Write-Host "  - Locked files      ->  Skipped now; auto-deleted at next boot"
    Write-Host ""
} else {
    Write-Host "       TASK NOT FOUND - registration failed" -ForegroundColor Red
    Write-Host ""
}
Write-Host "Press Enter to close this window..."
Read-Host
