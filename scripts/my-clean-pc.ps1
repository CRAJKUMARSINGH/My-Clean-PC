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

# Track whether we have seen the space-freed line so we can highlight it.
$script:SpaceFreedLine = $null

function Write-CleanLog {
    param([string]$Message)

    # Machine-readable sentinels — captured silently, not printed
    if ($Message -match '^PRESCAN_ESTIMATE:') {
        $script:EstimateStr = $Message -replace '^PRESCAN_ESTIMATE:', ''
        return
    }
    if ($Message -match '^FREED_BYTES:') {
        return   # used by Electron GUI only
    }

    if ($Message -match '^-- PRE-SCAN') {
        Write-Host ""
        Write-Host $Message -ForegroundColor Yellow
    } elseif ($Message -match '^-- STEP') {
        Write-Host ""
        Write-Host $Message -ForegroundColor Cyan
    } elseif ($Message -match 'Estimated junk found') {
        Write-Host $Message -ForegroundColor Yellow
    } elseif ($Message -match "^    ") {
        # Indented pre-scan top-5 rows
        Write-Host $Message -ForegroundColor DarkYellow
    } elseif ($Message -match "That's like") {
        Write-Host $Message -ForegroundColor Cyan
    } elseif ($Message -match 'Space freed this run') {
        $script:SpaceFreedLine = $Message
    } elseif ($Message -match '^={3,}') {
        # Suppress inner separators; we draw our own below
    } elseif ($Message -match 'auto-skip|NOT touched|skipped') {
        Write-Host $Message -ForegroundColor DarkYellow
    } else {
        Write-Host $Message -ForegroundColor Green
    }
}

Invoke-MyCleanPCCore -Log { param([string]$Message) Write-CleanLog $Message }

# ---- Final summary block ------------------------------------------------
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  All done!" -ForegroundColor Green

if ($script:SpaceFreedLine) {
    # Extract just the size string (e.g. "3.42 GB") for a punchy display line
    $sizeOnly = ($script:SpaceFreedLine -replace '.*Space freed this run:\s*', '').Trim()
    Write-Host ""
    Write-Host ("  >>> " + $sizeOnly + " freed <<<") -ForegroundColor White -BackgroundColor DarkGreen
    Write-Host ""
}

Write-Host "  Temp + app cache cleaned (locked files skipped)." -ForegroundColor Green
Write-Host "  Passwords (Login Data) were NOT touched."         -ForegroundColor Green
Write-Host "  Autofill/form data was NOT touched."              -ForegroundColor Green
Write-Host "  Downloads folder was NOT touched."                -ForegroundColor Green
Write-Host ""
Write-Host "  THANKS CODEX FOR UR CLEAN PC" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Cyan
