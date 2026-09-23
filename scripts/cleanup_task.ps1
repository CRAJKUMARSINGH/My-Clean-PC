# My Clean PC - Scheduled Cleanup Task (PowerShell)
# Requires clean-pc-core.ps1 in the same folder (e.g. C:\Scripts\)
# Run as SYSTEM via Task Scheduler - shows warning before cleaning
# Downloads folder is intentionally NEVER touched.
# Passwords (Login Data, key4.db) are intentionally NEVER touched.

$ErrorActionPreference = "SilentlyContinue"
$ConfirmPreference = "None"
$ProgressPreference = "SilentlyContinue"
$logFile = Join-Path $PSScriptRoot "cleanup_log.txt"
$tempLogFile = Join-Path $PSScriptRoot "temp_cleaner_log.txt"

$corePath = Join-Path $PSScriptRoot "clean-pc-core.ps1"
if (-not (Test-Path $corePath)) {
    $errLine = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: clean-pc-core.ps1 not found beside cleanup_task.ps1"
    Add-Content -Path $logFile -Value $errLine -ErrorAction SilentlyContinue
    Add-Content -Path $tempLogFile -Value $errLine -ErrorAction SilentlyContinue
    exit 1
}
. $corePath

function Write-Log {
    param([string]$Message)
    $logLine = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Write-Host $logLine
    Add-Content -Path $logFile -Value $logLine -ErrorAction SilentlyContinue
    Add-Content -Path $tempLogFile -Value $logLine -ErrorAction SilentlyContinue
}

try {
    Write-Log "===== Cleanup Started ====="
    
    # Show warning before cleaning starts
    try {
        Show-MyCleanPCNotice -Title "My Clean PC - Scheduled Cleaning Starting" -Body "Scheduled cleanup will begin in 30 seconds. You can continue using your computer normally." -Log { param([string]$Message) Write-Log $Message }
        Start-Sleep -Seconds 30
    } catch {
        Write-Log "Warning notification failed, proceeding with cleanup"
    }
    
    Invoke-MyCleanPCCore -Log { param([string]$Message) Write-Log $Message } -ManageWindowsUpdateService
    Write-Log "===== Cleanup Finished ====="
} catch {
    Write-Log "===== Cleanup FAILED: $($_.Exception.Message) ====="
    try {
        Show-MyCleanPCNotice -Title "My Clean PC stopped" -Body "Cleanup did not finish. You can still use your browsers and AI tools." -Log { param([string]$Message) Write-Log $Message }
    } catch {}
    exit 1
}
