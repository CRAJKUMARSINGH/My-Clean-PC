# My Clean PC - Complete AppFolder Cleanup Solution (Single File)
# This script safely deletes specified application folders from AppData\Roaming every 30 minutes
# Installs scheduled task to run automatically
#
# Author: Script
# Date: 2026-07-21
# Purpose: Complete solution for automated cleanup of application folders

# ==== CONFIGURATION ====
param(
    [string]$UserName = "Rajkumar",
    [string]$TaskName = "MyCleanPCAppFolderCleanup",
    [string]$LogDir = "C:\Scripts\Logs",
    [string]$BackupDir = "C:\Scripts\Backups\AppFolders",
    [int]$MaxLogSizeMB = 10
)

# ==== GLOBAL SETTINGS ====
$ErrorActionPreference = "SilentlyContinue"
$ConfirmPreference = "None"
$ProgressPreference = "SilentlyContinue"

Write-Host "=== My Clean PC - Complete AppFolder Cleanup Solution ===" -ForegroundColor Cyan
Write-Host "Running as user: $UserName" -ForegroundColor Yellow
Write-Host "Log directory: $LogDir" -ForegroundColor Yellow
Write-Host "Backup directory: $BackupDir" -ForegroundColor Yellow
Write-Host "" -ForegroundColor White

# ==== FOLDER PATHS TO CLEAN ====
$FoldersToClean = @(
    @{ Path = "C:\Users\$UserName\AppData\Roaming\Trae"; Critical = $false },
    @{ Path = "C:\Users\$UserName\AppData\Roaming\Cursor"; Critical = $false },
    @{ Path = "C:\Users\\$UserName\AppData\Roaming\Kiro"; Critical = $false },
    @{ Path = "C:\Users\$UserName\AppData\Roaming\Antigravity"; Critical = $false },
    @{ Path = "C:\Users\$UserName\AppData\Roaming\Qoder"; Critical = $false },
    @{ Path = "C:\Users\$UserName\AppData\Roaming\devin"; Critical = $false }
)

# ==== FUNCTIONS ====

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "[$Timestamp] $Message"
    Write-Host $LogEntry
    if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
    $LogFile = Join-Path $LogDir "appfolder-cleaner-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    Add-Content -Path $LogFile -Value $LogEntry -ErrorAction SilentlyContinue
}

function Rotate-LogFile {
    try {
        $logSize = (Get-Item $LogFile -ErrorAction SilentlyContinue).Length / 1MB
        if ($logSize -gt $MaxLogSizeMB) {
            $FileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($LogFile)
            $Extension = [System.IO.Path]::GetExtension($LogFile)
            $Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            Move-Item -Path $LogFile -Destination "$FileNameWithoutExt-$Timestamp$Extension" -Force
            Write-Log "Log file rotated: $logSize MB > $MaxLogSizeMB MB"
        }
    } catch {
        Write-Log "Warning: Error rotating log file: $_"
    }
}

function Test-Battery {
    try {
        $battery = Get-WmiObject -Class Win32_Battery -ErrorAction SilentlyContinue
        if ($battery -and $battery.BatteryStatus -eq 2) {
            Write-Log "Warning: Running on battery power. Skipping cleanup to prevent data loss."
            return $false
        }
    } catch {
        Write-Log "Warning: Could not check battery status: $_"
    }
    return $true
}

function Backup-Folder {
    param([string]$SourcePath)
    if (-not (Test-Path $SourcePath)) { return $false }
    
    try {
        $BackupSubfolder = Join-Path $BackupDir (Split-Path $SourcePath -Leaf)
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $BackupTarget = "$BackupSubfolder-$timestamp"
        
        Write-Log "Creating backup of: $SourcePath -> $BackupTarget"
        Copy-Item -Path $SourcePath -Destination $BackupTarget -Recurse -Force
        Write-Log "Backup created successfully: $BackupTarget"
        return $true
    } catch {
        Write-Log "Error creating backup of $SourcePath`: $_"
        return $false
    }
}

function Get-FormattedSize {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return "$($($Bytes / 1GB).ToString('F2')) GB" }
    elseif ($Bytes -ge 1MB) { return "$($($Bytes / 1MB).ToString('F1')) MB" }
    elseif ($Bytes -ge 1KB) { return "$($($Bytes / 1KB).ToString('F0')) KB" }
    else { return "$Bytes bytes" }
}

function Get-FolderSize {
    param([string]$Path)
    if (-not (Test-Path $Path -PathType Container)) { return 0 }
    try {
        $size = 0
        $files = Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            if ($file.PSIsContainer) {
                $size += (Get-ChildItem -Path $file.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            } else {
                $size += $file.Length
            }
        }
        return $size
    } catch {
        Write-Log "Error getting size of $Path`: $_"
        return 0
    }
}

