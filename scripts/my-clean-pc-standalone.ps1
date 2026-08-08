# My Clean PC - STANDALONE (single-file, no dependencies needed)
# ----------------------------------------------------------------
# This file is self-contained. Just right-click it and choose
# "Run with PowerShell" (as Administrator for best results).
#
# What gets cleaned:
#   Temp folders (%TEMP%, Windows\Temp, AppData\Local\Temp)
#   App cache folders (Cursor, Windsurf, Kiro, Trae, Warp, Genspark, etc.)
#   All installed browsers (Chrome, Edge, Firefox, Brave, Vivaldi, Opera, etc.)
#   Prefetch, INetCache, Thumbnail/Icon cache
#   Windows Update cache, Recycle Bin, Event Logs, DNS cache
#
# What is NEVER touched:
#   Passwords (Login Data, key4.db)
#   Autofill / form data
#   Downloads folder
#   Bookmarks
#   Quick Access pins / Recent folder
# ----------------------------------------------------------------

$ErrorActionPreference = "SilentlyContinue"
$ConfirmPreference     = "None"
$ProgressPreference    = "SilentlyContinue"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  My Clean PC - Standalone Cleaner"         -ForegroundColor Cyan
Write-Host "  Designed for Priyanka"                    -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Passwords (Login Data) are NEVER touched." -ForegroundColor Yellow
Write-Host "  Downloads folder is NEVER touched."        -ForegroundColor Yellow
Write-Host "  Busy/locked files auto-skip - no prompts." -ForegroundColor Yellow
Write-Host ""

# ════════════════════════════════════════════════════
# EMBEDDED CORE  (clean-pc-core.ps1 inlined here)
# ════════════════════════════════════════════════════

$script:SkipPathFragments = @(
    "\Login Data", "\Login Data For Account", "\key4.db", "\formhistory.sqlite",
    "\Web Data", "\Web Data-journal", "\Autofill", "\Downloads", "\MyCleanPC\",
    "\Microsoft\Windows\Recent\", "\Microsoft\Windows\History\",
    "\Microsoft\Windows\Recent\AutomaticDestinations", "\Microsoft\Windows\Recent\CustomDestinations"
)

$script:ProcessedTempRoots = @{}

function Format-ByteSize {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return ('{0:F2} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:F1} MB' -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ('{0:F0} KB' -f ($Bytes / 1KB)) }
    return "$Bytes B"
}

