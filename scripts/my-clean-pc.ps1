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

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  My Clean PC - Windows Cache Cleaner"       -ForegroundColor Cyan
Write-Host "  Designed for Priyanka"                     -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Passwords (Login Data) are NEVER touched." -ForegroundColor Yellow
Write-Host "  Downloads folder is NEVER touched."        -ForegroundColor Yellow
Write-Host "  Busy temp/cache files auto-skip - no prompts." -ForegroundColor Yellow
Write-Host ""

function Write-CleanLog {
    param([string]$Message)
    if ($Message -match '^-- STEP') {
        Write-Host ""
        Write-Host $Message -ForegroundColor Cyan
    } elseif ($Message -match 'auto-skip|NOT touched|skipped') {
        Write-Host $Message -ForegroundColor DarkYellow
    } else {
        Write-Host $Message -ForegroundColor Green
    }
}

Invoke-MyCleanPCCore -Log { param([string]$Message) Write-CleanLog $Message }

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  All done!"                                 -ForegroundColor Green
Write-Host "  Temp + app cache cleaned (locked files skipped)." -ForegroundColor Green
Write-Host "  Passwords (Login Data) were NOT touched."  -ForegroundColor Green
Write-Host "  Downloads folder was NOT touched."         -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
