# My Clean PC - Scheduled Cleanup Task (PowerShell)
# Mirrors the 6-step cleaning scope defined in the app (App.tsx / WIN_PS1)
# Run as SYSTEM via Task Scheduler - no interactive prompts
# Downloads folder is intentionally NEVER touched.
# Passwords (Login Data, key4.db) are intentionally NEVER touched.

$ErrorActionPreference = "SilentlyContinue"
$logFile = "C:\Scripts\cleanup_log.txt"

function Write-Log {
    param([string]$Message)
    Add-Content -Path $logFile -Value "[$( Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ErrorAction SilentlyContinue
}

function Remove-Paths {
    param([string]$Label, [string[]]$Paths)
    $any = $false
    foreach ($p in $Paths) {
        $exp = [System.Environment]::ExpandEnvironmentVariables($p)
        if (Test-Path $exp) {
            Remove-Item -Recurse -Force $exp -ErrorAction SilentlyContinue
            $any = $true
        }
    }
    if ($any) { Write-Log "  [$Label] cleared." }
    else      { Write-Log "  [$Label] not found / already clean." }
}

function Clear-ChromiumCache {
    param([string]$Label, [string]$UserDataPath)
    $base = [System.Environment]::ExpandEnvironmentVariables($UserDataPath)
    if (-not (Test-Path $base)) { Write-Log "  [$Label] not installed, skipped."; return }

    $dirs  = @("Cache","Code Cache","GPUCache","Media Cache","blob_storage",
               "Service Worker\CacheStorage","Service Worker\ScriptCache",
               "Local Storage","IndexedDB","Session Storage","Application Cache",
               "Network","Extension State","Storage")
    $files = @("Cookies","Cookies-journal","History","History-journal",
               "Visited Links","Top Sites","Top Sites-journal",
               "Shortcuts","Shortcuts-journal","Network Action Predictor",
               "Favicons","Favicons-journal","Current Session","Last Session",
               "Current Tabs","Last Tabs","Web Data","Web Data-journal",
               "Extension Cookies","QuotaManager")

    Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $p = $_.FullName
        foreach ($d in $dirs)  { if (Test-Path "$p\$d") { Remove-Item -Recurse -Force "$p\$d" -ErrorAction SilentlyContinue } }
        foreach ($f in $files) { if (Test-Path "$p\$f") { Remove-Item -Force "$p\$f" -ErrorAction SilentlyContinue } }
        # Login Data intentionally SKIPPED - passwords are SAFE
    }
    Write-Log "  [$Label] cleared. (Passwords NOT touched)"
}

# ════════════════════════════════════════════════════════════════════
Write-Log "===== Cleanup Started ====="
# ════════════════════════════════════════════════════════════════════

Write-Log "-- STEP 1: AI App Caches --"
Remove-Paths "Antigravity"  @("%APPDATA%\Antigravity", "%LOCALAPPDATA%\Antigravity")
Remove-Paths "Cursor"       @("%APPDATA%\Cursor\Cache", "%APPDATA%\Cursor\CachedData", "%APPDATA%\Cursor\logs", "%LOCALAPPDATA%\cursor-updater")
Remove-Paths "Kiro"         @("%APPDATA%\kiro\Cache", "%APPDATA%\kiro\CachedData", "%LOCALAPPDATA%\kiro")
Remove-Paths "Trae AI"      @("%APPDATA%\Trae", "%APPDATA%\trae-ai", "%LOCALAPPDATA%\Trae")
Remove-Paths "Windsurf"     @("%APPDATA%\Windsurf\Cache", "%APPDATA%\Windsurf\CachedData", "%APPDATA%\Windsurf\logs", "%LOCALAPPDATA%\Windsurf")
Remove-Paths "Warp"         @("%APPDATA%\warp", "%LOCALAPPDATA%\Warp\data")
Remove-Paths "Devin"        @("%APPDATA%\Devin", "%LOCALAPPDATA%\Devin")
Remove-Paths "Genspark"     @("%APPDATA%\Genspark", "%LOCALAPPDATA%\Genspark")

Write-Log "-- STEP 2: Browser Cache and History (passwords SAFE) --"
Clear-ChromiumCache "Google Chrome"    "%LOCALAPPDATA%\Google\Chrome\User Data"
Clear-ChromiumCache "Microsoft Edge"   "%LOCALAPPDATA%\Microsoft\Edge\User Data"
Clear-ChromiumCache "Brave"            "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data"
Clear-ChromiumCache "Vivaldi"          "%LOCALAPPDATA%\Vivaldi\User Data"
Clear-ChromiumCache "Opera"            "%APPDATA%\Opera Software\Opera Stable"
Clear-ChromiumCache "Genspark Browser" "%LOCALAPPDATA%\Genspark\User Data"
Clear-ChromiumCache "Yandex Browser"   "%LOCALAPPDATA%\Yandex\YandexBrowser\User Data"

