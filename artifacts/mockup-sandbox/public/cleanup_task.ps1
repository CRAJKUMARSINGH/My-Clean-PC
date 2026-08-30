# My Clean PC - Scheduled Cleanup Task (PowerShell)
# Requires clean-pc-core.ps1 in the same folder (e.g. C:\Scripts\)
# Run as SYSTEM via Task Scheduler - no interactive prompts
# Downloads folder is intentionally NEVER touched.
# Passwords (Login Data, key4.db) are intentionally NEVER touched.

$ErrorActionPreference = "SilentlyContinue"
$ConfirmPreference = "None"
$ProgressPreference = "SilentlyContinue"
$logFile = Join-Path $PSScriptRoot "cleanup_log.txt"

$corePath = Join-Path $PSScriptRoot "clean-pc-core.ps1"
if (-not (Test-Path $corePath)) {
    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: clean-pc-core.ps1 not found beside cleanup_task.ps1"
    exit 1
}
. $corePath

function Write-Log {
    param([string]$Message)
    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ErrorAction SilentlyContinue
}

Write-Log "===== Cleanup Started ====="
Invoke-MyCleanPCCore -Log { param([string]$Message) Write-Log $Message } -ManageWindowsUpdateService
Write-Log "===== Cleanup Finished ====="