function Clean-AppFolders {
    Write-Log "=== Starting AppFolder Cleanup ==="
    
    if (-not (Test-Battery)) { return }
    
    $cleanedCount = 0
    $skippedCount = 0
    $totalSizeBefore = 0
    
    foreach ($folder in $FoldersToClean) {
        $folderPath = $folder.Path
        $folderName = Split-Path $folderPath -Leaf
        
        Write-Log "Processing folder: $folderName"
        
        if (-not (Test-Path $folderPath -PathType Container)) {
            Write-Log "  Skipped: Folder does not exist: $folderPath"
            $skippedCount++
            continue
        }
        
        $sizeBefore = Get-FolderSize $folderPath
        $totalSizeBefore += $sizeBefore
        Write-Log "  Size before cleanup: $(Get-FormattedSize $sizeBefore)"
        
        Backup-Folder -SourcePath $folderPath
        
        $deleteSuccess = $false
        $errorMessages = @()
        
        try {
            Write-Log "  Attempting clean deletion..."
            Remove-Item -Path $folderPath -Recurse -Force -ErrorAction Stop
            $deleteSuccess = -not (Test-Path $folderPath)
            if ($deleteSuccess) {
                Write-Log "  Successfully cleaned: $folderName"
                $cleanedCount++
            }
        } catch {
            $errorMessages += "Method 1 (.NET) failed: $_"
        }
        
        if (-not $deleteSuccess) {
            try {
                Write-Log "  Attempting CMD deletion fallback..."
                $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "rd", "/s", "/q", "`""$folderPath`""" -NoNewWindow -Wait -PassThru
                if ($process.ExitCode -eq 0) {
                    $deleteSuccess = -not (Test-Path $folderPath)
                    if ($deleteSuccess) {
                        Write-Log "  Successfully cleaned with CMD fallback: $folderName"
                        $cleanedCount++
                    }
                } else {
                    $errorMessages += "Method 2 (CMD) failed with exit code: $($process.ExitCode)"
                }
            } catch {
                $errorMessages += "Method 2 (CMD) failed: $_"
            }
        }
        
        if (-not $deleteSuccess) {
            Write-Log "  Failed to clean $folderName`: $( $errorMessages -join " | " )"
            $skippedCount++
        }
    }
    
    Write-Log "=== Cleanup Summary ==="
    Write-Log "Total size scanned: $(Get-FormattedSize $totalSizeBefore)"
    Write-Log "Folders successfully cleaned: $cleanedCount"
    Write-Log "Folders skipped: $skippedCount"
    
    if ($cleanedCount -gt 0) {
        Write-Log "Cleanup completed successfully!"
    } else {
        Write-Log "No folders were cleaned."
    }
    
    Write-Log "=== AppFolder Cleanup Finished ==="
}

function Create-ScheduledTask {
    param([string]$UserName, [string]$TaskName, [string]$ScriptPath)
    
    Write-Log "Creating scheduled task: $TaskName"
    
    $taskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($taskExists) {
        Write-Log "Warning: Scheduled task '$TaskName' already exists."
        $removeChoice = Read-Host "Do you want to remove the existing task and create a new one? (y/N)"
        if ($removeChoice -match "^[Yy]") {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-Log "Removed existing task: $TaskName"
        } else {
            Write-Log "Using existing task configuration."
            return $false
        }
    }
    
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30) -RepetitionDuration (New-TimeSpan -Days 365*10) -Enabled
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File \"$ScriptPath\""
    $task = New-ScheduledTask -TaskName $TaskName -Description "Automated cleanup of application folders from AppData\\Roaming every 30 minutes" -Trigger $trigger -Action $action -RunLevel Highest
    
    try {
        Register-ScheduledTask -TaskName $TaskName -InputObject $task -User $UserName -Password (Read-Host -AsSecureString "Enter password for $UserName") -ErrorAction Stop
        Write-Log "Scheduled task '$TaskName' created successfully."
        Write-Log "Task will run every 30 minutes."
        return $true
    } catch {
        Write-Log "Error creating scheduled task: $_"
        return $false
    }
}

# ==== MAIN EXECUTION ====

# Create directories
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }

# Determine script path for scheduled task
$scriptPath = $MyInvocation.MyCommand.Path

# Option 1: Ask user if they want to create scheduled task
$createTaskChoice = Read-Host "Do you want to create a scheduled task that runs this script every 30 minutes? (y/N)"

$taskCreated = $false
if ($createTaskChoice -match "^[Yy]") {
    $taskCreated = Create-ScheduledTask -UserName $UserName -TaskName $TaskName -ScriptPath $scriptPath
}

# Run cleanup once
Write-Log "Running manual cleanup (or as scheduled)..."
Clean-AppFolders

# ==== COMPLETION REPORT ====
Write-Host "=== Script Execution Complete ===" -ForegroundColor Green
Write-Host "Manual cleanup has finished." -ForegroundColor White

if ($taskCreated) {
    Write-Host "A scheduled task has been created and will run automatically every 30 minutes." -ForegroundColor Green
    Write-Host "Task Name: $TaskName" -ForegroundColor White
    Write-Host "Running as user: $UserName" -ForegroundColor White
    Write-Host "Script: $scriptPath" -ForegroundColor White
} else {
    Write-Host "To create the scheduled task later, run:" -ForegroundColor Yellow
    Write-Host "PowerShell -ExecutionPolicy Bypass -File \"$scriptPath\" -UserName $UserName -TaskName $TaskName" -ForegroundColor Gray
}
Write-Host "" -ForegroundColor White
Write-Host "All logs are stored in: $LogDir" -ForegroundColor Gray
Write-Host "Backups are stored in: $BackupDir" -ForegroundColor Gray
Write-Host "=== End of Script ===" -ForegroundColor Cyan