# Firefox
$ffProfiles = [System.Environment]::ExpandEnvironmentVariables("%APPDATA%\Mozilla\Firefox\Profiles")
if (Test-Path $ffProfiles) {
    $ffDirs  = @("cache2","startupCache","OfflineCache","thumbnails","storage")
    $ffFiles = @("cookies.sqlite","cookies.sqlite-shm","cookies.sqlite-wal",
                 "places.sqlite","places.sqlite-shm","places.sqlite-wal",
                 "formhistory.sqlite","formhistory.sqlite-shm","formhistory.sqlite-wal",
                 "downloads.sqlite","favicons.sqlite","favicons.sqlite-shm","favicons.sqlite-wal",
                 "webappsstore.sqlite","content-prefs.sqlite","permissions.sqlite",
                 "sessionstore.jsonlz4","sessionCheckpoints.json",
                 "previous.jsonlz4","recovery.jsonlz4","recovery.baklz4")
    Get-ChildItem $ffProfiles -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $p = $_.FullName
        foreach ($d in $ffDirs)  { if (Test-Path "$p\$d") { Remove-Item -Recurse -Force "$p\$d" -ErrorAction SilentlyContinue } }
        foreach ($f in $ffFiles) { if (Test-Path "$p\$f") { Remove-Item -Force "$p\$f" -ErrorAction SilentlyContinue } }
        # key4.db (passwords) intentionally SKIPPED
    }
    Write-Log "  [Firefox] cleared. (Passwords NOT touched)"
} else {
    Write-Log "  [Firefox] not installed, skipped."
}

Write-Log "-- STEP 3: Prefetch and Recent Files --"
# Prefetch
Get-ChildItem "C:\Windows\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Log "  [Prefetch] cleared."

# Recent Activity (shortcut list only - actual files untouched)
$recentPath  = [System.Environment]::ExpandEnvironmentVariables("%APPDATA%\Microsoft\Windows\Recent")
$historyPath = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Microsoft\Windows\History")
if (Test-Path $recentPath)  { Get-ChildItem $recentPath  -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path $historyPath) { Remove-Item -Recurse -Force $historyPath -ErrorAction SilentlyContinue }
Write-Log "  [Recent Items / History] cleared."

Write-Log "-- STEP 4: Temporary Files --"
# User Temp
$userTemp = [System.Environment]::ExpandEnvironmentVariables("%TEMP%")
if (Test-Path $userTemp) {
    Get-ChildItem $userTemp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "  [User Temp] cleared."
}
# Windows System Temp
if (Test-Path "C:\Windows\Temp") {
    Get-ChildItem "C:\Windows\Temp" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "  [Windows Temp] cleared."
}

Write-Log "-- STEP 5: Recycle Bin and Update Cache --"
# Recycle Bin
try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue; Write-Log "  [Recycle Bin] emptied." }
catch { Write-Log "  [Recycle Bin] could not empty: $($_.Exception.Message)" }

# Windows Update download cache (best-effort, skip if service won't stop quickly)
$wuStopped = $false
try {
    $svc = Get-Service -Name wuauserv -ErrorAction Stop
    if ($svc.Status -eq 'Running') {
        Stop-Service -Name wuauserv -Force -ErrorAction Stop
        $wuStopped = $true
    }
} catch { Write-Log "  [wuauserv] could not stop, skipping Update cache." }

if ($wuStopped -or (Get-Service wuauserv -ErrorAction SilentlyContinue).Status -ne 'Running') {
    $wuDownload = "C:\Windows\SoftwareDistribution\Download"
    if (Test-Path $wuDownload) {
        Get-ChildItem $wuDownload -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "  [Windows Update Download Cache] cleared."
    }
    $wuLogs = "C:\Windows\SoftwareDistribution\DataStore\Logs"
    if (Test-Path $wuLogs) {
        Get-ChildItem $wuLogs -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "  [Windows Update Logs] cleared."
    }
    if ($wuStopped) { Start-Service -Name wuauserv -ErrorAction SilentlyContinue }
}

# Thumbnail and icon cache
$explorerCache = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Microsoft\Windows\Explorer")
if (Test-Path $explorerCache) {
    Get-ChildItem $explorerCache -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem $explorerCache -Filter "iconcache_*.db"  -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Log "  [Thumbnail / Icon Cache] cleared."
}

# IE / WinINet cache
$inetCache = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Microsoft\Windows\INetCache")
if (Test-Path $inetCache) {
    Remove-Item -Recurse -Force $inetCache -ErrorAction SilentlyContinue
    Write-Log "  [INetCache] cleared."
}

Write-Log "-- STEP 6: Event Logs and DNS Cache --"
# Event Logs
foreach ($log in @("Application","System","Security","Setup")) {
    try { wevtutil cl $log 2>&1 | Out-Null; Write-Log "  [Event Log: $log] cleared." }
    catch { Write-Log "  [Event Log: $log] failed: $($_.Exception.Message)" }
}

# DNS Cache
try { Clear-DnsClientCache -ErrorAction Stop; Write-Log "  [DNS Cache] flushed." }
catch { ipconfig /flushdns | Out-Null; Write-Log "  [DNS Cache] flushed via ipconfig." }

# ════════════════════════════════════════════════════════════════════
Write-Log "===== Cleanup Finished ====="
# ════════════════════════════════════════════════════════════════════
