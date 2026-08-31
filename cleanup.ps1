## PowerShell cleanup script – cleanup.ps1
# This script silently clears the Windows TEMP directory and the Recycle Bin,
# logging its actions to logs/cleanup.log. It produces no console output.

# Ensure the logs directory exists
$logsDir = Join-Path -Path $PSScriptRoot -ChildPath 'logs'
if (-not (Test-Path -Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

$logPath = Join-Path -Path $logsDir -ChildPath 'cleanup.log'
"Cleanup started at $(Get-Date)" | Out-File -FilePath $logPath -Encoding utf8 -Append

# Clear TEMP folder silently
try {
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction Stop
    "TEMP folder cleared successfully." | Out-File -FilePath $logPath -Append
} catch {
    "Error clearing TEMP folder: $_" | Out-File -FilePath $logPath -Append
}

# Clear Recycle Bin silently
try {
    Clear-RecycleBin -Force -ErrorAction Stop
    "Recycle Bin cleared successfully." | Out-File -FilePath $logPath -Append
} catch {
    "Error clearing Recycle Bin: $_" | Out-File -FilePath $logPath -Append
}

"Cleanup completed at $(Get-Date)" | Out-File -FilePath $logPath -Append
