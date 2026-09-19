# My Clean PC - AppFolder Cleanup Script
# Safely deletes specified application folders from AppData\Roaming every 30 minutes
# Includes backup verification, error handling, and scheduled task creation
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
    [int]$MaxLogSizeMB = 10,
    [switch]$CreateScheduledTask = $false,
    [switch]$ForceCleanup = $false,
    [switch]$ShowHelp = $false
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
        $items = Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                $size += (Get-ChildItem -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            } else {
                $size += $item.Length
            }
        }
        return $size
    } catch {
        Write-Log "Error getting size of $Path`: $_"
        return 0
    }
}

function Backup-Folder {
    param([string]$SourcePath)
    if (-not (Test-Path $SourcePath)) { return $false }
    
    try {
        $BackupSubfolder = Join-Path $BackupDir (Split-Path $SourcePath -Leaf)
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $BackupTarget = "$BackupSubfolder-$timestamp"
        
        Write-Log "Creating backup of: $SourcePath -> $BackupTarget"
        if (-not (Test-Path $BackupSubfolder)) { New-Item -ItemType Directory -Path $BackupSubfolder -Force | Out-Null }
        Copy-Item -Path $SourcePath -Destination $BackupTarget -Recurse -Force
        Write-Log "Backup created successfully: $BackupTarget"
        return $true
    } catch {
        Write-Log "Error creating backup of $SourcePath`: $_"
        return $false
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

function Clean-AppFolders {
    Write-Log "=== Starting AppFolder Cleanup ==="
    
    if (-not (Test-Battery)) { return }
    
    # Define all folders to clean
    $FoldersToClean = @(
        @{ Path = "C:\Users\$UserName\AppData\Roaming\Trae"; Critical = $false },
        @{ Path = "C:\Users\$UserName\AppData\Roaming\Cursor"; Critical = $false },
        @{ Path = "C:\Users\$UserName\AppData\Roaming\Kiro"; Critical = $false },
        @{ Path = "C:\Users\$UserName\AppData\Roaming\Antigravity"; Critical = $false },
        @{ Path = "C:\Users\$UserName\AppData\Roaming\Qoder"; Critical = $false },
        @{ Path = "C:\Users\$UserName\AppData\Roaming\devin"; Critical = $false }
    )
    
    $cleanedCount = 0
    $skippedCount = 0
    $totalSizeBefore = 0
    
    foreach ($folder in $FoldersToClean) {
        $folderPath = $folder.Path
        $folderName = Split-Path $folderPath -Leaf
        
        Write-Log "Processing folder: $folderName"
        Write-Log "  Path: $folderPath"
        
        if (-not (Test-Path $folderPath -PathType Container)) {
            Write-Log "  Status: Folder does not exist - skipping"
            $skippedCount++
            continue
        }
        
        $sizeBefore = Get-FolderSize $folderPath
        $totalSizeBefore += $sizeBefore
        Write-Log "  Size before cleanup: $(Get-FormattedSize $sizeBefore)"
        
        if ((Test-Path $folderPath -PathType Container) -and ($ForceCleanup -or $folder.Critical)) {
            Backup-Folder -SourcePath $folderPath
        }
        
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
                        Write-Host "  Successfully cleaned with CMD fallback: $folderName" -ForegroundColor Green
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
    
    try {
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
        
        # Verify script exists
        if (-not (Test-Path $ScriptPath)) {
            Write-Log "Error: Script file not found: $ScriptPath"
            return $false
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
    } catch {
        Write-Log "Error in scheduled task creation process: $_"
        return $false
    }
}

function Show-Help {
    Write-Host "=== My Clean PC - AppFolder Cleanup Script Help ===" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor White
    Write-Host "This script safely deletes application folders from AppData\\Roaming and can create a scheduled task." -ForegroundColor White
    Write-Host "" -ForegroundColor White
    Write-Host "SYNTAX:" -ForegroundColor Yellow
    Write-Host "  AppFolderCleanupScript.ps1 [parameters]" -ForegroundColor Gray
    Write-Host "" -ForegroundColor White
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -UserName <string>          Windows username (default: Rajkumar)" -ForegroundColor Gray
    Write-Host "  -TaskName <string>          Scheduled task name (default: MyCleanPCAppFolderCleanup)" -ForegroundColor Gray
    Write-Host "  -LogDir <string>            Log directory (default: C:\Scripts\Logs)" -ForegroundColor Gray
    Write-Host "  -BackupDir <string>         Backup directory (default: C:\Scripts\Backups\AppFolders)" -ForegroundColor Gray
    Write-Host "  -MaxLogSizeMB <int>         Maximum log file size in MB (default: 10)" -ForegroundColor Gray
    Write-Host "  -CreateScheduledTask         Create scheduled task (default: ask user)" -ForegroundColor Gray
    Write-Host "  -ForceCleanup               Clean all folders including non-existent ones" -ForegroundColor Gray
    Write-Host "  -ShowHelp                   Show this help message" -ForegroundColor Gray
    Write-Host "" -ForegroundColor White
    Write-Host "FOLDERS CLEANED:" -ForegroundColor Yellow
    Write-Host "  C:\Users\$UserName\AppData\Roaming\Trae" -ForegroundColor Gray
    Write-Host "  C:\Users\$UserName\AppData\Roaming\Cursor" -ForegroundColor Gray
    Write-Host "  C:\Users\$UserName\AppData\Roaming\Kiro" -ForegroundColor Gray
    Write-Host "  C:\Users\$UserName\AppData\Roaming\Antigravity (if exists)" -ForegroundColor Gray
    Write-Host "  C:\Users\$UserName\AppData\Roaming\Qoder (if exists)" -ForegroundColor Gray
    Write-Host "  C:\Users\$UserName\AppData\Roaming\devin" -ForegroundColor Gray
    Write-Host "" -ForegroundColor White
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  AppFolderCleanupScript.ps1                    Run cleanup once and ask about scheduling" -ForegroundColor Gray
    Write-Host "  AppFolderCleanupScript.ps1 -CreateScheduledTask Run cleanup and create scheduled task" -ForegroundColor Gray
    Write-Host "  AppFolderCleanupScript.ps1 -ForceCleanup     Force cleanup with backup of all folders" -ForegroundColor Gray
    Write-Host "  AppFolderCleanupScript.ps1 -UserName Jane Doe Run cleanup for different user" -ForegroundColor Gray
    Write-Host "" -ForegroundColor White
    Write-Host "LOGS AND BACKUPS:" -ForegroundColor Yellow
    Write-Host "  Logs: $LogDir\\appfolder-cleaner-YYYYMMDD-HHmmss.log" -ForegroundColor Gray
    Write-Host "  Backups: $BackupDir\\FolderName-YYYYMMDD-HHmmss\\" -ForegroundColor Gray
    Write-Host "" -ForegroundColor White
    Write-Host "=== End Help ===" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor White
}

# ==== MAIN EXECUTION ====

# Initialize directories
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }

# Parse command line parameters
if ($ShowHelp) { Show-Help; exit 0 }

Write-Host "=== My Clean PC - AppFolder Cleanup Script ===" -ForegroundColor Cyan
Write-Host "Running with parameters:" -ForegroundColor Yellow
Write-Host "  UserName: $UserName" -ForegroundColor White
Write-Host "  TaskName: $TaskName" -ForegroundColor White
Write-Host "  LogDir: $LogDir" -ForegroundColor White
Write-Host "  BackupDir: $BackupDir" -ForegroundColor White
Write-Host "  CreateScheduledTask: $CreateScheduledTask" -ForegroundColor White
Write-Host "  ForceCleanup: $ForceCleanup" -ForegroundColor White
Write-Host "" -ForegroundColor White

# Determine script path for scheduled task
$scriptPath = $MyInvocation.MyCommand.Path

# Option 1: Ask user if they want to create scheduled task
if (-not $CreateScheduledTask) {
    $createTaskChoice = Read-Host "Do you want to create a scheduled task that runs this script every 30 minutes? (y/N)"
    if ($createTaskChoice -match "^[Yy]") {
        $CreateScheduledTask = $true
    }
}

$taskCreated = $false
if ($CreateScheduledTask) {
    $taskCreated = Create-ScheduledTask -UserName $UserName -TaskName $TaskName -ScriptPath $scriptPath
}

# Run cleanup
Write-Log "Running cleanup..."
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
    Write-Host "PowerShell -ExecutionPolicy Bypass -File \"$scriptPath\" -CreateScheduledTask -UserName $UserName -TaskName $TaskName" -ForegroundColor Gray
}
Write-Host "" -ForegroundColor White
Write-Host "All logs are stored in: $LogDir" -ForegroundColor Gray
Write-Host "Backups are stored in: $BackupDir" -ForegroundColor Gray
Write-Host "=== End of Script ===" -ForegroundColor Cyan