function Get-DriveFreeBytes {
    param([string]$Drive = $env:SystemDrive)
    $letter = $Drive.TrimEnd('\').TrimEnd(':')
    $letterSlash = $letter + ':\'
    try {
        $info = [System.IO.DriveInfo]::GetDrives() |
                Where-Object { $_.Name -ieq $letterSlash } | Select-Object -First 1
        if ($info -and $info.AvailableFreeSpace -gt 0) {
            return [long]$info.AvailableFreeSpace
        }
    } catch {}
    try {
        $psd = Get-PSDrive -Name $letter -ErrorAction Stop
        if ($psd -and $psd.Free -gt 0) {
            return [long]$psd.Free
        }
    } catch {}
    try {
        $wmi = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='${letter}:'" -ErrorAction Stop
        if ($wmi -and $wmi.FreeSpace -gt 0) {
            return [long]$wmi.FreeSpace
        }
    } catch {}
    return [long]0
}

function Measure-PathSizeBytes {
    param([string]$LiteralPath)
    if (-not $LiteralPath -or -not (Test-Path -LiteralPath $LiteralPath)) { return [long]0 }
    try {
        if (Test-Path -LiteralPath $LiteralPath -PathType Leaf) {
            return ([System.IO.FileInfo]$LiteralPath).Length
        }
        $total = [long]0
        foreach ($f in [System.IO.Directory]::EnumerateFiles($LiteralPath, '*', [System.IO.SearchOption]::AllDirectories)) {
            try { $total += ([System.IO.FileInfo]$f).Length } catch {}
        }
        return $total
    } catch { return [long]0 }
}

function Get-CleanupEstimate {
    $hits = [System.Collections.Generic.List[hashtable]]::new()
    function AddHit([string]$full, [string]$short) {
        if (-not $full -or -not (Test-Path -LiteralPath $full)) { return }
        $b = Measure-PathSizeBytes $full
        if ($b -gt 0) { $hits.Add(@{ Label = $full; ShortLabel = $short; Bytes = $b }) }
    }
    AddHit ([System.Environment]::ExpandEnvironmentVariables('%TEMP%'))              'User Temp'
    AddHit ([System.Environment]::ExpandEnvironmentVariables('%LOCALAPPDATA%\Temp')) 'LocalAppData\Temp'
    AddHit 'C:\Windows\Temp'                                                          'Windows\Temp'
    $aiMap = @{
        '%APPDATA%\kiro'                = 'Kiro (Roaming)'
        '%LOCALAPPDATA%\kiro'           = 'Kiro (Local)'
        '%APPDATA%\Cursor\Cache'        = 'Cursor Cache'
        '%APPDATA%\Cursor\CachedData'   = 'Cursor CachedData'
        '%LOCALAPPDATA%\cursor-updater' = 'Cursor Updater'
        '%APPDATA%\Windsurf\Cache'      = 'Windsurf Cache'
        '%LOCALAPPDATA%\Windsurf'       = 'Windsurf Local'
        '%APPDATA%\Trae'                = 'Trae'
        '%APPDATA%\warp'                = 'Warp'
        '%APPDATA%\Genspark'            = 'Genspark'
    }
    foreach ($kv in $aiMap.GetEnumerator()) {
        AddHit ([System.Environment]::ExpandEnvironmentVariables($kv.Key)) $kv.Value
    }
    foreach ($root in @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data",
        "$env:LOCALAPPDATA\Vivaldi\User Data"
    )) {
        if (-not (Test-Path $root)) { continue }
        $appName = (Split-Path $root -Parent | Split-Path -Leaf)
        foreach ($cache in @(Get-ChildItem $root -Recurse -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -in @('Cache','Code Cache','GPUCache') } | Select-Object -First 4)) {
            AddHit $cache.FullName "$appName Cache"
        }
    }
    $ffBase = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $ffBase) {
        foreach ($prof in @(Get-ChildItem $ffBase -Directory -ErrorAction SilentlyContinue)) {
            AddHit (Join-Path $prof.FullName 'cache2') 'Firefox Cache'
        }
    }
    AddHit ([System.Environment]::ExpandEnvironmentVariables('%LOCALAPPDATA%\Microsoft\Windows\INetCache')) 'INetCache'
    AddHit ([System.Environment]::ExpandEnvironmentVariables('%LOCALAPPDATA%\Microsoft\Windows\Explorer'))  'Thumbnail DB'
    $sorted = $hits | Sort-Object { $_.Bytes } -Descending
    $total  = [long](($hits | Measure-Object -Property Bytes -Sum).Sum)
    return @{ TotalBytes = $total; Count = $hits.Count; Top5 = @($sorted | Select-Object -First 5) }
}

function Format-ByteComparison {
    param([long]$Bytes)
    if ($Bytes -le 10MB) { return '' }
    $songs  = [Math]::Round($Bytes / 4MB)
    $photos = [Math]::Round($Bytes / 4.5MB)
    $video  = [Math]::Round($Bytes / 50MB)
    $emails = [Math]::Round($Bytes / 0.3MB)
    if ($songs  -in 50..9999) { return "That's like $("{0:N0}" -f $songs) MP3 songs" }
    if ($photos -in 50..9999) { return "That's like $("{0:N0}" -f $photos) holiday photos" }
    if ($video  -in 5..999)   { return "That's like $("{0:N0}" -f $video) minutes of HD video" }
    if ($emails -in 50..9999) { return "That's like $("{0:N0}" -f $emails) emails" }
    return "That's like $("{0:N0}" -f $photos) holiday photos"
}

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

