# My Clean PC - Scheduled Task Creator (PowerShell)
# Creates a scheduled task to run appfolder-cleaner.ps1 every 30 minutes
#
# Author: Script
# Date: 2026-07-21
# Purpose: Set up automated cleanup of application folders

param(
    [string]$TaskName = "MyCleanPCAppFolderCleanup",
    [string]$ScriptPath = "C:\Scripts\appfolder-cleaner.ps1",
    [string]$UserName = "Rajkumar",
    [string]$Description = "Automated cleanup of application folders from AppData\\Roaming every 30 minutes"
)

# Configuration
$triggerActionMessage = "Starting scheduled AppFolder cleanup..."
$triggerActionCompleteMessage = "Scheduled AppFolder cleanup completed successfully"
$triggerActionErrorMessage = "Scheduled AppFolder cleanup failed"

Write-Host "=== My Clean PC - Scheduled Task Creator ===" -ForegroundColor Cyan
Write-Host "Creating scheduled task: $TaskName" -ForegroundColor Yellow
Write-Host "Script to run: $ScriptPath" -ForegroundColor Yellow
Write-Host "User: $UserName" -ForegroundColor Yellow
Write-Host "" -ForegroundColor White

# Check if the script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Host "Error: Script file not found: $ScriptPath" -ForegroundColor Red
    exit 1
}

# Check if running with administrative privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Warning: Not running with administrative privileges. Scheduled tasks may require admin rights." -ForegroundColor Yellow
}

# Create the PowerShell script content for the scheduled task action
$actionScript = @"
`$ErrorActionPreference = `"SilentlyContinue`"
`$ConfirmPreference = `"None`"
`$ProgressPreference = `"SilentlyContinue`"

`$ScriptPath = `"$ScriptPath`"
`$LogDir = `"C:\Scripts\Logs`"
`$UserName = `"$UserName`"

if (-not (Test-Path `$LogDir)) { New-Item -ItemType Directory -Path `$LogDir -Force | Out-Null }

`$Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
`$LogFile = Join-Path `$LogDir `"ScheduledTaskLog-$(Get-Date -Format 'yyyyMMdd').log`"

`$LogEntry = "[`$Timestamp] [SCHED_TASK] Starting scheduled cleanup task..."
`$LogEntry | Out-File -FilePath `$LogFile -Append

# Logging function
function Write-Log {
    param([string]`$Message)
    `Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    `LogEntry = "[`$Timestamp] [SCHED_TASK] `$Message"
    Write-Host `$Message
    `LogEntry | Out-File -FilePath '`$'\$LogFile' -Append -ErrorAction SilentlyContinue
}

# Execute cleanup script
`StartTime = Get-Date
& `$ScriptPath
`EndTime = Get-Date
`Duration = `{0:g}` -f (`EndTime - `StartTime)
`Write-Log "Scheduled task completed in `$Duration"
"@

# Create the PowerShell script file for the scheduled task
$scheduledTaskScriptPath = "C:\Scripts\scheduled-task-action.ps1"
Set-Content -Path $scheduledTaskScriptPath -Value $actionScript -Force
Write-Host "Created scheduled task action script: $scheduledTaskScriptPath" -ForegroundColor Green

# Create the scheduled task using PowerShell ScheduledTasks module
$taskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($taskExists) {
    Write-Host "Warning: Scheduled task '$TaskName' already exists." -ForegroundColor Yellow
    $removeChoice = Read-Host "Do you want to remove the existing task and create a new one? (y/N)"
    if ($removeChoice -match "^[Yy]") {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Removed existing task: $TaskName" -ForegroundColor Yellow
    } else {
        Write-Host "Using existing task configuration." -ForegroundColor Green
        exit 0
    }
}

# Define the trigger (every 30 minutes)
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30) -RepetitionDuration (New-TimeSpan -Days 365*10) -Enabled

# Define the action
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File \"$ScriptPath\""

# Create the scheduled task
$task = New-ScheduledTask -TaskName $TaskName -Description $Description -Trigger $trigger -Action $action -RunLevel Highest

# Register the task
Register-ScheduledTask -TaskName $TaskName -InputObject $task -User `$UserName -Password (Read-Host -AsSecureString "Enter password for $UserName") -ErrorAction Stop

Write-Host "=== Scheduled Task Created Successfully ===" -ForegroundColor Green
Write-Host "Task Name: $TaskName" -ForegroundColor White
Write-Host "Task Description: $Description" -ForegroundColor White
Write-Host "Running every 30 minutes" -ForegroundColor White
Write-Host "Script: $ScriptPath" -ForegroundColor White
Write-Host "User: $UserName" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "You can verify the task in Task Scheduler (taskschd.msc) or using:" -ForegroundColor Gray
Write-Host "Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
Write-Host "" -ForegroundColor White
Write-Host "The script will run automatically every 30 minutes and log results to C:\Scripts\Logs\" -ForegroundColor Green