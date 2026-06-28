# My Clean PC - shared cleaning core (single source of truth)
# Dot-source from my-clean-pc.ps1, cleanup_task.ps1, etc.
# Passwords (Login Data, key4.db) and Downloads are NEVER touched.

$ErrorActionPreference = "SilentlyContinue"
$ConfirmPreference = "None"
$ProgressPreference = "SilentlyContinue"

# Paths never deleted (passwords, Downloads, self-install folder)
$script:SkipPathFragments = @("\Login Data", "\Login Data For Account", "\key4.db", "\Downloads", "\MyCleanPC\")

$script:JunkDirNames = @(
    "Cache", "Caches", "CachedData", "Code Cache", "GPUCache", "Media Cache",
    "Temp", "Tmp", "tmp", "Logs", "Log", "crashpad", "CrashDumps", "blob_storage",
    "startupCache", "OfflineCache", "Application Cache", "INetCache", "WebCache",
    "Updater", "updater", "D3DSCache", "storage", "Crash Reports"
)

function Test-SkipCleanPath {
    param([string]$Path)
    foreach ($frag in $script:SkipPathFragments) {
        if ($Path -like "*$frag*") { return $true }
    }
    return $false
}

function Clear-SafeDirectoryContents {
    param([string]$LiteralPath)
    if (Test-SkipCleanPath $LiteralPath) { return }
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Container)) { return }
    foreach ($child in @(Get-ChildItem -LiteralPath $LiteralPath -Force -ErrorAction SilentlyContinue)) {
        if (Test-SkipCleanPath $child.FullName) { continue }
        try { $child.Attributes = 'Normal' } catch {}
        if ($child.PSIsContainer) {
            Clear-SafeDirectoryContents -LiteralPath $child.FullName
            Remove-Item -LiteralPath $child.FullName -Force -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        } else {
            Remove-Item -LiteralPath $child.FullName -Force -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        }
    }
}

# Delete path if safe; skip protected paths and locked/in-use files - never prompts user
function Remove-SafePath {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [switch]$Recurse
    )
    if (Test-SkipCleanPath $LiteralPath) { return $false }
    if (-not (Test-Path -LiteralPath $LiteralPath)) { return $false }
    try {
        $item = Get-Item -LiteralPath $LiteralPath -Force -ErrorAction Stop
        $item.Attributes = 'Normal'
    } catch { return $false }
    if ($Recurse -and (Test-Path -LiteralPath $LiteralPath -PathType Container)) {
        Clear-SafeDirectoryContents -LiteralPath $LiteralPath
        Remove-Item -LiteralPath $LiteralPath -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    } else {
        Remove-Item -LiteralPath $LiteralPath -Force -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    }
    return -not (Test-Path -LiteralPath $LiteralPath)
}

function Clear-SafeTempTree {
    param([string]$RootPath)
    $root = [System.Environment]::ExpandEnvironmentVariables($RootPath)
    if (-not (Test-Path $root)) { return }
    foreach ($child in @(Get-ChildItem $root -Force -ErrorAction SilentlyContinue)) {
        Remove-SafePath -LiteralPath $child.FullName -Recurse | Out-Null
    }
}

function Test-JunkDirName {
    param([string]$Name)
    foreach ($jn in $script:JunkDirNames) {
        if ($Name -ieq $jn) { return $true }
    }
    return $false
}

function Clear-RecycleBinSilent {
    if (-not ('RecycleBinNative' -as [type])) {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class RecycleBinNative {
    [DllImport("Shell32.dll", CharSet = CharSet.Unicode)]
    public static extern int SHEmptyRecycleBin(IntPtr hwnd, string pszRootPath, uint dwFlags);
    public const uint SHERB_NOCONFIRMATION = 0x00000001;
    public const uint SHERB_NOPROGRESSUI   = 0x00000002;
    public const uint SHERB_NOSOUND        = 0x00000004;
}
"@
    }
    $flags = [RecycleBinNative]::SHERB_NOCONFIRMATION -bor `
        [RecycleBinNative]::SHERB_NOPROGRESSUI -bor `
        [RecycleBinNative]::SHERB_NOSOUND
    [RecycleBinNative]::SHEmptyRecycleBin([IntPtr]::Zero, $null, $flags) | Out-Null
}