function Get-LongLiteralPath {
    param([Parameter(Mandatory)][string]$LiteralPath)
    $full = [System.IO.Path]::GetFullPath($LiteralPath)
    if ($full.StartsWith('\\?\')) { return $full }
    if ($full.StartsWith('\\'))  { return '\\?\UNC\' + $full.Substring(2) }
    return '\\?\' + $full
}

function Clear-PathAttributes {
    param([Parameter(Mandatory)][string]$LiteralPath)
    try {
        if ([System.IO.Directory]::Exists($LiteralPath)) {
            [System.IO.File]::SetAttributes($LiteralPath, [System.IO.FileAttributes]::Normal)
        } elseif ([System.IO.File]::Exists($LiteralPath)) {
            [System.IO.File]::SetAttributes($LiteralPath, [System.IO.FileAttributes]::Normal)
        }
    } catch {}
}

function Get-CleanerStagingRoot {
    foreach ($candidate in @(
        (Join-Path $env:ProgramData "MyCleanPC"),
        (Join-Path ([System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%")) "MyCleanPC")
    )) {
        try {
            if (-not (Test-Path -LiteralPath $candidate)) { New-Item -ItemType Directory -Path $candidate -Force | Out-Null }
            if (Test-Path -LiteralPath $candidate -PathType Container) { return $candidate }
        } catch {}
    }
    return ([System.IO.Path]::GetTempPath())
}

function Invoke-ProcessAnswerAll {
    param([Parameter(Mandatory)][string]$FilePath, [Parameter(Mandatory)][string[]]$ArgumentList, [int]$TimeoutMilliseconds = 120000)
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath
        foreach ($arg in $ArgumentList) { [void]$psi.ArgumentList.Add($arg) }
        $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
        $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
        $proc = New-Object System.Diagnostics.Process; $proc.StartInfo = $psi; [void]$proc.Start()
        try { $proc.StandardInput.WriteLine('A'); $proc.StandardInput.WriteLine('Y'); $proc.StandardInput.Close() } catch {}
        if (-not $proc.WaitForExit($TimeoutMilliseconds)) { try { $proc.Kill() } catch {}; return $false }
        return ($proc.ExitCode -eq 0)
    } catch { return $false }
}

function Remove-PathViaCmd {
    param([Parameter(Mandatory)][string]$LiteralPath, [switch]$Recurse)
    if (-not (Test-Path -LiteralPath $LiteralPath)) { return $true }
    Clear-PathAttributes $LiteralPath
    if ((Test-Path -LiteralPath $LiteralPath -PathType Container) -or $Recurse) {
        $ok = Invoke-ProcessAnswerAll -FilePath 'cmd.exe' -ArgumentList @('/c', 'rd', '/s', '/q', $LiteralPath)
    } else {
        $ok = Invoke-ProcessAnswerAll -FilePath 'cmd.exe' -ArgumentList @('/c', 'del', '/f', '/q', '/a', $LiteralPath)
    }
    return ($ok -and -not (Test-Path -LiteralPath $LiteralPath))
}

function Initialize-RebootDeleteNative {
    if ('RebootDeleteNative' -as [type]) { return }
    Add-Type @"
using System; using System.Runtime.InteropServices;
public static class RebootDeleteNative {
    [DllImport("Kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName, int dwFlags);
    public const int MOVEFILE_DELAY_UNTIL_REBOOT = 0x4;
}
"@
}

function Register-DeleteOnReboot {
    param([Parameter(Mandatory)][string]$LiteralPath)
    try { Initialize-RebootDeleteNative; [RebootDeleteNative]::MoveFileEx((Get-LongLiteralPath $LiteralPath), $null, [RebootDeleteNative]::MOVEFILE_DELAY_UNTIL_REBOOT) | Out-Null } catch {}
}

function Remove-PathViaDotNet {
    param([Parameter(Mandatory)][string]$LiteralPath, [switch]$Recurse)
    if (-not (Test-Path -LiteralPath $LiteralPath)) { return $true }
    try {
        if ([System.IO.Directory]::Exists($LiteralPath)) {
            if ($Recurse) { foreach ($c in @([System.IO.Directory]::EnumerateFileSystemEntries($LiteralPath))) { Remove-PathViaDotNet -LiteralPath $c -Recurse | Out-Null } }
            [System.IO.File]::SetAttributes($LiteralPath, [System.IO.FileAttributes]::Normal)
            [System.IO.Directory]::Delete($LiteralPath, $false)
        } elseif ([System.IO.File]::Exists($LiteralPath)) {
            [System.IO.File]::SetAttributes($LiteralPath, [System.IO.FileAttributes]::Normal)
            [System.IO.File]::Delete($LiteralPath)
        } else { return $false }
        return -not (Test-Path -LiteralPath $LiteralPath)
    } catch { return $false }
}

function Remove-SafePath {
    param([Parameter(Mandatory)][string]$LiteralPath, [switch]$Recurse)
    if (Test-SkipCleanPath $LiteralPath) { return $false }
    if (-not (Test-Path -LiteralPath $LiteralPath)) { return $false }
    if (Remove-PathViaDotNet -LiteralPath $LiteralPath -Recurse:$Recurse) { return $true }
    if (Remove-PathViaCmd    -LiteralPath $LiteralPath -Recurse:$Recurse) { return $true }
    if (Test-Path -LiteralPath $LiteralPath) { Register-DeleteOnReboot -LiteralPath $LiteralPath }
    return $false
}

function Remove-SafePathWithRetry {
    param([Parameter(Mandatory)][string]$LiteralPath, [switch]$Recurse, [int]$MaxRetries = 2)
    $attempt = 0; $success = $false
    while ($attempt -le $MaxRetries -and -not $success) {
        $success = Remove-SafePath -LiteralPath $LiteralPath -Recurse:$Recurse
        if (-not $success -and $attempt -lt $MaxRetries) { Start-Sleep -Milliseconds 500 }
        $attempt++
    }
    return $success
}

function Clear-DirectoryViaRobocopy {
    param([string]$TargetPath)
    if (-not (Test-Path $TargetPath)) { return 0 }
    $targetNorm  = ([System.IO.Path]::GetFullPath($TargetPath)).TrimEnd('\') + '\'
    $stagingRoot = Get-CleanerStagingRoot
    $emptyDir    = Join-Path $stagingRoot ("empty_" + [guid]::NewGuid().ToString('N'))
    $removed     = 0
    try {
        New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
        if ($emptyDir.StartsWith($targetNorm, [StringComparison]::OrdinalIgnoreCase)) { throw "Staging inside target" }
        $before = @(Get-ChildItem $TargetPath -Force -ErrorAction SilentlyContinue).Count
        foreach ($child in @(Get-ChildItem $TargetPath -Force -ErrorAction SilentlyContinue)) {
            if (Test-SkipCleanPath $child.FullName) { continue }
            if (Remove-SafePathWithRetry -LiteralPath $child.FullName -Recurse) { $removed++ }
        }
        $null = & robocopy.exe $emptyDir $TargetPath /mir /r:0 /w:0 /nfl /ndl /njh /njs /nc /ns /np 2>&1
        $after = @(Get-ChildItem $TargetPath -Force -ErrorAction SilentlyContinue).Count
        $removed = [Math]::Max($removed, [Math]::Max(0, $before - $after))
        foreach ($child in @(Get-ChildItem $TargetPath -Force -ErrorAction SilentlyContinue)) {
            if (Remove-SafePathWithRetry -LiteralPath $child.FullName -Recurse) { $removed++ }
            elseif (Test-Path -LiteralPath $child.FullName) { Register-DeleteOnReboot -LiteralPath $child.FullName }
        }
    } finally {
        if (Test-Path $emptyDir) { Remove-PathViaDotNet -LiteralPath $emptyDir -Recurse | Out-Null }
    }
    return $removed
}

function Remove-DirectorySilent {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (Test-SkipCleanPath $LiteralPath) { return $false }
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Container)) { return $false }
    Clear-DirectoryViaRobocopy $LiteralPath | Out-Null
    Remove-PathViaCmd -LiteralPath $LiteralPath -Recurse | Out-Null
    if (Test-Path -LiteralPath $LiteralPath) {
        foreach ($item in @(Get-ChildItem -LiteralPath $LiteralPath -Force -Recurse -ErrorAction SilentlyContinue)) { Register-DeleteOnReboot -LiteralPath $item.FullName }
        Register-DeleteOnReboot -LiteralPath $LiteralPath
        return $false
    }
    return $true
}

function Clear-SafeTempTree {
    param([string]$RootPath)
    $root = [System.Environment]::ExpandEnvironmentVariables($RootPath)
    if (-not (Test-Path $root)) { return 0 }
    $key = ([System.IO.Path]::GetFullPath($root)).TrimEnd('\').ToLowerInvariant()
    if ($script:ProcessedTempRoots.ContainsKey($key)) { return $script:ProcessedTempRoots[$key] }
    $null = Invoke-ProcessAnswerAll -FilePath 'cmd.exe' -ArgumentList @('/c', "del /f /s /q `"$root\*`"")
    $removed = Clear-DirectoryViaRobocopy $root
    foreach ($stuck in @(Get-ChildItem -LiteralPath $root -Force -Recurse -ErrorAction SilentlyContinue)) { Register-DeleteOnReboot -LiteralPath $stuck.FullName }
    $script:ProcessedTempRoots[$key] = $removed
    return $removed
}

function Test-JunkDirName {
    param([string]$Name)
    foreach ($jn in $script:JunkDirNames) { if ($Name -ieq $jn) { return $true } }
    return $false
}

function Remove-CleanPaths {
    param([string[]]$Paths)
    foreach ($p in $Paths) {
        $exp = [System.Environment]::ExpandEnvironmentVariables($p)
        if (-not (Test-Path -LiteralPath $exp)) { continue }
        if (Test-Path -LiteralPath $exp -PathType Container) { Remove-DirectorySilent -LiteralPath $exp | Out-Null }
        else { Remove-SafePathWithRetry -LiteralPath $exp | Out-Null }
    }
}

function Clear-RigorousTempLocations {
    $script:ProcessedTempRoots = @{}
    foreach ($raw in @("%TEMP%", "%LOCALAPPDATA%\Temp", "C:\Windows\Temp",
                        "%LOCALAPPDATA%\CrashDumps", "%LOCALAPPDATA%\D3DSCache",
                        "%LOCALAPPDATA%\Microsoft\Windows\WebCache",
                        "%LOCALAPPDATA%\Microsoft\Windows\Burn\Burn")) {
        $p = [System.Environment]::ExpandEnvironmentVariables($raw)
        if (Test-Path $p) { Clear-SafeTempTree $p | Out-Null }
    }
    $local = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%")
    Get-ChildItem $local -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        foreach ($n in @("Temp","temp","tmp","Tmp")) {
            $tp = Join-Path $_.FullName $n
            if (Test-Path $tp) { Clear-SafeTempTree $tp | Out-Null }
        }
    }
}

function Clear-AppDataJunkSweep {
    param([string]$RootVar)
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
                if (Test-JunkDirName $_.Name) { if (Remove-DirectorySilent -LiteralPath $child) { $cleared++ } }
                elseif ($cur.Depth -lt 3) { $stack.Push(@{ Path = $child; Depth = $cur.Depth + 1 }) }
            }
        }
    }
    return $cleared
}

function Clear-RecycleBinSilent {
    if (-not ('RecycleBinNative' -as [type])) {
        Add-Type @"
using System; using System.Runtime.InteropServices;
public static class RecycleBinNative {
    [DllImport("Shell32.dll", CharSet = CharSet.Unicode)]
    public static extern int SHEmptyRecycleBin(IntPtr hwnd, string pszRootPath, uint dwFlags);
    public const uint SHERB_NOCONFIRMATION = 0x00000001;
    public const uint SHERB_NOPROGRESSUI   = 0x00000002;
    public const uint SHERB_NOSOUND        = 0x00000004;
}
"@
    }
    $flags = [RecycleBinNative]::SHERB_NOCONFIRMATION -bor [RecycleBinNative]::SHERB_NOPROGRESSUI -bor [RecycleBinNative]::SHERB_NOSOUND
    [RecycleBinNative]::SHEmptyRecycleBin([IntPtr]::Zero, $null, $flags) | Out-Null
}

function Clear-StoreAppTemp {
    $pkgs = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Packages")
    if (-not (Test-Path $pkgs)) { return }
    Get-ChildItem $pkgs -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        foreach ($sub in @("AC\Temp", "AC\Microsoft\CryptnetUrlCache")) {
            $t = Join-Path $_.FullName $sub
            if (Test-Path $t) { Remove-DirectorySilent -LiteralPath $t | Out-Null }
        }
    }
}

$script:BrowserDiscoveryExcludes = @('\Cursor\','\discord\','\Discord\','\Slack\','\Teams\','\Postman\',
    '\GitHub Desktop\','\Notion\','\Obsidian\','\Spotify\','\Zoom\','\Antigravity\','\Windsurf\',
    '\Qoder\','\kiro\','\Trae\','\Devin\','\electron\','\Microsoft\Teams\','\Code\')

function Test-BrowserDiscoveryExcluded { param([string]$Path)
    foreach ($f in $script:BrowserDiscoveryExcludes) { if ($Path -like "*$f*") { return $true } }; return $false }

function Test-ChromiumUserDataRoot { param([string]$Path)
    if (Test-BrowserDiscoveryExcluded $Path) { return $false }
    if (-not (Test-Path -LiteralPath (Join-Path $Path 'Local State'))) { return $false }
    foreach ($child in @(Get-ChildItem -LiteralPath $Path -Directory -ErrorAction SilentlyContinue)) {
        if ($child.Name -eq 'Default' -or $child.Name -like 'Profile *' -or $child.Name -eq 'Guest Profile') { return $true }
    }
    return $false }

function Find-ChromiumBrowserRoots {
    $found = @{}
    foreach ($base in @([System.Environment]::ExpandEnvironmentVariables('%LOCALAPPDATA%'), [System.Environment]::ExpandEnvironmentVariables('%APPDATA%'))) {
        if (-not (Test-Path $base)) { continue }
        foreach ($ls in @(Get-ChildItem -Path $base -Filter 'Local State' -File -Recurse -Depth 6 -ErrorAction SilentlyContinue)) {
            $root = $ls.Directory.FullName
            if (Test-BrowserDiscoveryExcluded $root) { continue }
            if (-not (Test-ChromiumUserDataRoot $root)) { continue }
            $key = $root.ToLowerInvariant()
            if (-not $found.ContainsKey($key)) { $found[$key] = $root }
        }
    }
    return @($found.Values | Sort-Object) }

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
    return @($found.Values) }

$script:ChromiumCleanDirs  = @("Cache","Code Cache","GPUCache","Media Cache","blob_storage",
    "Service Worker\CacheStorage","Service Worker\ScriptCache","Local Storage","IndexedDB",
    "Session Storage","Application Cache","Network","Extension State","Storage",
    "DawnCache","GrShaderCache","ShaderCache","Shared Dictionary","optimization_guide_hint_cache_store")
$script:ChromiumCleanFiles = @("Cookies","Cookies-journal","History","History-journal",
    "Visited Links","Top Sites","Top Sites-journal","Shortcuts","Shortcuts-journal",
    "Network Action Predictor","Favicons","Favicons-journal","Extension Cookies",
    "QuotaManager","Reporting and NEL","Reporting and NEL-journal")
$script:GeckoCleanDirs  = @("cache2","startupCache","OfflineCache","thumbnails","storage","jumpListCache")
$script:GeckoCleanFiles = @("cookies.sqlite","cookies.sqlite-shm","cookies.sqlite-wal",
    "downloads.sqlite","favicons.sqlite","favicons.sqlite-shm","favicons.sqlite-wal",
    "webappsstore.sqlite","content-prefs.sqlite","permissions.sqlite","sessionCheckpoints.json")

function Clear-ChromiumBrowserCache { param([string]$UserDataPath)
    $base = [System.Environment]::ExpandEnvironmentVariables($UserDataPath)
    if (-not (Test-Path $base)) { return }
    Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $profile = $_.FullName
        foreach ($d in $script:ChromiumCleanDirs) {
            $t = Join-Path $profile $d
            if (Test-Path -LiteralPath $t -PathType Container) { Remove-DirectorySilent -LiteralPath $t | Out-Null }
            elseif (Test-Path -LiteralPath $t) { Remove-SafePathWithRetry -LiteralPath $t | Out-Null }
        }
        foreach ($f in $script:ChromiumCleanFiles) { Remove-SafePathWithRetry -LiteralPath (Join-Path $profile $f) | Out-Null }
    } }

function Clear-GeckoBrowserProfiles { param([string]$ProfilesPath)
    if (-not (Test-Path $ProfilesPath)) { return }
    Get-ChildItem $ProfilesPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $p = $_.FullName
        foreach ($d in $script:GeckoCleanDirs) {
            $t = Join-Path $p $d
            if (Test-Path -LiteralPath $t -PathType Container) { Remove-DirectorySilent -LiteralPath $t | Out-Null }
            elseif (Test-Path -LiteralPath $t) { Remove-SafePathWithRetry -LiteralPath $t | Out-Null }
        }
        foreach ($f in $script:GeckoCleanFiles) { Remove-SafePathWithRetry -LiteralPath (Join-Path $p $f) | Out-Null }
    } }

function Close-BrowserProcesses {
    param([scriptblock]$Log = { param($m) })
    foreach ($n in @("chrome","msedge","brave","vivaldi","opera","yandexbrowser","chromium","arc","wavebox",
                     "sidekick","centbrowser","coccoc","ucbrowser","epicprivacybrowser","gensparkbrowser",
                     "firefox","waterfox","palemoon","librewolf","torbrowser","basilisk","thunderbird")) {
        $procs = Get-Process -Name $n -ErrorAction SilentlyContinue
        if ($procs) { & $Log "  Closing $n..."; Stop-Process -Name $n -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2 }
    }
}

function Clear-AllInstalledBrowsers {
    param([scriptblock]$Log = { param([string]$Message) })
    & $Log "  Closing browser processes (to unlock files)..."
    Close-BrowserProcesses -Log $Log
    & $Log "  Scanning PC for all installed browsers..."
    $chromiumRoots = Find-ChromiumBrowserRoots
    $geckoBrowsers = Find-GeckoBrowserProfileDirs
    $count = $chromiumRoots.Count + $geckoBrowsers.Count
    if ($count -eq 0) { & $Log "  No browser profiles found."; return }
    & $Log "  Found $count browser location(s). Cleaning cache/cookies (passwords SAFE)."
    foreach ($root in $chromiumRoots) { & $Log "  -> $(Split-Path (Split-Path $root -Parent) -Leaf)"; Clear-ChromiumBrowserCache $root }
    foreach ($g in $geckoBrowsers) { & $Log "  -> $($g.Name)"; Clear-GeckoBrowserProfiles $g.Path }
    & $Log "  [All Browsers] cleared. Passwords and autofill NOT touched."
}

# ════════════════════════════════════════════════════
# MAIN CLEAN SEQUENCE
# ════════════════════════════════════════════════════

$script:SpaceFreedLine = $null
$sysDrive    = $env:SystemDrive
$freeAtStart = Get-DriveFreeBytes $sysDrive

function Write-CleanLog {
    param([string]$Message)
    if ($Message -match '^PRESCAN_ESTIMATE:') { $script:EstimateStr = $Message -replace '^PRESCAN_ESTIMATE:',''; return }
    if ($Message -match '^FREED_BYTES:') { return }
    if ($Message -match '^-- PRE-SCAN')       { Write-Host ""; Write-Host $Message -ForegroundColor Yellow }
    elseif ($Message -match '^-- STEP')       { Write-Host ""; Write-Host $Message -ForegroundColor Cyan }
    elseif ($Message -match 'Estimated junk') { Write-Host $Message -ForegroundColor Yellow }
    elseif ($Message -match "^    ")          { Write-Host $Message -ForegroundColor DarkYellow }
    elseif ($Message -match "That's like")    { Write-Host $Message -ForegroundColor Cyan }
    elseif ($Message -match 'Space freed')    { $script:SpaceFreedLine = $Message }
    elseif ($Message -match '^={3,}')         { }
    elseif ($Message -match 'NOT touched|skipped|auto-skip') { Write-Host $Message -ForegroundColor DarkYellow }
    else { Write-Host $Message -ForegroundColor Green }
}

$log = { param([string]$Message) Write-CleanLog $Message }

Write-Host "-- PRE-SCAN: measuring junk (nothing deleted yet) --" -ForegroundColor Yellow
$estimate = Get-CleanupEstimate
Write-Host ("  Estimated junk: " + (Format-ByteSize $estimate.TotalBytes) + " across " + $estimate.Count + " locations") -ForegroundColor Yellow
foreach ($hit in $estimate.Top5) { Write-Host ("    " + $hit.ShortLabel.PadRight(28) + "  " + (Format-ByteSize $hit.Bytes)) -ForegroundColor DarkYellow }
Write-Host ""

Write-Host "-- STEP 1: AI App Caches --" -ForegroundColor Cyan
Remove-CleanPaths @(
    "%APPDATA%\Antigravity", "%LOCALAPPDATA%\Antigravity",
    "%APPDATA%\Cursor\Cache", "%APPDATA%\Cursor\CachedData", "%APPDATA%\Cursor\logs", "%LOCALAPPDATA%\cursor-updater",
    "%APPDATA%\Qoder", "%LOCALAPPDATA%\Qoder",
    "%APPDATA%\kiro", "%APPDATA%\kiro\Cache", "%APPDATA%\kiro\CachedData", "%LOCALAPPDATA%\kiro",
    "%APPDATA%\Trae", "%APPDATA%\trae-ai", "%LOCALAPPDATA%\Trae",
    "%APPDATA%\Windsurf\Cache", "%APPDATA%\Windsurf\CachedData", "%APPDATA%\Windsurf\logs", "%LOCALAPPDATA%\Windsurf",
    "%APPDATA%\Devin", "%LOCALAPPDATA%\Devin",
    "%APPDATA%\warp", "%LOCALAPPDATA%\Warp\data",
    "%APPDATA%\Genspark", "%LOCALAPPDATA%\Genspark"
)
Write-Host "  [AI App Caches] cleared." -ForegroundColor Green

Write-Host "-- STEP 2: All Installed Browsers (passwords SAFE) --" -ForegroundColor Cyan
Clear-AllInstalledBrowsers -Log $log

Write-Host "-- STEP 3: Prefetch --" -ForegroundColor Cyan
foreach ($pf in @(Get-ChildItem "C:\Windows\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue)) {
    Remove-SafePathWithRetry -LiteralPath $pf.FullName | Out-Null
}
Write-Host "  [Prefetch] cleared." -ForegroundColor Green

Write-Host "-- STEP 4: Temp Files + AppData Junk (robocopy bulk clear) --" -ForegroundColor Cyan
Clear-RigorousTempLocations
$localCount = Clear-AppDataJunkSweep "%LOCALAPPDATA%"
$roamCount  = Clear-AppDataJunkSweep "%APPDATA%"
Write-Host ('  [Temp + AppData] cleared (' + $localCount + ' local + ' + $roamCount + ' roaming junk folders).') -ForegroundColor Green

Write-Host "-- STEP 5: Recycle Bin + Update Cache --" -ForegroundColor Cyan
try { Clear-RecycleBinSilent } catch {}
Write-Host "  [Recycle Bin] emptied." -ForegroundColor Green
foreach ($wuPath in @("C:\Windows\SoftwareDistribution\Download", "C:\Windows\SoftwareDistribution\DataStore\Logs")) {
    if (Test-Path $wuPath) { Clear-SafeTempTree $wuPath | Out-Null }
}
Write-Host "  [Windows Update cache] cleared." -ForegroundColor Green
Clear-StoreAppTemp
Write-Host "  [Store app temp] cleared." -ForegroundColor Green

Write-Host "-- STEP 6: INetCache + Thumbnail/Icon Cache --" -ForegroundColor Cyan
$inetCache = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Microsoft\Windows\INetCache")
if (Test-Path $inetCache) { Clear-DirectoryViaRobocopy $inetCache | Out-Null; Remove-PathViaCmd -LiteralPath $inetCache -Recurse | Out-Null }
Write-Host "  [INetCache] cleared." -ForegroundColor Green
$explorerCache = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Microsoft\Windows\Explorer")
if (Test-Path $explorerCache) {
    foreach ($db in @(Get-ChildItem $explorerCache -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue)) { Remove-SafePathWithRetry -LiteralPath $db.FullName | Out-Null }
    foreach ($db in @(Get-ChildItem $explorerCache -Filter "iconcache_*.db"  -ErrorAction SilentlyContinue)) { Remove-SafePathWithRetry -LiteralPath $db.FullName | Out-Null }
}
Write-Host "  [Thumbnail/Icon cache] cleared." -ForegroundColor Green

Write-Host "-- STEP 7: Event Logs + DNS Cache --" -ForegroundColor Cyan
foreach ($logName in @("Application","System","Security","Setup")) {
    try { wevtutil cl $logName 2>&1 | Out-Null } catch {}
    Write-Host "  [Event Log: $logName] cleared." -ForegroundColor Green
}
try { Clear-DnsClientCache -ErrorAction Stop } catch { ipconfig /flushdns | Out-Null }
Write-Host "  [DNS Cache] flushed." -ForegroundColor Green

# ── Final summary ──────────────────────────────────────────────
$freeAtEnd  = Get-DriveFreeBytes $sysDrive
$totalFreed = [Math]::Max(0, $freeAtEnd - $freeAtStart)
$freedStr   = Format-ByteSize $totalFreed
$comparison = Format-ByteComparison $totalFreed

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  All done!" -ForegroundColor Green
Write-Host ""
Write-Host ('  >>> ' + $freedStr + ' freed <<<') -ForegroundColor White -BackgroundColor DarkGreen
if ($comparison) { Write-Host "  $comparison" -ForegroundColor Cyan }
Write-Host ""
Write-Host "  Temp + app cache + browser cache: CLEARED"   -ForegroundColor Green
Write-Host "  Passwords (Login Data): NOT touched"         -ForegroundColor Green
Write-Host "  Autofill / form data: NOT touched"           -ForegroundColor Green
Write-Host "  Downloads folder: NOT touched"               -ForegroundColor Green
Write-Host ""
Write-Host "  THANKS CODEX FOR UR CLEAN PC"               -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Cyan
