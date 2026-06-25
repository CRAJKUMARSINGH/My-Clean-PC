# My Clean PC - Windows Cache Cleaner (PowerShell)
# Designed for Priyanka
# Run with: PowerShell -ExecutionPolicy Bypass -File clean-pc-windows.ps1

$ErrorActionPreference = "SilentlyContinue"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  My Clean PC - Windows Cache Cleaner"       -ForegroundColor Cyan
Write-Host "  Designed for Priyanka"                     -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Passwords (Login Data) are NEVER touched." -ForegroundColor Yellow
Write-Host "  Downloads folder is NEVER touched."        -ForegroundColor Yellow
Write-Host ""

# ── Helper: remove a list of paths ────────────────────────────────────
function Remove-Paths {
  param([string]$Label, [string[]]$Paths)
  Write-Host "[$Label]" -ForegroundColor White
  foreach ($p in $Paths) {
    $exp = [System.Environment]::ExpandEnvironmentVariables($p)
    if (Test-Path $exp) {
      Remove-Item -Recurse -Force $exp
      Write-Host "  Cleared: $exp" -ForegroundColor Green
    }
  }
  Write-Host "  Done." -ForegroundColor DarkGray
}

# ── Helper: clear Chromium-based browser cache (NEVER Login Data) ─────
function Clear-ChromiumCache {
  param([string]$Label, [string]$UserDataPath)
  Write-Host "[$Label]" -ForegroundColor White
  $base = [System.Environment]::ExpandEnvironmentVariables($UserDataPath)
  if (-not (Test-Path $base)) { Write-Host "  Not installed." -ForegroundColor DarkGray; return }
  # iterate all profile folders (Default, Profile 1, Profile 2, ...)
  Get-ChildItem $base -Directory | ForEach-Object {
    $p = $_.FullName
    $dirs = @("Cache","Code Cache","GPUCache","Media Cache","blob_storage",
              "Service Worker\CacheStorage","Service Worker\ScriptCache",
              "Local Storage","IndexedDB","Session Storage",
              "Application Cache","Network","Extension State","Storage")
    foreach ($d in $dirs) { if (Test-Path "$p\$d") { Remove-Item -Recurse -Force "$p\$d" } }
    $files = @("Cookies","Cookies-journal","History","History-journal",
               "Visited Links","Top Sites","Top Sites-journal",
               "Shortcuts","Shortcuts-journal","Network Action Predictor",
               "Favicons","Favicons-journal",
               "Current Session","Last Session","Current Tabs","Last Tabs",
               "Download Service\EntryDB",
               "Web Data","Web Data-journal","Extension Cookies","QuotaManager")
    foreach ($f in $files) { if (Test-Path "$p\$f") { Remove-Item -Force "$p\$f" } }
    # Login Data and Login Data For Account are intentionally SKIPPED
  }
  Write-Host "  Done." -ForegroundColor DarkGray
}

# ════════════════════════════════════════════
Write-Host "" 
Write-Host "--- AI IDE App Caches ---" -ForegroundColor Cyan
Write-Host ""

Remove-Paths "1/9 Antigravity" @("%APPDATA%\Antigravity","%LOCALAPPDATA%\Antigravity")
Remove-Paths "2/9 Cursor"      @("%APPDATA%\Cursor\Cache","%APPDATA%\Cursor\CachedData","%APPDATA%\Cursor\logs","%LOCALAPPDATA%\cursor-updater")
Remove-Paths "3/9 Qoder"       @("%APPDATA%\Qoder","%LOCALAPPDATA%\Qoder")
Remove-Paths "4/9 Kiro"        @("%APPDATA%\kiro\Cache","%APPDATA%\kiro\CachedData","%LOCALAPPDATA%\kiro")
Remove-Paths "5/9 Trae AI"     @("%APPDATA%\Trae","%APPDATA%\trae-ai","%LOCALAPPDATA%\Trae")
Remove-Paths "6/9 Windsurf"    @("%APPDATA%\Windsurf\Cache","%APPDATA%\Windsurf\CachedData","%APPDATA%\Windsurf\logs","%LOCALAPPDATA%\Windsurf")
Remove-Paths "7/9 Devin"       @("%APPDATA%\Devin","%LOCALAPPDATA%\Devin")
Remove-Paths "8/9 Warp"        @("%APPDATA%\warp","%LOCALAPPDATA%\Warp\data")
Remove-Paths "9/9 Genspark (app)" @("%APPDATA%\Genspark","%LOCALAPPDATA%\Genspark")

