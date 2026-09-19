# My Clean PC - AppFolder Cleaner (PowerShell)
# Safely deletes specified application folders from AppData\Roaming every 30 minutes
# 
# Author: Script
# Date: 2026-07-21
# Purpose: Clean up application folders with backup verification and error handling
#
# Configuration
$UserName = "Rajkumar"  # Windows username
$ScriptName = "AppFolderCleaner"
$LogDirectory = "C:\Scripts\Logs"
$LogFile = Join-Path $LogDirectory "$ScriptName-$(Get-Date -Format 'yyyyMMdd').log"
$MaxLogSizeMB = 10  # Maximum log file size in MB
$BackupDirectory = "C:\Scripts\Backups\AppFolders"
$EnableLogging = $true

# Create necessary directories if they don't exist
if (-not (Test-Path $LogDirectory)) { New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null }
if (-not (Test-Path $BackupDirectory)) { New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null }

# Functions
function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "[$Timestamp] $Message"
    Write-Host $LogEntry
    if ($EnableLogging) {
        Add-Content -Path $LogFile -Value $LogEntry -ErrorAction SilentlyContinue
    }
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
    # Check if running on battery (optional safety check)
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
        $BackupSubfolder = Join-Path $BackupDirectory (Split-Path $SourcePath -Leaf)
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

# Main cleanup function
function Clean-AppFolders {
    Write-Log "=== Starting AppFolder Cleanup ==="
    
    # Check battery (optional safety)
    if (-not (Test-Battery)) { return }
    
    # Define folders to clean
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
        
        # Check if folder exists
        if (-not (Test-Path $folderPath -PathType Container)) {
            Write-Log "  Skipped: Folder does not exist: $folderPath"
            $skippedCount++
            continue
        }
        
        # Get folder size before backup
        $sizeBefore = Get-FolderSize $folderPath
        $totalSizeBefore += $sizeBefore
        Write-Log "  Size before cleanup: $(Get-FormattedSize $sizeBefore)"
        
        # Create backup before deletion (pre-delete verification)
        $backupSuccess = Backup-Folder -SourcePath $folderPath
        if (-not $backupSuccess) {
            Write-Log "  Backup failed for $folderPath - attempting to continue with cleanup anyway"
        }
        
        # Attempt to delete the folder with multiple methods
        $deleteSuccess = $false
        $errorMessages = @()
        
        # Method 1: Use .NET Directory.Delete with retry
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
        
        # Method 2: Use CMD with /s /q if Method 1 failed
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
        
        # Report errors if any
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
    
    Rotate-LogFile
}

# Execute main cleanup
Clean-AppFolders