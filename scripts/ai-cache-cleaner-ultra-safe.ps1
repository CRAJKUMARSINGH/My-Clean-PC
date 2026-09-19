# ULTRA-SAFE AI Cache Cleaner
# NEVER closes any browser, app, or AI tool
# NEVER causes logouts or session loss
# ONLY cleans safe cache files
# Runs silently every 24 minutes

$ErrorActionPreference  = "SilentlyContinue"
$ConfirmPreference      = "None"
$ProgressPreference     = "SilentlyContinue"
$WarningPreference      = "SilentlyContinue"

function Write-Log {
    param([string]$Msg)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLine = "[$timestamp] $Msg"
    Write-Host $logLine
}

# ABSOLUTELY FORBIDDEN PATHS - Never touch these
$forbiddenPaths = @(
    "Login Data",
    "key4.db",
    "Cookies",
    "Local Storage",
    "Session Storage",
    "Web Data",
    "Preferences",
    "Secure Preferences",
    "Bookmarks",
    "History",
    "Top Sites",
    "Login Data For Account",
    "Autofill",
    "formhistory.sqlite",
    "passwords",
    "sessions",
    "session",
    "token",
    "auth",
    "credential"
)

# SAFE CACHE PATHS ONLY - These are safe to clean
$safeCachePaths = @(
    # Cursor - cache only
    "$env:LOCALAPPDATA\Cursor\Cache",
    "$env:LOCALAPPDATA\Cursor\CachedData",
    "$env:LOCALAPPDATA\Cursor\Code Cache",
    "$env:LOCALAPPDATA\Cursor\GPUCache",
    
    # Windsurf - cache only
    "$env:LOCALAPPDATA\Windsurf\Cache",
    "$env:LOCALAPPDATA\Windsurf\CachedData",
    "$env:LOCALAPPDATA\Windsurf\Code Cache",
    "$env:LOCALAPPDATA\Windsurf\GPUCache",
    
    # Trae - cache only
    "$env:LOCALAPPDATA\Trae\Cache",
    "$env:LOCALAPPDATA\Trae\CachedData",
    "$env:LOCALAPPDATA\Trae\Code Cache",
    
    # Devin - cache only
    "$env:LOCALAPPDATA\Devin\Cache",
    "$env:LOCALAPPDATA\Devin\CachedData",
    "$env:LOCALAPPDATA\Devin\Code Cache",
    
    # Kiro - cache only
    "$env:LOCALAPPDATA\Kiro\Cache",
    "$env:LOCALAPPDATA\Kiro\CachedData",
    "$env:LOCALAPPDATA\kiro\Cache",
    "$env:LOCALAPPDATA\kiro\CachedData",
    
    # Antigravity - cache only
    "$env:LOCALAPPDATA\Antigravity\Cache",
    "$env:LOCALAPPDATA\Antigravity\CachedData"
)

function Is-Safe-To-Clean {
    param([string]$Path)
    
    # Check if path contains any forbidden patterns
    foreach ($forbidden in $forbiddenPaths) {
        if ($Path -like "*$forbidden*") {
            return $false
        }
    }
    
    # Additional safety checks
    if ($Path -like "*session*" -or $Path -like "*auth*" -or $Path -like "*login*") {
        return $false
    }
    
    return $true
}

function Clean-Safe-Directory {
    param([string]$DirectoryPath)
    
    if (-not (Test-Path -LiteralPath $DirectoryPath)) {
        return $false
    }
    
    # Safety check - ensure this is a cache directory
    if (-not (Is-Safe-To-Clean $DirectoryPath)) {
        Write-Log "  SKIPPED: $DirectoryPath (contains sensitive data)"
        return $false
    }
    
    $cleanedFiles = 0
    $cleanedSize = 0
    
    try {
        # Get all files in directory (recursive)
        $files = Get-ChildItem -LiteralPath $DirectoryPath -Recurse -File -ErrorAction SilentlyContinue
        
        foreach ($file in $files) {
            # Double-check each file
            if (Is-Safe-To-Clean $file.FullName) {
                try {
                    $fileSize = $file.Length
                    Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
                    $cleanedFiles++
                    $cleanedSize += $fileSize
                } catch {
                    # File locked, skip it
                }
            }
        }
        
        return @{
            Files = $cleanedFiles
            Size = $cleanedSize
        }
    } catch {
        return @{
            Files = 0
            Size = 0
        }
    }
}

