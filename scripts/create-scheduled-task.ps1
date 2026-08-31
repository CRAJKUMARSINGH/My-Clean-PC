# My Clean PC - Installer & Scheduled Task Setup
# Copies cleanup_task.ps1 + clean-pc-core.ps1 to install dir,
# then registers/updates the MyCleanPC scheduled task to run every 6 hours.
# Run once from the repo root with: powershell -ExecutionPolicy Bypass -File scripts\create-scheduled-task.ps1

$ErrorActionPreference  = "SilentlyContinue"
$ConfirmPreference      = "None"
$ProgressPreference     = "SilentlyContinue"
$PSDefaultParameterValues["*:Confirm"] = $false
$PSDefaultParameterValues["*:Force"]   = $true

# ---- Config ---------------------------------------------------------------
$TaskName    = "MyCleanPC"
$InstallDir  = "$env:LOCALAPPDATA\MyCleanPC"
$RepoScripts = "$PSScriptRoot"          # wherever this file lives (scripts/)
$TaskScript  = Join-Path $InstallDir "cleanup_task.ps1"
$LogFile     = Join-Path $InstallDir "install_log.txt"
$IntervalHrs = 6
$ExecLimitHr = 2
# ---------------------------------------------------------------------------

function Write-Log {
    param([string]$Msg)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Msg"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
}

Write-Log "===== MyCleanPC Installer ====="

# 1. Create install dir
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Write-Log "Created install dir: $InstallDir"
} else {
    Write-Log "Install dir exists: $InstallDir"
}

# 2. Copy scripts from repo to install dir
foreach ($script in @("cleanup_task.ps1", "clean-pc-core.ps1")) {
    $src = Join-Path $RepoScripts $script
    $dst = Join-Path $InstallDir  $script
    if (-not (Test-Path $src)) {
        Write-Log "ERROR: Source not found: $src"
        exit 1
    }
    Copy-Item -Path $src -Destination $dst -Force
    Write-Log "Copied $script -> $InstallDir"
}

# 3. Remove existing task if present
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Log "Removed existing task: $TaskName"
}

# 4. Build task components
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$TaskScript`""

# Start now, repeat every 6 hours indefinitely
$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Hours $IntervalHrs)

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit        (New-TimeSpan -Hours $ExecLimitHr) `
    -MultipleInstances         IgnoreNew `
    -StartWhenAvailable `
    -DontStopIfGoingOnBatteries `
    -AllowStartIfOnBatteries `
    -Priority 7

$principal = New-ScheduledTaskPrincipal `
    -UserId    $env:USERNAME `
    -LogonType Interactive `
    -RunLevel  Highest

# 5. Register task
Register-ScheduledTask `
    -TaskName   $TaskName `
    -Action     $action `
    -Trigger    $trigger `
    -Settings   $settings `
    -Principal  $principal `
    -Force | Out-Null

Write-Log "Task registered: $TaskName"

# 6. Verify
$info = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
$task = Get-ScheduledTask     -TaskName $TaskName -ErrorAction SilentlyContinue
Write-Log "State         : $($task.State)"
Write-Log "Next run      : $($info.NextRunTime)"
Write-Log "Repeat every  : $IntervalHrs hours"
Write-Log "Exec limit    : $ExecLimitHr hours"
Write-Log "Script        : $TaskScript"
Write-Log "===== Install complete ====="