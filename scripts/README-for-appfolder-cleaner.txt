# My Clean PC - AppFolder Cleaner

## Overview
This project provides automated cleanup of application folders from the AppData\Roaming directory. The cleanup runs every 30 minutes automatically via Windows Task Scheduler.

## Components

### 1. appfolder-cleaner.ps1
**Main cleanup script** that:
- Safely deletes specified application folders from AppData\Roaming
- Creates backups before deletion (safety verification)
- Handles errors gracefully (skips if folders don't exist)
- Rotates log files to prevent exceeding size limits
- Runs with optional battery checks to prevent data loss
- Provides detailed logging of all operations

**Folders cleaned (6 total):**
- C:\Users\Rajkumar\AppData\Roaming\Trae
- C:\Users\Rajkumar\AppData\Roaming\Cursor
- C:\Users\Rajkumar\AppData\Roaming\Kiro
- C:\Users\Rajkumar\AppData\Roaming\Antigravity (if exists)
- C:\Users\Rajkumar\AppData\Roaming\Qoder (equivalent to QoderWork)
- C:\Users\Rajkumar\AppData\Roaming\devin

### 2. create-scheduled-task.ps1
**Task setup script** that:
- Creates a Windows Scheduled Task running every 30 minutes
- Uses PowerShell's ScheduledTasks module
- Creates daily log files in C:\Scripts\Logs\
- Runs with highest privileges for proper access
- Allows you to verify the task configuration

## Directory Structure

```
C:\Scripts\
├── appfolder-cleaner.ps1
├── create-scheduled-task.ps1
├── scheduled-task-action.ps1 (created by setup)
├── Logs\          (contains daily log files)
└── Backups\       (contains backup copies of deleted folders)
```

## How to Use

### Option 1: Run Cleanup Manually
```powershell
# Run the cleanup once
C:\Scripts\appfolder-cleaner.ps1
```

### Option 2: Set Up Automated Scheduling
```powershell
# Open PowerShell as Administrator and run:
C:\Scripts\create-scheduled-task.ps1
```

### Option 3: Check Scheduled Task Status
```powershell
# Verify the task is registered
Get-ScheduledTask -TaskName "MyCleanPCAppFolderCleanup"

# View task details
Get-ScheduledTaskInfo -TaskName "MyCleanPCAppFolderCleanup"

# Disable the task if needed
Disable-ScheduledTask -TaskName "MyCleanPCAppFolderCleanup"
```

## Safety Features

1. **Backup Verification**: Creates timestamped backups of all folders before deletion
2. **Error Handling**: Gracefully skips missing folders without stopping
3. **Log Rotation**: Daily log files with size limits to prevent disk issues
4. **Battery Check**: Optional safety check to prevent data loss on laptops
5. **Multiple Deletion Methods**: Attempts .NET deletion, falls back to CMD if needed

## Log Files

- **Daily Logs**: Stored in C:\Scripts\Logs\ using timestamped filenames
- **Content**: Includes timestamps, operation status, folder sizes, and error messages
- **Rotation**: Files are rotated when they exceed 10MB in size

## Configuration

The scripts use the following configuration:
- **Username**: Rajkumar
- **Log Directory**: C:\Scripts\Logs\
- **Backup Directory**: C:\Scripts\Backups\AppFolders
- **Maximum Log Size**: 10MB per log file
- **Schedule**: Every 30 minutes indefinitely
- **Execution Policy**: Bypassed for script compatibility

## Important Notes

1. The scripts should be run with appropriate permissions to access user profile folders
2. Backup folders will accumulate over time - consider cleaning this directory periodically
3. The scripts are designed to be safe and should not affect system stability
4. Multiple folders with similar names (e.g., Qoder vs QoderWork) are handled appropriately

## Support

For issues or questions about the AppFolder Cleaner script, refer to the documentation or the existing My Clean PC cleanup infrastructure in the scripts directory.