function Clear-RigorousTempLocations {
    param([scriptblock]$OnItem = { param($Path) })
    $fixed = @(
        "%TEMP%", "%LOCALAPPDATA%\Temp", "C:\Windows\Temp",
        "%LOCALAPPDATA%\CrashDumps", "%LOCALAPPDATA%\D3DSCache",
        "%LOCALAPPDATA%\Microsoft\Windows\WebCache",
        "%LOCALAPPDATA%\Microsoft\Windows\Burn\Burn"
    )
    foreach ($raw in $fixed) {
        $p = [System.Environment]::ExpandEnvironmentVariables($raw)
        if (Test-Path $p) {
            Clear-SafeTempTree $p
            & $OnItem $p
        }
    }
    $local = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%")
    Get-ChildItem $local -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        foreach ($n in @("Temp", "temp", "tmp", "Tmp")) {
            $tp = Join-Path $_.FullName $n
            if (Test-Path $tp) {
                Remove-SafePath -LiteralPath $tp -Recurse | Out-Null
                & $OnItem $tp
            }
        }
    }
}

function Clear-AppDataJunkSweep {
    param(
        [string]$RootVar,
        [scriptblock]$OnBatch = { param($Count) }
    )
    $root = [System.Environment]::ExpandEnvironmentVariables($RootVar)
    if (-not (Test-Path $root)) { return 0 }
    $cleared = 0
    Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $stack = New-Object System.Collections.Stack
        $stack.Push(@{ Path = $_.FullName; Depth = 0 })
        while ($stack.Count -gt 0) {
            $cur = $stack.Pop()
            Get-ChildItem $cur.Path -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $child = $_.FullName
                if (Test-SkipCleanPath $child) { return }
                if (Test-JunkDirName $_.Name) {
                    if (Remove-SafePath -LiteralPath $child -Recurse) { $cleared++ }
                } elseif ($cur.Depth -lt 3) {
                    $stack.Push(@{ Path = $child; Depth = $cur.Depth + 1 })
                }
            }
        }
    }
    & $OnBatch $cleared
    return $cleared
}

function Remove-CleanPaths {
    param([string[]]$Paths)
    foreach ($p in $Paths) {
        $exp = [System.Environment]::ExpandEnvironmentVariables($p)
        Remove-SafePath -LiteralPath $exp -Recurse | Out-Null
    }
}

# Non-browser apps that also use Chromium "Local State" - never treat as browser
$script:BrowserDiscoveryExcludes = @(
    '\Cursor\', '\discord\', '\Discord\', '\Slack\', '\Teams\', '\Postman\',
    '\GitHub Desktop\', '\Notion\', '\Obsidian\', '\Spotify\', '\Zoom\',
    '\Antigravity\', '\Windsurf\', '\Qoder\', '\kiro\', '\Trae\', '\Devin\',
    '\electron\', '\Microsoft\Teams\', '\Code\'
)

function Test-BrowserDiscoveryExcluded {
    param([string]$Path)
    foreach ($frag in $script:BrowserDiscoveryExcludes) {
        if ($Path -like "*$frag*") { return $true }
    }
    return $false
}

function Test-ChromiumUserDataRoot {
    param([string]$Path)
    if (Test-BrowserDiscoveryExcluded $Path) { return $false }
    if (-not (Test-Path -LiteralPath (Join-Path $Path 'Local State'))) { return $false }
    foreach ($child in @(Get-ChildItem -LiteralPath $Path -Directory -ErrorAction SilentlyContinue)) {
        if ($child.Name -eq 'Default' -or $child.Name -like 'Profile *' -or $child.Name -eq 'Guest Profile') {
            return $true
        }
    }
    return $false
}

function Find-ChromiumBrowserRoots {
    $found = @{}
    $bases = @(
        [System.Environment]::ExpandEnvironmentVariables('%LOCALAPPDATA%'),
        [System.Environment]::ExpandEnvironmentVariables('%APPDATA%')
    )
    foreach ($base in $bases) {
        if (-not (Test-Path $base)) { continue }
        foreach ($localState in @(Get-ChildItem -Path $base -Filter 'Local State' -File -Recurse -Depth 6 -ErrorAction SilentlyContinue)) {
            $root = $localState.Directory.FullName
            if (Test-BrowserDiscoveryExcluded $root) { continue }
            if (-not (Test-ChromiumUserDataRoot $root)) { continue }
            $key = $root.ToLowerInvariant()
            if (-not $found.ContainsKey($key)) { $found[$key] = $root }
        }
    }
    return @($found.Values | Sort-Object)
}