# ════════════════════════════════════════════
Write-Host ""
Write-Host "--- Browser Cache + History (passwords kept safe) ---" -ForegroundColor Cyan
Write-Host ""

Clear-ChromiumCache "B1/8 Google Chrome"    "%LOCALAPPDATA%\Google\Chrome\User Data"
Clear-ChromiumCache "B2/8 Microsoft Edge"   "%LOCALAPPDATA%\Microsoft\Edge\User Data"
Clear-ChromiumCache "B3/8 Brave"            "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data"
Clear-ChromiumCache "B4/8 Vivaldi"          "%LOCALAPPDATA%\Vivaldi\User Data"
Clear-ChromiumCache "B5/8 Opera"            "%APPDATA%\Opera Software\Opera Stable"
Clear-ChromiumCache "B6/8 Genspark Browser" "%LOCALAPPDATA%\Genspark\User Data"
Clear-ChromiumCache "B7/8 Yandex Browser"   "%LOCALAPPDATA%\Yandex\YandexBrowser\User Data"

# ── Firefox ──────────────────────────────────────────────────────────
Write-Host "[B8/8 Firefox]" -ForegroundColor White
$ffProfiles = [System.Environment]::ExpandEnvironmentVariables("%APPDATA%\Mozilla\Firefox\Profiles")
if (Test-Path $ffProfiles) {
  Get-ChildItem $ffProfiles -Directory | ForEach-Object {
    $p = $_.FullName
    $dirs  = @("cache2","startupCache","OfflineCache","thumbnails","storage")
    $files = @("cookies.sqlite","cookies.sqlite-shm","cookies.sqlite-wal",
               "places.sqlite","places.sqlite-shm","places.sqlite-wal",
               "formhistory.sqlite","formhistory.sqlite-shm","formhistory.sqlite-wal",
               "downloads.sqlite",
               "favicons.sqlite","favicons.sqlite-shm","favicons.sqlite-wal",
               "webappsstore.sqlite","content-prefs.sqlite","permissions.sqlite",
               "sessionstore.jsonlz4","sessionCheckpoints.json",
               "previous.jsonlz4","recovery.jsonlz4","recovery.baklz4")
    foreach ($d in $dirs)  { if (Test-Path "$p\$d") { Remove-Item -Recurse -Force "$p\$d" } }
    foreach ($f in $files) { if (Test-Path "$p\$f") { Remove-Item -Force "$p\$f" } }
    # key4.db (saved passwords) intentionally SKIPPED
  }
  Write-Host "  Done." -ForegroundColor DarkGray
} else {
  Write-Host "  Not installed." -ForegroundColor DarkGray
}

# ════════════════════════════════════════════
Write-Host ""
Write-Host "--- Windows Prefetch ---" -ForegroundColor Cyan
Write-Host ""

Write-Host "[P1] Windows Prefetch (C:\Windows\Prefetch)..." -ForegroundColor White
Get-ChildItem "C:\Windows\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue |
  Remove-Item -Force -ErrorAction SilentlyContinue
Write-Host "  Done." -ForegroundColor DarkGray

