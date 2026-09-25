<#
.SYNOPSIS
    Safe Windows 10 & Application Cache Cleaner (Repaired).
.DESCRIPTION
    Safely cleans Windows user temporary files, developer/AI tool caches, and browser caches
    (Google Chrome, Microsoft Edge, Mozilla Firefox, Brave, Vivaldi, Opera).
    
    CRITICAL SAFETY GUARANTEES:
    - Passwords, credentials, and vault files (Login Data, key4.db, logins.json) are NEVER touched.
    - Bookmarks and browsing history (places.sqlite, Bookmarks, History) are NEVER touched.
    - Cookies and active sessions (Cookies, Network\Cookies, cookies.sqlite) are NEVER touched.
    - Autofill and form data (Web Data, formhistory.sqlite) are NEVER touched.
    - Roaming application settings (%APPDATA%\Cursor, %APPDATA%\Windsurf, etc.) are NEVER touched.
    - Downloads folder is 100% PRESERVED and protected with strict path filters.
    - Windows Prefetch, Event Logs, and MachineGuid registry values are NEVER touched.
    - Running browsers are safely detected; their caches are skipped if open to prevent corruption.
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Clean,
    [switch]$ForceCloseBrowsers,
    [switch]$IncludeSystemTemp,
    [string]$LogFile = ""
)

$ErrorActionPreference = "Continue"

# Resolve path to safe cleanup engine
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$enginePath = Join-Path $scriptDir "Safe-Cleanup-Engine.ps1"

if (-not (Test-Path -LiteralPath $enginePath)) {
    # Check LocalAppData installed location
    $altEngine = Join-Path "$env:LOCALAPPDATA\MyCleanPC" "Safe-Cleanup-Engine.ps1"
    if (Test-Path -LiteralPath $altEngine) {
        $enginePath = $altEngine
    } else {
        Write-Error "CRITICAL: Safe-Cleanup-Engine.ps1 not found in $scriptDir or $altEngine"
        exit 1
    }
}

if ([string]::IsNullOrWhiteSpace($LogFile)) {
    $LogFile = Join-Path $scriptDir "ai_cleaner_log.txt"
}

# Dot-source the safe engine
. $enginePath

# Default behavior: If invoked with no switches (e.g. from scheduled task), execute safe -Clean
$runClean = $Clean
if (-not $DryRun -and -not $Clean) {
    $runClean = $true
}

# Run the safe cleaner
Invoke-SafeWindows10Cleanup `
    -DryRun:$DryRun `
    -Clean:$runClean `
    -ForceCloseBrowsers:$ForceCloseBrowsers `
    -IncludeSystemTemp:$IncludeSystemTemp `
    -LogFile $LogFile