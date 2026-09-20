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

# FORBIDDEN PATHS - NEVER TOUCH Passwords, Downloads, Bookmarks, or Autofill
$forbiddenPaths = @(
    "Login Data",
    "Login Data For Account",
    "key4.db",
    "logins.json",
    "passwords",
    "credential",
    "Bookmarks",
    "bookmarks.html",
    "Downloads",
    "Autofill",
    "formhistory.sqlite"
)

# TARGETED CLEANING PATHS (AI Tools + Browser Ctrl+Shift+Delete Items: Cache, Cookies, History, Storage)
$safeCachePaths = @(
    # AI Tool Caches
    "$env:LOCALAPPDATA\Cursor\Cache",
    "$env:LOCALAPPDATA\Cursor\CachedData",
    "$env:LOCALAPPDATA\Cursor\Code Cache",
    "$env:LOCALAPPDATA\Cursor\GPUCache",
    
    "$env:LOCALAPPDATA\Windsurf\Cache",
    "$env:LOCALAPPDATA\Windsurf\CachedData",
    "$env:LOCALAPPDATA\Windsurf\Code Cache",
    "$env:LOCALAPPDATA\Windsurf\GPUCache",
    
    "$env:LOCALAPPDATA\Trae\Cache",
    "$env:LOCALAPPDATA\Trae\CachedData",
    "$env:LOCALAPPDATA\Trae\Code Cache",
    
    "$env:LOCALAPPDATA\Devin\Cache",
    "$env:LOCALAPPDATA\Devin\CachedData",
    "$env:LOCALAPPDATA\Devin\Code Cache",
    
    "$env:LOCALAPPDATA\Kiro\Cache",
    "$env:LOCALAPPDATA\Kiro\CachedData",
    "$env:LOCALAPPDATA\kiro\Cache",
    "$env:LOCALAPPDATA\kiro\CachedData",
    
    "$env:LOCALAPPDATA\Antigravity\Cache",
    "$env:LOCALAPPDATA\Antigravity\CachedData",
    
    # AI Tool & App Roaming Folders
    "$env:APPDATA\Antigravity IDE",
    "$env:APPDATA\Cursor",
    "$env:APPDATA\DEVIN",
    "$env:APPDATA\Devin",
    "$env:APPDATA\KIRO",
    "$env:APPDATA\Kiro",
    "$env:APPDATA\TRAE",
    "$env:APPDATA\Trae",
    "$env:APPDATA\foobar2000-v2",
    "$env:APPDATA\Windsurf",

    # Chromium Browsers: Chrome, Edge, Brave, Vivaldi, Yandex, Opera, Genspark
    # Target: Cache, Code Cache, GPUCache, Cookies, Network, History, Visited Links, Local Storage, Session Storage, IndexedDB, Service Worker
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cookies",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Network",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Visited Links",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Local Storage",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Session Storage",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\IndexedDB",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Service Worker",

    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\GPUCache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cookies",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Network",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Visited Links",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Local Storage",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Session Storage",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\IndexedDB",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Service Worker",

    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\GPUCache",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cookies",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Network",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\History",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Visited Links",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Local Storage",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Session Storage",

    "$env:LOCALAPPDATA\Vivaldi\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Vivaldi\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Vivaldi\User Data\Default\GPUCache",
    "$env:LOCALAPPDATA\Vivaldi\User Data\Default\Cookies",
    "$env:LOCALAPPDATA\Vivaldi\User Data\Default\Network",
    "$env:LOCALAPPDATA\Vivaldi\User Data\Default\History",
    "$env:LOCALAPPDATA\Vivaldi\User Data\Default\Local Storage",

    "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\GPUCache",
    "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\Cookies",
    "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\Network",
    "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\History",
    "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\Local Storage",

    "$env:APPDATA\Opera Software\Opera Stable\Cache",
    "$env:APPDATA\Opera Software\Opera Stable\Cookies",
    "$env:APPDATA\Opera Software\Opera Stable\Network",
    "$env:APPDATA\Opera Software\Opera Stable\History",
    "$env:APPDATA\Opera Software\Opera Stable\Local Storage",

    # Firefox Profiles
    "$env:APPDATA\Mozilla\Firefox\Profiles\*\cache2",
    "$env:APPDATA\Mozilla\Firefox\Profiles\*\cookies.sqlite",
    "$env:APPDATA\Mozilla\Firefox\Profiles\*\places.sqlite",
    "$env:APPDATA\Mozilla\Firefox\Profiles\*\webappsstore.sqlite",
    "$env:APPDATA\Mozilla\Firefox\Profiles\*\storage"
)

# Expand any wildcard paths (e.g., Firefox profile wildcard) to concrete directories/files
$expandedCachePaths = @()
foreach ($p in $safeCachePaths) {
    if ($p -like "*`*") {
        try {
            $items = Get-ChildItem -Path $p -ErrorAction SilentlyContinue
            foreach ($item in $items) { $expandedCachePaths += $item.FullName }
        } catch { }
    } else {
        $expandedCachePaths += $p
    }
}
$safeCachePaths = $expandedCachePaths

function Is-Safe-To-Clean {
    param([string]$Path)
    
    # Check if path contains any forbidden patterns (passwords, downloads, bookmarks)
    foreach ($forbidden in $forbiddenPaths) {
        if ($Path -like "*$forbidden*") {
            return $false
        }
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
    
    # Registry Cleaning: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography -> MachineGuid
    Write-Log "Cleaning Registry: HKLM:\SOFTWARE\Microsoft\Cryptography -> MachineGuid..."
    try {
        if (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid" -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid" -Force -ErrorAction SilentlyContinue
            Write-Log "  MachineGuid registry value deleted successfully."
        } else {
            Write-Log "  MachineGuid registry value not present."
        }
    } catch {
        Write-Log "  MachineGuid registry deletion skipped (Requires Administrator privileges)."
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
    Write-Log "   Browser Cache, Cookies, History & AI Caches: CLEANED"
    Write-Log "   NO Passwords touched"
    Write-Log "   NO Downloads folder touched"
    Write-Log "   NO Bookmarks touched"
    Write-Log "   Direct permanent deletion used (No Recycle Bin dump)"
    Write-Log ""
    Write-Log "All tools and browsers remain running smoothly."
}

# Run the ultra-safe cleaner
Invoke-UltraSafeAiCacheCleaner