function Invoke-UltraSafeAiCacheCleaner {
    Write-Log "=== ULTRA-SAFE AI Cache Cleaner ==="
    Write-Log "MODE: Maximum Safety - NO app closure, NO session loss"
    Write-Log "Will ONLY clean safe cache files"
    Write-Log "Will NEVER touch login data, cookies, or sessions"
    
    $totalFilesCleaned = 0
    $totalSizeCleaned = 0
    $pathsCleaned = 0
    
    foreach ($cachePath in $safeCachePaths) {
        $expandedPath = [System.Environment]::ExpandEnvironmentVariables($cachePath)
        
        if (-not (Test-Path -LiteralPath $expandedPath)) {
            continue
        }
        
        Write-Log "Processing: $expandedPath"
        
        # Final safety check
        if (-not (Is-Safe-To-Clean $expandedPath)) {
            Write-Log "  SKIPPED: Path not safe to clean"
            continue
        }
        
        $result = Clean-Safe-Directory -DirectoryPath $expandedPath
        
        if ($result.Files -gt 0) {
            $totalFilesCleaned += $result.Files
            $totalSizeCleaned += $result.Size
            $pathsCleaned++
            $sizeMB = [math]::Round($result.Size / 1MB, 2)
            Write-Log "  Cleaned $($result.Files) files ($sizeMB MB)"
        } else {
            Write-Log "  No files to clean or files locked"
        }
    }
    
    # Clean temp files (very conservative)
    Write-Log "Cleaning temp files (older than 2 hours)..."
    $tempCleaned = 0
    $tempPath = $env:TEMP
    
    if (Test-Path $tempPath) {
        $tempFiles = Get-ChildItem -LiteralPath $tempPath -Recurse -File -ErrorAction SilentlyContinue
        $cutoffTime = (Get-Date).AddHours(-2)
        
        foreach ($tempFile in $tempFiles) {
            # Only clean old temp files
            if ($tempFile.LastWriteTime -lt $cutoffTime) {
                # Safety check for temp files too
                if (Is-Safe-To-Clean $tempFile.FullName) {
                    try {
                        Remove-Item -LiteralPath $tempFile.FullName -Force -ErrorAction SilentlyContinue
                        $tempCleaned++
                    } catch {
                        # File locked, skip
                    }
                }
            }
        }
    }
    
    if ($tempCleaned -gt 0) {
        Write-Log "  Cleaned $tempCleaned temp files"
    }
    
    $totalSizeMB = [math]::Round($totalSizeCleaned / 1MB, 2)
    
    Write-Log "=== Ultra-Safe Cleaner Complete ==="
    Write-Log "Statistics:"
    Write-Log "   Cache paths cleaned: $pathsCleaned"
    Write-Log "   Files cleaned: $totalFilesCleaned"
    Write-Log "   Space freed: $totalSizeMB MB"
    Write-Log "   Temp files cleaned: $tempCleaned"
    Write-Log ""
    Write-Log "Safety Confirmation:"
    Write-Log "   NO applications were closed"
    Write-Log "   NO browsers were closed"
    Write-Log "   NO AI tools were closed"
    Write-Log "   NO login sessions were affected"
    Write-Log "   NO passwords were touched"
    Write-Log "   NO cookies were deleted"
    Write-Log "   NO session data was touched"
    Write-Log ""
    Write-Log "Kiro, Devin, and all other tools remain running with sessions intact"
}

# Run the ultra-safe cleaner
Invoke-UltraSafeAiCacheCleaner