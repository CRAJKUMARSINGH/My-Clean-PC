# My Clean PC - Windows Cache Cleaner (PowerShell)
# Designed for Priyanka
# Requires clean-pc-core.ps1 in the same folder.
# Run: PowerShell -ExecutionPolicy Bypass -File my-clean-pc.ps1

$ErrorActionPreference = "SilentlyContinue"
$ConfirmPreference = "None"
$ProgressPreference = "SilentlyContinue"

$corePath = Join-Path $PSScriptRoot "clean-pc-core.ps1"
if (-not (Test-Path $corePath)) {
    Write-Host "ERROR: clean-pc-core.ps1 not found beside my-clean-pc.ps1" -ForegroundColor Red
    exit 1
}
. $corePath

# Silent mode - no output

# Track whether we have seen the space-freed line so we can highlight it.
$script:SpaceFreedLine = $null

function Write-CleanLog {
    param([string]$Message)
    # Silent mode - no output
}

Invoke-MyCleanPCCore -Log { param([string]$Message) Write-CleanLog $Message }

# Silent mode - no summary output
