# AI Cache Cleaner - Specialized for AI tools cache/temp cleanup every 24 minutes
# Cleans AI tool roaming cache and temp files WITHOUT closing any running tools
# Dot-sources clean-pc-core.ps1 for the cleaning functions

$ErrorActionPreference  = "SilentlyContinue"
$ConfirmPreference      = "None"
$ProgressPreference     = "SilentlyContinue"
$WarningPreference      = "SilentlyContinue"

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CoreScript = Join-Path $ScriptDir "clean-pc-core.ps1"

# Dot-source the core cleaning script
if (Test-Path $CoreScript) {
    . $CoreScript
} else {
    Write-Host "ERROR: clean-pc-core.ps1 not found at $CoreScript"
    exit 1
}

function Write-Log {
    param([string]$Msg)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLine = "[$timestamp] $Msg"
    Write-Host $logLine
}

function Invoke-AiCacheCleaner {
    param(
        [scriptblock]$Log = { param([string]$Message) Write-Host $Message }
    )

    & $Log "=== AI Cache Cleaner - 24-minute cycle ==="
    & $Log "Cleaning AI tool roaming cache and temp files WITHOUT closing running tools"

    # Get AI cache target paths (same as main cleaner but we won't close processes)
    $aiTargets = @(Get-AiCacheTargetPaths)
    
    if ($aiTargets.Count -eq 0) {
        & $Log "No AI cache folders found on this PC."
        return
    }

    & $Log "Found $($aiTargets.Count) AI cache target(s) to clean"

    $clearedCount = 0
    foreach ($raw in $aiTargets) {
        $exp = [System.Environment]::ExpandEnvironmentVariables($raw)
        if (-not (Test-Path -LiteralPath $exp)) { continue }
        
        & $Log "Cleaning: $exp"
        
        if (Test-Path -LiteralPath $exp -PathType Container) {
            # Use KeepContainer to preserve the directory structure
            if (Remove-DirectorySilent -LiteralPath $exp -KeepContainer) { 
                $clearedCount++ 
                & $Log "  ✓ Cleaned successfully"
            } else {
                $left = @(Get-ChildItem -LiteralPath $exp -Force -ErrorAction SilentlyContinue).Count
                if ($left -gt 0) {
                    & $Log "  ⚠ Some items still locked: $left (will be cleaned next cycle)"
                }
            }
        } else {
            if (Remove-SafePathWithRetry -LiteralPath $exp) { 
                $clearedCount++ 
                & $Log "  ✓ Cleaned successfully"
            }
        }
    }

    # Also clean AI-specific temp directories
    $aiTempPaths = @(
        "%LOCALAPPDATA%\Cursor\Cache",
        "%LOCALAPPDATA%\Cursor\CachedData",
        "%LOCALAPPDATA%\Windsurf\Cache", 
        "%LOCALAPPDATA%\Windsurf\CachedData",
        "%LOCALAPPDATA%\Trae\Cache",
        "%LOCALAPPDATA%\Trae\CachedData",
        "%LOCALAPPDATA%\Devin\Cache",
        "%LOCALAPPDATA%\Devin\CachedData",
        "%LOCALAPPDATA%\Antigravity\Cache",
        "%LOCALAPPDATA%\Antigravity\CachedData",
        "%LOCALAPPDATA%\kiro\Cache",
        "%LOCALAPPDATA%\Kiro\Cache",
        "%LOCALAPPDATA%\Genspark\Cache",
        "%LOCALAPPDATA%\ChatGPT\Cache",
        "%LOCALAPPDATA%\Claude\Cache"
    )

    foreach ($raw in $aiTempPaths) {
        $exp = [System.Environment]::ExpandEnvironmentVariables($raw)
        if (Test-Path -LiteralPath $exp -PathType Container) {
            & $Log "Cleaning temp: $exp"
            if (Remove-DirectorySilent -LiteralPath $exp -KeepContainer) { 
                $clearedCount++ 
            }
        }
    }

    & $Log "=== AI Cache Cleaner completed ==="
    & $Log "Cleared $clearedCount AI cache/temp locations"
    & $Log "No AI tools were closed - they continued running during cleanup"
}

# Run the AI cache cleaner
Invoke-AiCacheCleaner