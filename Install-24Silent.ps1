# 24-Silent Cleaner - Installation Script
# Creates a Windows Scheduled Task to run cleaning every 24 minutes
# NO applications, browsers, or AI tools will be closed
# Run as Administrator: powershell -ExecutionPolicy Bypass -File Install-24Silent.ps1

param(
    [switch]$AlreadyElevated
)

$ErrorActionPreference  = "Stop"
$ConfirmPreference      = "None"
$ProgressPreference     = "SilentlyContinue"
$PSDefaultParameterValues["*:Confirm"] = $false
$PSDefaultParameterValues["*:Force"]   = $true

# ---- Config ---------------------------------------------------------------
$TaskName    = "24-Silent-Cleaner"
$InstallDir  = "$env:LOCALAPPDATA\MyCleanPC"
$RepoScripts = "$PSScriptRoot"          # Current directory
$TaskScript  = Join-Path $InstallDir "24-Silent.ps1"
$LogFile     = Join-Path $InstallDir "24-silent-install-log.txt"
$IntervalMin = 24                       # Run every 24 minutes
$ExecLimitMin = 30                      # Max execution time 30 minutes
# ---------------------------------------------------------------------------

function Write-Log {
    param([string]$Msg)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Msg"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
}

Write-Log "===== 24-Silent Cleaner Installer ====="

# 1. Create install dir
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Write-Log "Created install dir: $InstallDir"
} else {
    Write-Log "Install dir exists: $InstallDir"
}

# 2. Create the 24-Silent.ps1 script if it doesn't exist
$24SilentScript = @'
# 24-Silent Cleaner - Main Cleaning Script
# Runs every 24 minutes without closing any applications
# Safe temp file and cache cleaning only

$ErrorActionPreference  = "SilentlyContinue"
$ConfirmPreference      = "None"
$ProgressPreference     = "SilentlyContinue"
$WarningPreference      = "SilentlyContinue"

$LogFile = Join-Path $env:USERPROFILE "24-Silent-Log.txt"

function Write-Log {
    param([string]$Msg)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLine = "[$timestamp] $Msg"
    Add-Content -Path $LogFile -Value $logLine -ErrorAction SilentlyContinue
}

Write-Log "=== 24-Silent Cleaner Started ==="

# Clean Windows Temp (files older than 2 hours)
$tempPath = $env:TEMP
if (Test-Path $tempPath) {
    $cutoffTime = (Get-Date).AddHours(-2)
    $tempFiles = Get-ChildItem -LiteralPath $tempPath -Recurse -File -ErrorAction SilentlyContinue
    $cleanedCount = 0
    
    foreach ($file in $tempFiles) {
        if ($file.LastWriteTime -lt $cutoffTime) {
            try {
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
                $cleanedCount++
            } catch {
                # File locked, skip
            }
        }
    }
    Write-Log "Cleaned $cleanedCount temp files from Windows Temp"
}

# Clean Local AppData Temp
$localTemp = "$env:LOCALAPPDATA\Temp"
if (Test-Path $localTemp) {
    $cutoffTime = (Get-Date).AddHours(-2)
    $localTempFiles = Get-ChildItem -LiteralPath $localTemp -Recurse -File -ErrorAction SilentlyContinue
    $localCleanedCount = 0
    
    foreach ($file in $localTempFiles) {
        if ($file.LastWriteTime -lt $cutoffTime) {
            try {
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
                $localCleanedCount++
            } catch {
                # File locked, skip
            }
        }
    }
    Write-Log "Cleaned $localCleanedCount temp files from Local AppData Temp"
}

# Clean Prefetch (older than 1 day)
$prefetchPath = "C:\Windows\Prefetch"
if (Test-Path $prefetchPath) {
    $cutoffTime = (Get-Date).AddDays(-1)
    $prefetchFiles = Get-ChildItem -LiteralPath $prefetchPath -File -ErrorAction SilentlyContinue
    $prefetchCleanedCount = 0
    
    foreach ($file in $prefetchFiles) {
        if ($file.LastWriteTime -lt $cutoffTime) {
            try {
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
                $prefetchCleanedCount++
            } catch {
                # File locked, skip
            }
        }
    }
    Write-Log "Cleaned $prefetchCleanedCount files from Prefetch"
}

