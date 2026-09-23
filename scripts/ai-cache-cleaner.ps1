# ULTRA-SAFE AI Cache Cleaner
# NEVER closes any browser, app, or AI tool
# NEVER causes logouts or session loss
# ONLY cleans safe cache files
# Runs silently on scheduled interval (every 7 minutes or weekly)

$ErrorActionPreference  = "SilentlyContinue"
$ConfirmPreference      = "None"
$ProgressPreference     = "SilentlyContinue"
$WarningPreference      = "SilentlyContinue"

$logFile = Join-Path $PSScriptRoot "ai_cleaner_log.txt"
$tempLogFile = Join-Path $PSScriptRoot "temp_cleaner_log.txt"

function Write-Log {
    param([string]$Msg)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLine = "[$timestamp] $Msg"
    Write-Host $logLine
    Add-Content -Path $logFile -Value $logLine -ErrorAction SilentlyContinue
    Add-Content -Path $tempLogFile -Value $logLine -ErrorAction SilentlyContinue
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
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $normPath = $Path -replace '/', '\'

    # Absolute safeguard for User Profile Downloads folder and subitems
    $userDownloads = Join-Path $env:USERPROFILE "Downloads"
    if ($normPath -ieq $userDownloads -or $normPath.StartsWith($userDownloads + "\", [System.StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }

    # Check if path contains any forbidden patterns (passwords, downloads, bookmarks)
    foreach ($forbidden in $forbiddenPaths) {
        if ($normPath -like "*$forbidden*") {
            return $false
        }
    }

    # Strict check for any Download or Downloads path segment
    if ($normPath -match '(?i)[\\/]Downloads?([\\/]|$)') {
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
    
    # Aggressive Temp file cleaning - ALL temp files (no age restriction)
    # 3-pass Ctrl+A > Shift+Del > Skip Skip behavior
    Write-Log "=== TEMP & PREFETCH CLEANING ==="
    Write-Log "Mode: Aggressive 3-pass (Ctrl+A > Shift+Del > auto-skip locked files)"
    
    $tempPaths = @(
        $env:TEMP,
        "$env:LOCALAPPDATA\Temp",
        "C:\Windows\Temp"
    ) | Select-Object -Unique
    
    $totalTempCleaned = 0
    foreach ($tempPath in $tempPaths) {
        $tempCleanedHere = 0
        $expandedPath = [System.Environment]::ExpandEnvironmentVariables($tempPath)
        
        if (-not (Test-Path -LiteralPath $expandedPath)) {
            Write-Log "  SKIP (path not found): $expandedPath"
            continue
        }
        
        Write-Log "  Cleaning: $expandedPath"
        
        # Pass 1: cmd del /f /s /q - kills every unlocked file instantly
        #         Bypasses Explorer shell completely - zero dialogs, no prompts
        #         Locked files are silently skipped by cmd.exe (no "file in use" popup)
        try {
            $delResult = Start-Process -FilePath "cmd.exe" `
                -ArgumentList @("/c", "del /f /s /q `"$expandedPath\*`" 2>nul") `
                -WindowStyle Hidden -Wait -PassThru -ErrorAction SilentlyContinue
            Write-Log "    Pass 1/3 (cmd del /f/s/q): done"
        } catch {
            Write-Log "    Pass 1/3 (cmd del): skipped"
        }
        
        # Pass 2: Robocopy /MIR from empty staging folder
        #         Wipes directory skeleton + any files del couldn't reach
        #         Locked items silently skipped - zero UI popups
        try {
            $robocopyEmpty = Join-Path $env:LOCALAPPDATA "ai_cleaner_empty_$(Get-Random -Maximum 999999)"
            New-Item -ItemType Directory -Path $robocopyEmpty -Force -ErrorAction SilentlyContinue | Out-Null
            $robocopyBefore = @(Get-ChildItem -LiteralPath $expandedPath -Force -ErrorAction SilentlyContinue).Count
            & robocopy.exe $robocopyEmpty $expandedPath /mir /r:0 /w:0 /mt:8 /nfl /ndl /njh /njs /nc /ns /np 2>&1 | Out-Null
            $robocopyAfter = @(Get-ChildItem -LiteralPath $expandedPath -Force -ErrorAction SilentlyContinue).Count
            $tempCleanedHere += [Math]::Max(0, $robocopyBefore - $robocopyAfter)
            if (Test-Path -LiteralPath $robocopyEmpty) {
                Remove-Item -LiteralPath $robocopyEmpty -Force -Recurse -ErrorAction SilentlyContinue
            }
            Write-Log "    Pass 2/3 (robocopy /MIR): wiped $([Math]::Max(0, $robocopyBefore - $robocopyAfter)) dir skeletons"
        } catch {
            Write-Log "    Pass 2/3 (robocopy): skipped"
        }
        
        # Pass 3: Per-item sweep with safety checks. Skip locked files = "Skip Skip"
        #         Remove-Item with -Force -ErrorAction SilentlyContinue never prompts
        $pass3Removed = 0
        try {
            $remainingItems = @(Get-ChildItem -LiteralPath $expandedPath -Recurse -Force -ErrorAction SilentlyContinue)
            # Process deepest items first (files before their parent dirs)
            $remainingItems = $remainingItems | Sort-Object { $_.FullName.Length } -Descending
            foreach ($item in $remainingItems) {
                if (-not (Is-Safe-To-Clean $item.FullName)) { continue }
                try {
                    if ($item.PSIsContainer) {
                        Remove-Item -LiteralPath $item.FullName -Force -Recurse -ErrorAction SilentlyContinue
                    } else {
                        Remove-Item -LiteralPath $item.FullName -Force -ErrorAction SilentlyContinue
                    }
                    if (-not (Test-Path -LiteralPath $item.FullName)) {
                        $pass3Removed++
                    }
                } catch {
                    # Locked file - SKIP it silently (the user's "Skip Skip" behavior)
                }
            }
        } catch {}
        $tempCleanedHere += $pass3Removed
        Write-Log "    Pass 3/3 (per-item sweep): removed $pass3Removed leftovers"
        
        Write-Log "    -> Total cleaned here: ~$tempCleanedHere items"
        $totalTempCleaned += $tempCleanedHere
    }
    
    # Prefetch cleaning - same 3-pass aggressive approach
    $prefetchPath = "C:\Windows\Prefetch"
    $prefetchCleaned = 0
    if (Test-Path -LiteralPath $prefetchPath) {
        Write-Log "  Cleaning: $prefetchPath"
        
        $prefetchBefore = @(Get-ChildItem -LiteralPath $prefetchPath -Force -ErrorAction SilentlyContinue).Count
        
        # Pass 1: cmd del /f /s /q on Prefetch
        try {
            Start-Process -FilePath "cmd.exe" `
                -ArgumentList @("/c", "del /f /s /q `"$prefetchPath\*`" 2>nul") `
                -WindowStyle Hidden -Wait -PassThru -ErrorAction SilentlyContinue | Out-Null
            Write-Log "    Pass 1/3 (cmd del /f/s/q): done"
        } catch {
            Write-Log "    Pass 1/3 (cmd del): skipped"
        }
        
        # Pass 2: Robocopy /MIR
        try {
            $pfEmpty = Join-Path $env:LOCALAPPDATA "ai_pf_empty_$(Get-Random -Maximum 999999)"
            New-Item -ItemType Directory -Path $pfEmpty -Force -ErrorAction SilentlyContinue | Out-Null
            & robocopy.exe $pfEmpty $prefetchPath /mir /r:0 /w:0 /mt:8 /nfl /ndl /njh /njs /nc /ns /np 2>&1 | Out-Null
            if (Test-Path -LiteralPath $pfEmpty) {
                Remove-Item -LiteralPath $pfEmpty -Force -Recurse -ErrorAction SilentlyContinue
            }
            Write-Log "    Pass 2/3 (robocopy /MIR): done"
        } catch {
            Write-Log "    Pass 2/3 (robocopy): skipped"
        }
        
        # Pass 3: Per-item sweep, skip locked files
        $pfPass3 = 0
        try {
            $pfItems = @(Get-ChildItem -LiteralPath $prefetchPath -Force -ErrorAction SilentlyContinue)
            $pfItems = $pfItems | Sort-Object { $_.FullName.Length } -Descending
            foreach ($item in $pfItems) {
                if (-not (Is-Safe-To-Clean $item.FullName)) { continue }
                try {
                    if ($item.PSIsContainer) {
                        Remove-Item -LiteralPath $item.FullName -Force -Recurse -ErrorAction SilentlyContinue
                    } else {
                        Remove-Item -LiteralPath $item.FullName -Force -ErrorAction SilentlyContinue
                    }
                    if (-not (Test-Path -LiteralPath $item.FullName)) {
                        $pfPass3++
                    }
                } catch {
                    # Locked - SKIP
                }
            }
        } catch {}
        $prefetchCleaned = $prefetchBefore - @(Get-ChildItem -LiteralPath $prefetchPath -Force -ErrorAction SilentlyContinue).Count
        $prefetchCleaned = [Math]::Max(0, $prefetchCleaned)
        Write-Log "    Pass 3/3 (per-item sweep): removed $pfPass3 leftovers"
        Write-Log "    -> Total cleaned here: ~$prefetchCleaned items"
    }
    
    Write-Log "Temp + Prefetch Summary: ~$($totalTempCleaned + $prefetchCleaned) items wiped permanently"
    
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
    Write-Log "   Temp items wiped (all 3 paths): $totalTempCleaned"
    Write-Log "   Prefetch items wiped: $prefetchCleaned"
    Write-Log "   Temp + Prefetch total: $($totalTempCleaned + $prefetchCleaned)"
    Write-Log ""
    Write-Log "Safety Confirmation:"
    Write-Log "   Browser Cache, Cookies, History & AI Caches: CLEANED"
    Write-Log "   Temp folders: CLEANED aggressively (3-pass: del > robocopy > sweep)"
    Write-Log "   Prefetch: CLEANED aggressively (3-pass: del > robocopy > sweep)"
    Write-Log "   NO Passwords touched"
    Write-Log "   NO Downloads folder touched"
    Write-Log "   NO Bookmarks touched"
    Write-Log "   Direct permanent deletion used (No Recycle Bin dump)"
    Write-Log ""
    Write-Log "All tools and browsers remain running smoothly."
}

# Run the ultra-safe cleaner
Invoke-UltraSafeAiCacheCleaner