function Find-GeckoBrowserProfileDirs {
    $found = @{}
    $appData = [System.Environment]::ExpandEnvironmentVariables('%APPDATA%')
    if (-not (Test-Path $appData)) { return @() }
    foreach ($ini in @(Get-ChildItem $appData -Filter 'profiles.ini' -File -Recurse -Depth 5 -ErrorAction SilentlyContinue)) {
        $browserRoot = $ini.Directory.FullName
        if (Test-BrowserDiscoveryExcluded $browserRoot) { continue }
        $profilesDir = Join-Path $browserRoot 'Profiles'
        if (-not (Test-Path $profilesDir)) { continue }
        $key = $profilesDir.ToLowerInvariant()
        if ($found.ContainsKey($key)) { continue }
        $leaf = Split-Path $browserRoot -Leaf
        $parent = Split-Path (Split-Path $browserRoot -Parent) -Leaf
        $vendorName = if ($parent -and $parent -ne $leaf -and $parent -ne 'Roaming') { "$parent\$leaf" } else { $leaf }
        $found[$key] = @{ Name = $vendorName; Path = $profilesDir }
    }
    return @($found.Values)
}

function Get-BrowserLabelFromPath {
    param([string]$Path)
    $rules = @(
        @{ Match = 'Google\Chrome'; Label = 'Google Chrome' }
        @{ Match = 'Microsoft\Edge'; Label = 'Microsoft Edge' }
        @{ Match = 'BraveSoftware'; Label = 'Brave' }
        @{ Match = 'Vivaldi'; Label = 'Vivaldi' }
        @{ Match = 'Opera Software'; Label = 'Opera' }
        @{ Match = 'Yandex'; Label = 'Yandex Browser' }
        @{ Match = 'Chromium'; Label = 'Chromium' }
        @{ Match = 'Arc'; Label = 'Arc Browser' }
        @{ Match = 'Wavebox'; Label = 'Wavebox' }
        @{ Match = 'Sidekick'; Label = 'Sidekick' }
        @{ Match = 'CentBrowser'; Label = 'Cent Browser' }
        @{ Match = 'CocCoc'; Label = 'Coc Coc Browser' }
        @{ Match = 'UCBrowser'; Label = 'UC Browser' }
        @{ Match = 'Epic Privacy Browser'; Label = 'Epic Browser' }
        @{ Match = 'Genspark'; Label = 'Genspark Browser' }
    )
    foreach ($rule in $rules) {
        if ($Path -like "*$($rule.Match)*") { return $rule.Label }
    }
    if ($Path -match '\\User Data$') {
        $browserDir = Split-Path (Split-Path $Path -Parent) -Leaf
        $vendorDir = Split-Path (Split-Path (Split-Path $Path -Parent) -Parent) -Leaf
        if ($vendorDir -and $browserDir -and $vendorDir -ne $browserDir) {
            return "$vendorDir $browserDir".Trim()
        }
        return $browserDir
    }
    return (Split-Path $Path -Leaf)
}

function Get-GeckoBrowserLabel {
    param([string]$VendorName)
    switch -Regex ($VendorName) {
        'Firefox' { return 'Firefox' }
        'Waterfox' { return 'Waterfox' }
        'Pale Moon' { return 'Pale Moon' }
        'LibreWolf' { return 'LibreWolf' }
        'Tor Browser' { return 'Tor Browser' }
        'Basilisk' { return 'Basilisk' }
        'Thunderbird' { return 'Thunderbird' }
        default { return ($VendorName -replace '\\', ' ') }
    }
}

$script:ChromiumCleanDirs = @(
    "Cache", "Code Cache", "GPUCache", "Media Cache", "blob_storage",
    "Service Worker\CacheStorage", "Service Worker\ScriptCache",
    "Local Storage", "IndexedDB", "Session Storage", "Application Cache",
    "Network", "Extension State", "Storage", "DawnCache", "GrShaderCache",
    "ShaderCache", "Shared Dictionary", "optimization_guide_hint_cache_store"
)
$script:ChromiumCleanFiles = @(
    "Cookies", "Cookies-journal", "History", "History-journal",
    "Visited Links", "Top Sites", "Top Sites-journal",
    "Shortcuts", "Shortcuts-journal", "Network Action Predictor",
    "Favicons", "Favicons-journal", "Current Session", "Last Session",
    "Current Tabs", "Last Tabs", "Web Data", "Web Data-journal",
    "Extension Cookies", "QuotaManager", "Reporting and NEL", "Reporting and NEL-journal"
)
$script:GeckoCleanDirs = @("cache2", "startupCache", "OfflineCache", "thumbnails", "storage", "jumpListCache")
$script:GeckoCleanFiles = @(
    "cookies.sqlite", "cookies.sqlite-shm", "cookies.sqlite-wal",
    "places.sqlite", "places.sqlite-shm", "places.sqlite-wal",
    "formhistory.sqlite", "formhistory.sqlite-shm", "formhistory.sqlite-wal",
    "downloads.sqlite", "favicons.sqlite", "favicons.sqlite-shm", "favicons.sqlite-wal",
    "webappsstore.sqlite", "content-prefs.sqlite", "permissions.sqlite",
    "sessionstore.jsonlz4", "sessionCheckpoints.json",
    "previous.jsonlz4", "recovery.jsonlz4", "recovery.baklz4"
)