Write-Host "[P2] User Prefetch / Recent Activity..." -ForegroundColor White
$recentPath  = [System.Environment]::ExpandEnvironmentVariables("%APPDATA%\Microsoft\Windows\Recent")
$historyPath = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Microsoft\Windows\History")
if (Test-Path $recentPath)  { Get-ChildItem $recentPath  | Remove-Item -Recurse -Force }
if (Test-Path $historyPath) { Remove-Item -Recurse -Force $historyPath }
Write-Host "  Done." -ForegroundColor DarkGray

# ════════════════════════════════════════════
Write-Host ""
Write-Host "--- Temp Files ---" -ForegroundColor Cyan
Write-Host ""

Write-Host "[T1] User Temp (%TEMP%)..." -ForegroundColor White
$userTemp = [System.Environment]::ExpandEnvironmentVariables("%TEMP%")
if (Test-Path $userTemp) {
  Get-ChildItem $userTemp -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "  Done." -ForegroundColor DarkGray

Write-Host "[T2] Windows Temp (C:\Windows\Temp)..." -ForegroundColor White
if (Test-Path "C:\Windows\Temp") {
  Get-ChildItem "C:\Windows\Temp" -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "  Done." -ForegroundColor DarkGray

# ════════════════════════════════════════════
Write-Host ""
Write-Host "--- Recycle Bin ---" -ForegroundColor Cyan
Write-Host ""

Write-Host "[R1] Emptying Recycle Bin..." -ForegroundColor White
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "  Done." -ForegroundColor DarkGray

# ════════════════════════════════════════════
Write-Host ""
Write-Host "--- Windows Update Cache ---" -ForegroundColor Cyan
Write-Host ""

Write-Host "[W1] SoftwareDistributionDownload..." -ForegroundColor White
$wuDownload = "C:WindowsSoftwareDistributionDownload"
if (Test-Path $wuDownload) {
  Get-ChildItem $wuDownload -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "  Done." -ForegroundColor DarkGray

Write-Host "[W2] Windows Update logs..." -ForegroundColor White
$wuLogs = "C:WindowsSoftwareDistributionDataStoreLogs"
if (Test-Path $wuLogs) {
  Get-ChildItem $wuLogs -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "  Done." -ForegroundColor DarkGray

# ════════════════════════════════════════════
Write-Host ""
Write-Host "--- Thumbnail Cache ---" -ForegroundColor Cyan
Write-Host ""

Write-Host "[N1] Explorer thumbnail + icon cache..." -ForegroundColor White
$explorerCache = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%MicrosoftWindowsExplorer")
if (Test-Path $explorerCache) {
  Get-ChildItem $explorerCache -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
  Get-ChildItem $explorerCache -Filter "iconcache_*.db"  -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}
Write-Host "  Done." -ForegroundColor DarkGray

# ════════════════════════════════════════════
Write-Host ""
Write-Host "--- Windows Event Logs ---" -ForegroundColor Cyan
Write-Host ""

Write-Host "[E1] Application log..." -ForegroundColor White
wevtutil cl Application 2>$null
Write-Host "  Done." -ForegroundColor DarkGray

Write-Host "[E2] System log..." -ForegroundColor White
wevtutil cl System 2>$null
Write-Host "  Done." -ForegroundColor DarkGray

Write-Host "[E3] Security log..." -ForegroundColor White
wevtutil cl Security 2>$null
Write-Host "  Done." -ForegroundColor DarkGray

Write-Host "[E4] Setup log..." -ForegroundColor White
wevtutil cl Setup 2>$null
Write-Host "  Done." -ForegroundColor DarkGray

# ════════════════════════════════════════════
Write-Host ""
Write-Host "--- DNS Cache ---" -ForegroundColor Cyan
Write-Host ""

Write-Host "[D1] Flushing DNS cache..." -ForegroundColor White
ipconfig /flushdns | Out-Null
Write-Host "  Done." -ForegroundColor DarkGray

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  All done!"                                 -ForegroundColor Green
Write-Host "  Passwords (Login Data) were NOT touched."  -ForegroundColor Green
Write-Host "  Downloads folder was NOT touched."         -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Read-Host "Press Enter to exit"