# Clean AI Tool Roaming AppData (safe cache only)
$aiTools = @("Windsurf", "Kiro", "Devin", "Antigravity", "Trae")
$aiCleanedCount = 0

foreach ($tool in $aiTools) {
    $toolPath = "$env:APPDATA\$tool"
    if (Test-Path $toolPath) {
        # Only clean Cache directories, never touch data directories
        $cacheDirs = Get-ChildItem -LiteralPath $toolPath -Directory -ErrorAction SilentlyContinue | 
                     Where-Object { $_.Name -like "*Cache*" -or $_.Name -like "*cache*" }
        
        foreach ($cacheDir in $cacheDirs) {
            try {
                $files = Get-ChildItem -LiteralPath $cacheDir.FullName -Recurse -File -ErrorAction SilentlyContinue
                foreach ($file in $files) {
                    try {
                        Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
                        $aiCleanedCount++
                    } catch {
                        # File locked, skip
                    }
                }
            } catch {
                # Directory locked, skip
            }
        }
    }
}
Write-Log "Cleaned $aiCleanedCount files from AI tool caches"

# Run Disk Cleanup silently
try {
    Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -WindowStyle Hidden -ErrorAction SilentlyContinue
    Write-Log "Disk Cleanup initiated"
} catch {
    Write-Log "Disk Cleanup failed to start"
}

# Empty Recycle Bin (older than 1 day)
try {
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.Namespace(0xA)
    $items = $recycleBin.Items()
    $recycleCleanedCount = 0
    
    foreach ($item in $items) {
        $itemDate = $recycleBin.GetDetailsOf($item, 3)  # Date modified
        if ($itemDate) {
            try {
                $itemDateObj = [DateTime]::Parse($itemDate)
                if ($itemDateObj -lt (Get-Date).AddDays(-1)) {
                    $item.InvokeVerb("delete")
                    $recycleCleanedCount++
                }
            } catch {
                # Parse failed, skip
            }
        }
    }
    Write-Log "Cleaned $recycleCleanedCount items from Recycle Bin"
} catch {
    Write-Log "Recycle Bin cleanup failed"
}

Write-Log "=== 24-Silent Cleaner Complete ==="
Write-Log "Total temp files cleaned: $($cleanedCount + $localCleanedCount + $prefetchCleanedCount)"
Write-Log "AI tool cache files cleaned: $aiCleanedCount"
Write-Log "Recycle Bin items cleaned: $recycleCleanedCount"
Write-Log "NO applications were closed during cleanup"
'@

# Write the 24-Silent.ps1 script to install directory
$24SilentScript | Out-File -FilePath $TaskScript -Encoding UTF8 -Force
Write-Log "Created 24-Silent.ps1 in install directory"

# 3. Stop/remove existing task if present
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    if ($existing.State -eq 'Running') {
        Write-Log "Stopping running task: $TaskName"
        Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine -like '*24-Silent.ps1*' } |
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

function Register-24SilentTask {
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
    Register-24SilentTask -RunLevel Highest
    Write-Log "Task registered: $TaskName (RunLevel Highest)"
    $registered = $true
} catch {
    Write-Log "Highest run level failed ($($_.Exception.Message)); retrying Limited."
    try {
        Register-24SilentTask -RunLevel Limited
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
        Write-Log "WARNING: existing 24-Silent task will keep its current trigger/limits. Re-run as Administrator to set 24-minute schedule."
    } else {
        Write-Log "ERROR: 24-Silent task does not exist and this session cannot create it. Re-run as Administrator."
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
Write-Log "===== 24-Silent Cleaner install complete ====="
Write-Log "This task will clean temp files and AI tool caches every 24 minutes"
Write-Log "NO applications, browsers, or AI tools will be closed - they continue running during cleanup"
