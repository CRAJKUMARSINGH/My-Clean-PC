# My Clean PC - Installer & Scheduled Task Setup
# Copies cleanup_task.ps1 + clean-pc-core.ps1 to install dir,
# then registers/updates the MyCleanPC scheduled task to run every 6 hours.
# Run once from the repo root with: powershell -ExecutionPolicy Bypass -File scripts\create-scheduled-task.ps1

param(
    [switch]$AlreadyElevated
)

$ErrorActionPreference  = "Stop"
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
$ExecLimitHr = 4
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

# 3. Stop/remove existing task if present (running 2-hour job would otherwise keep going)
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    if ($existing.State -eq 'Running') {
        Write-Log "Stopping running task: $TaskName"
        Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine -like '*MyCleanPC\cleanup_task.ps1*' } |
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

# Repeat every 6 hours indefinitely. RepetitionDuration is required on some Windows builds.
$startAt = (Get-Date).AddMinutes(2)
$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At $startAt `
    -RepetitionInterval (New-TimeSpan -Hours $IntervalHrs) `
    -RepetitionDuration (New-TimeSpan -Days 9999)

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit        (New-TimeSpan -Hours $ExecLimitHr) `
    -MultipleInstances         IgnoreNew `
    -StartWhenAvailable `
    -DontStopIfGoingOnBatteries `
    -AllowStartIfOnBatteries `
    -Priority 7

function Register-MyCleanPCTask {
    param([string]$RunLevel)
    $principal = New-ScheduledTaskPrincipal `
        -UserId    $env:USERNAME `
        -LogonType Interactive `
        -RunLevel  $RunLevel
    Register-ScheduledTask `
        -TaskName   $TaskName `
        -Action     $action `
        -Trigger    $trigger `
        -Settings   $settings `
        -Principal  $principal `
        -Force | Out-Null
}

# 5. Register task (Highest if this session can, otherwise Limited so the 6-hour job still runs)
$registered = $false
try {
    Register-MyCleanPCTask -RunLevel Highest
    Write-Log "Task registered: $TaskName (RunLevel Highest)"
    $registered = $true
} catch {
    Write-Log "Highest run level failed ($($_.Exception.Message)); retrying Limited."
    try {
        Register-MyCleanPCTask -RunLevel Limited
        Write-Log "Task registered: $TaskName (RunLevel Limited)"
        $registered = $true
    } catch {
        Write-Log "Limited register failed ($($_.Exception.Message)); retrying schtasks.exe /F."
    }
}

if (-not $registered) {
    $tr = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$TaskScript`""
    $startAt = (Get-Date).AddMinutes(2).ToString('HH:mm')
    $args = @(
        '/Create', '/TN', $TaskName, '/TR', $tr,
        '/SC', 'ONCE', '/ST', $startAt, '/RI', '360', '/DU', '9999:00',
        '/RL', 'LIMITED', '/F'
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
        Write-Log "WARNING: existing MyCleanPC task will keep its current trigger/limits. Re-run as Administrator to set 6-hour + 4-hour exec limit."
    } else {
        Write-Log "ERROR: MyCleanPC task does not exist and this session cannot create it. Re-run as Administrator."
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
Write-Log "Repeat every  : $IntervalHrs hours"
Write-Log "Trigger XML   : $rep"
Write-Log "Exec limit    : $ExecLimitHr hours"
Write-Log "Script        : $TaskScript"
if ($rep -and ($rep -notmatch 'PT6H') -and ($rep -notmatch '^0?6:00:00')) {
    Write-Log "WARNING: repetition interval is not 6 hours ($rep)"
}
Write-Log "===== Install complete ====="