# AI Cache Cleaner - Scheduled Task Setup
# Creates a scheduled task to run AI cache cleanup every 24 minutes
# The cleanup does NOT close any running AI tools
# Run once from the repo root with: powershell -ExecutionPolicy Bypass -File scripts\create-ai-cache-task.ps1

param(
    [switch]$AlreadyElevated
)

$ErrorActionPreference  = "Stop"
$ConfirmPreference      = "None"
$ProgressPreference     = "SilentlyContinue"
$PSDefaultParameterValues["*:Confirm"] = $false
$PSDefaultParameterValues["*:Force"]   = $true

# ---- Config ---------------------------------------------------------------
$TaskName    = "MyCleanPC-AI-Cache"
$InstallDir  = "$env:LOCALAPPDATA\MyCleanPC"
$RepoScripts = "$PSScriptRoot"          # wherever this file lives (scripts/)
$TaskScript  = Join-Path $InstallDir "ai-cache-cleaner.ps1"
$LogFile     = Join-Path $InstallDir "ai_cache_task_log.txt"
$IntervalMin = 24                       # Run every 24 minutes
$ExecLimitMin = 30                      # Max execution time 30 minutes
# ---------------------------------------------------------------------------

function Write-Log {
    param([string]$Msg)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Msg"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
}

Write-Log "===== AI Cache Cleaner Installer ====="

# 1. Create install dir
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Write-Log "Created install dir: $InstallDir"
} else {
    Write-Log "Install dir exists: $InstallDir"
}

# 2. Copy scripts from repo to install dir
$scriptsToCopy = @("ai-cache-cleaner.ps1", "clean-pc-core.ps1")
foreach ($script in $scriptsToCopy) {
    $src = Join-Path $RepoScripts $script
    $dst = Join-Path $InstallDir  $script
    if (-not (Test-Path $src)) {
        Write-Log "ERROR: Source not found: $src"
        exit 1
    }
    Copy-Item -Path $src -Destination $dst -Force
    Write-Log "Copied $script -> $InstallDir"
}

# 3. Stop/remove existing task if present
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    if ($existing.State -eq 'Running') {
        Write-Log "Stopping running task: $TaskName"
        Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine -like '*ai-cache-cleaner.ps1*' } |
        ForEach-Object {
            Write-Log "Killing leftover cleanup PID $($_.ProcessId)"
            Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        }
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        Write-Log "Removed existing task: $TaskName"
    } catch {
        Write-Log "Unregister denied ($($_.Exception.Message)); will overwrite with -Force."
        & schtasks.exe /End /TN $TaskName 2>$null | Out-Null
    }
}

# 4. Build task components
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$TaskScript`""

# Repeat every 24 minutes indefinitely
$startAt = (Get-Date).AddMinutes(2)
$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At $startAt `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMin) `
    -RepetitionDuration (New-TimeSpan -Days 9999)

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit        (New-TimeSpan -Minutes $ExecLimitMin) `
    -MultipleInstances         IgnoreNew `
    -StartWhenAvailable `
    -DontStopIfGoingOnBatteries `
    -AllowStartIfOnBatteries `
    -Priority 7

function Register-AiCacheTask {
    param([string]$RunLevel)
    # Use SYSTEM account for admin-level deletion
    $principal = New-ScheduledTaskPrincipal `
        -UserId    "SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel  $RunLevel
    Register-ScheduledTask `
        -TaskName   $TaskName `
        -Action     $action `
        -Trigger    $trigger `
        -Settings   $settings `
        -Principal  $principal `
        -Force | Out-Null
}

# 5. Register task (SYSTEM account for admin-level deletion)
$registered = $false
try {
    Register-AiCacheTask -RunLevel Highest
    Write-Log "Task registered: $TaskName (RunLevel Highest)"
    $registered = $true
} catch {
    Write-Log "Highest run level failed ($($_.Exception.Message)); retrying Limited."
    try {
        Register-AiCacheTask -RunLevel Limited
        Write-Log "Task registered: $TaskName (RunLevel Limited)"
        $registered = $true
    } catch {
        Write-Log "Limited register failed ($($_.Exception.Message)); retrying schtasks.exe /F."
    }
}

if (-not $registered) {
    $tr = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$TaskScript`""
    $startAt = (Get-Date).AddMinutes(2).ToString('HH:mm')
    $intervalMinutes = $IntervalMin * 60  # Convert to minutes for schtasks
    $args = @(
        '/Create', '/TN', $TaskName, '/TR', $tr,
        '/SC', 'ONCE', '/ST', $startAt, 
        '/RI', $intervalMinutes, '/DU', '9999:00',
        '/RU', 'SYSTEM', '/F'
    )
    try {
        $out = & schtasks.exe @args 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Log ("schtasks: " + $out.Trim())
            $registered = $true
        } else {
            Write-Log ("schtasks failed: " + $out.Trim())
        }
    } catch {
        Write-Log "schtasks threw ($($_.Exception.Message))"
    }
}

if (-not $registered) {
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Log "WARNING: could not rewrite the scheduled task (Access denied). Updated scripts are already in $InstallDir."
        Write-Log "WARNING: existing AI cache task will keep its current trigger/limits. Re-run as Administrator to set 24-minute schedule."
    } else {
        Write-Log "ERROR: AI cache task does not exist and this session cannot create it. Re-run as Administrator."
        exit 1
    }
}

# 6. Verify
$info = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
$task = Get-ScheduledTask     -TaskName $TaskName -ErrorAction SilentlyContinue
$rep = $null
if ($task -and $task.Triggers) {
    $rep = $task.Triggers[0].Repetition.Interval
}
Write-Log "State         : $($task.State)"
Write-Log "Next run      : $($info.NextRunTime)"
Write-Log "Repeat every  : $IntervalMin minutes"
Write-Log "Trigger XML   : $rep"
Write-Log "Exec limit    : $ExecLimitMin minutes"
Write-Log "Script        : $TaskScript"
if ($rep -and ($rep -notmatch "PT${IntervalMin}M") -and ($rep -notmatch "^0?${IntervalMin}:00:00")) {
    Write-Log "WARNING: repetition interval is not $IntervalMin minutes ($rep)"
}
Write-Log "===== AI Cache Cleaner install complete ====="
Write-Log "This task will clean AI tool cache/temp files every 24 minutes"
Write-Log "NO AI tools will be closed - they continue running during cleanup"