function Clear-ChromiumBrowserCache {
    param([string]$UserDataPath)
    $base = [System.Environment]::ExpandEnvironmentVariables($UserDataPath)
    if (-not (Test-Path $base)) { return }

    Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $profile = $_.FullName
        foreach ($d in $script:ChromiumCleanDirs) {
            Remove-SafePath -LiteralPath (Join-Path $profile $d) -Recurse | Out-Null
        }
        foreach ($f in $script:ChromiumCleanFiles) {
            Remove-SafePath -LiteralPath (Join-Path $profile $f) | Out-Null
        }
        # Login Data + Login Data For Account intentionally SKIPPED (passwords safe)
    }
}

function Clear-GeckoBrowserProfiles {
    param([string]$ProfilesPath)
    if (-not (Test-Path $ProfilesPath)) { return }
    Get-ChildItem $ProfilesPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $p = $_.FullName
        foreach ($d in $script:GeckoCleanDirs) {
            Remove-SafePath -LiteralPath (Join-Path $p $d) -Recurse | Out-Null
        }
        foreach ($f in $script:GeckoCleanFiles) {
            Remove-SafePath -LiteralPath (Join-Path $p $f) | Out-Null
        }
        # key4.db (saved passwords) intentionally SKIPPED
    }
}

function Clear-FirefoxProfiles {
    Clear-GeckoBrowserProfiles ([System.Environment]::ExpandEnvironmentVariables("%APPDATA%\Mozilla\Firefox\Profiles"))
}

function Clear-AllInstalledBrowsers {
    param([scriptblock]$Log = { param([string]$Message) })

    & $Log "  Scanning PC for all installed browsers..."
    $chromiumRoots = Find-ChromiumBrowserRoots
    $geckoBrowsers = Find-GeckoBrowserProfileDirs
    $count = $chromiumRoots.Count + $geckoBrowsers.Count

    if ($count -eq 0) {
        & $Log "  No browser profile folders found on this PC."
        return @{ Chromium = 0; Gecko = 0; Total = 0 }
    }

    & $Log "  Found $count browser profile location(s)."
    & $Log "  Cleaning: cache, cookies, history, sessions (like Ctrl+Shift+Delete)."
    & $Log "  Auto-skip: passwords, locked files - no prompts."

    foreach ($root in $chromiumRoots) {
        $label = Get-BrowserLabelFromPath $root
        & $Log "  -> $label"
        Clear-ChromiumBrowserCache $root
    }
    foreach ($g in $geckoBrowsers) {
        $label = Get-GeckoBrowserLabel $g.Name
        & $Log "  -> $label"
        Clear-GeckoBrowserProfiles $g.Path
    }

    & $Log "  [All Browsers] cleared. Passwords NOT touched."
    return @{ Chromium = $chromiumRoots.Count; Gecko = $geckoBrowsers.Count; Total = $count }
}

function Clear-StoreAppTemp {
    $pkgs = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Packages")
    if (-not (Test-Path $pkgs)) { return }
    Get-ChildItem $pkgs -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $at = Join-Path $_.FullName "AC\Temp"
        $cn = Join-Path $_.FullName "AC\Microsoft\CryptnetUrlCache"
        if (Test-Path $at) { Remove-SafePath -LiteralPath $at -Recurse | Out-Null }
        if (Test-Path $cn) { Remove-SafePath -LiteralPath $cn -Recurse | Out-Null }
    }
}

function Invoke-MyCleanPCCore {
    param(
        [scriptblock]$Log = { param([string]$Message) Write-Host $Message },
        [switch]$ManageWindowsUpdateService
    )

    & $Log "-- STEP 1: AI App Caches --"
    Remove-CleanPaths @(
        "%APPDATA%\Antigravity", "%LOCALAPPDATA%\Antigravity",
        "%APPDATA%\Cursor\Cache", "%APPDATA%\Cursor\CachedData", "%APPDATA%\Cursor\logs", "%LOCALAPPDATA%\cursor-updater",
        "%APPDATA%\Qoder", "%LOCALAPPDATA%\Qoder",
        "%APPDATA%\kiro\Cache", "%APPDATA%\kiro\CachedData", "%LOCALAPPDATA%\kiro",
        "%APPDATA%\Trae", "%APPDATA%\trae-ai", "%LOCALAPPDATA%\Trae",
        "%APPDATA%\Windsurf\Cache", "%APPDATA%\Windsurf\CachedData", "%APPDATA%\Windsurf\logs", "%LOCALAPPDATA%\Windsurf",
        "%APPDATA%\Devin", "%LOCALAPPDATA%\Devin",
        "%APPDATA%\warp", "%LOCALAPPDATA%\Warp\data",
        "%APPDATA%\Genspark", "%LOCALAPPDATA%\Genspark"
    )
    & $Log "  [AI App Caches] cleared."

    & $Log "-- STEP 2: All Installed Browsers (auto-detect, passwords SAFE) --"
    Clear-AllInstalledBrowsers -Log $Log | Out-Null

    & $Log "-- STEP 3: Prefetch and Recent Files --"
    foreach ($pf in @(Get-ChildItem "C:\Windows\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue)) {
        Remove-SafePath -LiteralPath $pf.FullName | Out-Null
    }
    $recentPath = [System.Environment]::ExpandEnvironmentVariables("%APPDATA%\Microsoft\Windows\Recent")
    $historyPath = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Microsoft\Windows\History")
    if (Test-Path $recentPath) { Clear-SafeTempTree $recentPath }
    Remove-SafePath -LiteralPath $historyPath -Recurse | Out-Null
    & $Log "  [Prefetch / Recent] cleared."

    & $Log "-- STEP 4: Temporary Files + Rigorous AppData --"
    & $Log "  (Busy/locked files auto-skip - no prompts)"
    Clear-SafeTempTree "%TEMP%"
    Clear-SafeTempTree "C:\Windows\Temp"
    Clear-RigorousTempLocations
    $localCount = Clear-AppDataJunkSweep "%LOCALAPPDATA%"
    $roamCount = Clear-AppDataJunkSweep "%APPDATA%"
    & $Log "  [Rigorous Temp + AppData] cleared ($localCount local + $roamCount roaming junk folders)."

    & $Log "-- STEP 5: Recycle Bin and Update Cache --"
    try { Clear-RecycleBinSilent } catch {}
    & $Log "  [Recycle Bin] emptied."

    $wuStopped = $false
    if ($ManageWindowsUpdateService) {
        try {
            $svc = Get-Service -Name wuauserv -ErrorAction Stop
            if ($svc.Status -eq "Running") {
                Stop-Service -Name wuauserv -Force -ErrorAction Stop
                $wuStopped = $true
            }
        } catch {
            & $Log "  [Windows Update cache] skipped (service could not stop)."
        }
    }

    if (-not $ManageWindowsUpdateService -or $wuStopped -or (Get-Service wuauserv -ErrorAction SilentlyContinue).Status -ne "Running") {
        $wuDownload = "C:\Windows\SoftwareDistribution\Download"
        if (Test-Path $wuDownload) { Clear-SafeTempTree $wuDownload }
        $wuLogs = "C:\Windows\SoftwareDistribution\DataStore\Logs"
        if (Test-Path $wuLogs) { Clear-SafeTempTree $wuLogs }
        & $Log "  [Windows Update cache] cleared."
        if ($wuStopped) { Start-Service -Name wuauserv -ErrorAction SilentlyContinue }
    }

    Clear-StoreAppTemp
    & $Log "  [Store app temp] cleared."

    $inetCache = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Microsoft\Windows\INetCache")
    Remove-SafePath -LiteralPath $inetCache -Recurse | Out-Null
    & $Log "  [INetCache] cleared."

    $explorerCache = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Microsoft\Windows\Explorer")
    if (Test-Path $explorerCache) {
        foreach ($thumb in @(Get-ChildItem $explorerCache -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue)) {
            Remove-SafePath -LiteralPath $thumb.FullName | Out-Null
        }
        foreach ($icon in @(Get-ChildItem $explorerCache -Filter "iconcache_*.db" -ErrorAction SilentlyContinue)) {
            Remove-SafePath -LiteralPath $icon.FullName | Out-Null
        }
    }
    & $Log "  [Thumbnail / Icon cache] cleared."

    & $Log "-- STEP 6: Event Logs and DNS Cache --"
    foreach ($logName in @("Application", "System", "Security", "Setup")) {
        try { wevtutil cl $logName 2>&1 | Out-Null } catch {}
        & $Log "  [Event Log: $logName] cleared."
    }
    try { Clear-DnsClientCache -ErrorAction Stop } catch { ipconfig /flushdns | Out-Null }
    & $Log "  [DNS Cache] flushed."
}
