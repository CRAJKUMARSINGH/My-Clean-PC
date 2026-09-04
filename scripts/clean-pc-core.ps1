# My Clean PC - shared cleaning core (single source of truth)
# Dot-source from my-clean-pc.ps1, cleanup_task.ps1, etc.
# Passwords (Login Data, key4.db), autofill data, Downloads, and Quick Access pins are NEVER touched.

# ---- Non-interactive bypass: auto-answer Yes/OK/All to any prompt --------
$ErrorActionPreference  = "SilentlyContinue"
$ConfirmPreference      = "None"          # suppresses -Confirm on all cmdlets
$ProgressPreference     = "SilentlyContinue"
$WarningPreference      = "SilentlyContinue"
$InformationPreference  = "SilentlyContinue"
$VerbosePreference      = "SilentlyContinue"
$DebugPreference        = "SilentlyContinue"
$WhatIfPreference       = $false          # never dry-run
# Auto-YES to every PowerShell cmdlet confirmation and force-flag
$PSDefaultParameterValues["*:Confirm"] = $false
$PSDefaultParameterValues["*:Force"]   = $true
$PSDefaultParameterValues["*:WhatIf"]  = $false
# -------------------------------------------------------------------------

# Paths never deleted (passwords, autofill, Downloads, self-install folder, Quick Access / Explorer shell state)
$script:SkipPathFragments = @(
    "\Login Data", "\Login Data For Account", "\key4.db", "\formhistory.sqlite",
    "\Web Data", "\Web Data-journal", "\Autofill", "\Downloads", "\MyCleanPC\",
    "\Microsoft\Windows\Recent\", "\Microsoft\Windows\History\",
    "\Microsoft\Windows\Recent\AutomaticDestinations", "\Microsoft\Windows\Recent\CustomDestinations"
)

# Temp roots already cleared this run (avoids duplicate passes that can re-trigger shell UI)
$script:ProcessedTempRoots = @{}

# ---- Space-freed helpers ------------------------------------------------

function Format-ByteSize {
    param($Bytes)
    if ($null -eq $Bytes) { $Bytes = 0 }
    $Bytes = [long]$Bytes
    if ($Bytes -ge 1GB) { return ('{0:F2} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:F1} MB' -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ('{0:F0} KB' -f ($Bytes / 1KB)) }
    return "$Bytes B"
}

# Reads available free bytes on the given drive letter (e.g. "C:" or "C:\").
# Uses DriveInfo - no shell, no WMI, instant.
function Get-DriveFreeBytes {
    param([string]$Drive = $env:SystemDrive)
    try {
        $letter = $Drive.TrimEnd('\').TrimEnd(':') + ':\'
        $info = [System.IO.DriveInfo]::GetDrives() |
                Where-Object { $_.Name -ieq $letter } |
                Select-Object -First 1
        if ($info) { return $info.AvailableFreeSpace }
    } catch {}
    return [long]0
}

# Fast recursive file-size sum via .NET enumeration - no shell, no dialog.
# Used to estimate how much a path contributes before it is deleted.
function Measure-PathSizeBytes {
    param([string]$LiteralPath)
    if (-not $LiteralPath -or -not (Test-Path -LiteralPath $LiteralPath)) { return [long]0 }
    try {
        if (Test-Path -LiteralPath $LiteralPath -PathType Leaf) {
            return ([System.IO.FileInfo]$LiteralPath).Length
        }
        $total = [long]0
        foreach ($f in [System.IO.Directory]::EnumerateFiles(
                $LiteralPath, '*', [System.IO.SearchOption]::AllDirectories)) {
            try { $total += ([System.IO.FileInfo]$f).Length } catch {}
        }
        return $total
    } catch { return [long]0 }
}

# ---- Pre-scan & fun-facts helpers --------------------------------------- #

$script:AiAppRootVars = @(
    '%APPDATA%\Cursor', '%LOCALAPPDATA%\Cursor',
    '%APPDATA%\Code', '%LOCALAPPDATA%\Code',
    '%APPDATA%\kiro', '%LOCALAPPDATA%\kiro',
    '%APPDATA%\Windsurf', '%LOCALAPPDATA%\Windsurf',
    '%APPDATA%\Trae', '%APPDATA%\trae-ai', '%LOCALAPPDATA%\Trae',
    '%APPDATA%\Antigravity', '%LOCALAPPDATA%\Antigravity',
    '%APPDATA%\Qoder', '%LOCALAPPDATA%\Qoder',
    '%APPDATA%\Devin', '%LOCALAPPDATA%\Devin',
    '%APPDATA%\warp', '%LOCALAPPDATA%\Warp',
    '%APPDATA%\Genspark', '%LOCALAPPDATA%\Genspark',
    '%APPDATA%\Claude', '%LOCALAPPDATA%\AnthropicClaude',
    '%APPDATA%\ChatGPT', '%LOCALAPPDATA%\ChatGPT',
    '%APPDATA%\GitHub Copilot', '%LOCALAPPDATA%\github-copilot',
    '%APPDATA%\Copilot', '%LOCALAPPDATA%\Copilot'
)

# Electron/Chromium cache folder names. Never User/, settings, or chat DBs.
$script:AiCacheDirNames = @(
    'Cache', 'Caches', 'CachedData', 'Code Cache', 'GPUCache', 'Media Cache',
    'DawnCache', 'DawnWebGPUCache', 'DawnGraphiteCache', 'blob_storage',
    'CachedExtensionVSIXs', 'CachedExtensions', 'logs', 'Crashpad', 'crashpad',
    'Service Worker', 'ShaderCache', 'GrShaderCache', 'Shared Dictionary',
    'GraphiteDawnCache'
)

# Do not walk into settings/chat trees while hunting cache folders.
$script:AiCacheSkipDescend = @(
    'User', 'Users', 'Backups', 'databases', 'IndexedDB',
    'workspaceStorage', 'WorkspaceStorage', 'globalStorage', 'History'
)

function Add-UniquePath {
    param(
        [System.Collections.Generic.List[string]]$List,
        [hashtable]$Seen,
        [string]$Path
    )
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return }
    $key = $Path.ToLowerInvariant()
    if ($Seen.ContainsKey($key)) { return }
    $Seen[$key] = $true
    [void]$List.Add($Path)
}

function Get-AiCacheTargetPaths {
    $out = New-Object System.Collections.Generic.List[string]
    $seen = @{}
    $maxDepth = 4
    foreach ($raw in $script:AiAppRootVars) {
        $root = [System.Environment]::ExpandEnvironmentVariables($raw)
        if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
        $stack = New-Object System.Collections.Stack
        $stack.Push(@{ Path = $root; Depth = 0 })
        while ($stack.Count -gt 0) {
            $cur = $stack.Pop()
            foreach ($child in @(Get-ChildItem -LiteralPath $cur.Path -Force -ErrorAction SilentlyContinue)) {
                $childPath = $child.FullName
                if (-not $child.PSIsContainer) { continue }
                if ($script:AiCacheDirNames -icontains $child.Name) {
                    Add-UniquePath $out $seen $childPath
                    continue
                }
                if ($cur.Depth -ge $maxDepth) { continue }
                if ($script:AiCacheSkipDescend -icontains $child.Name) { continue }
                $stack.Push(@{ Path = $childPath; Depth = ($cur.Depth + 1) })
            }
        }
    }
    foreach ($extra in @('%LOCALAPPDATA%\cursor-updater')) {
        Add-UniquePath $out $seen ([System.Environment]::ExpandEnvironmentVariables($extra))
    }
    return @($out)
}

function Get-KnownChromiumUserDataRoots {
    return @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data",
        "$env:LOCALAPPDATA\Google\Chrome Beta\User Data",
        "$env:LOCALAPPDATA\Google\Chrome SxS\User Data",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data",
        "$env:LOCALAPPDATA\Microsoft\Edge Beta\User Data",
        "$env:LOCALAPPDATA\Microsoft\Edge Dev\User Data",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser-Beta\User Data",
        "$env:LOCALAPPDATA\Vivaldi\User Data",
        "$env:APPDATA\Opera Software\Opera Stable",
        "$env:APPDATA\Opera Software\Opera GX Stable",
        "$env:LOCALAPPDATA\Opera Software\Opera Stable",
        "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data",
        "$env:LOCALAPPDATA\Chromium\User Data",
        "$env:LOCALAPPDATA\Arc\User Data",
        "$env:LOCALAPPDATA\Genspark\User Data",
        "$env:LOCALAPPDATA\GensparkBrowser\User Data",
        "$env:LOCALAPPDATA\DuckDuckGo\User Data",
        "$env:LOCALAPPDATA\Microsoft\Edge SxS\User Data",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser-Nightly\User Data"
    )
}

# Fast read-only size scan: measures everything that *would* be cleaned
# without deleting a single byte.  Returns a hashtable:
#   { TotalBytes, Count, Top5: [{Label, ShortLabel, Bytes}] }
function Get-CleanupEstimate {
    $hits = [System.Collections.Generic.List[hashtable]]::new()

    function AddHit([string]$full, [string]$short) {
        if (-not $full -or -not (Test-Path -LiteralPath $full)) { return }
        $b = Measure-PathSizeBytes $full
        if ($b -gt 0) { $hits.Add(@{ Label = $full; ShortLabel = $short; Bytes = $b }) }
    }

    # Temp folders
    AddHit ([System.Environment]::ExpandEnvironmentVariables('%TEMP%'))             'User Temp'
    AddHit ([System.Environment]::ExpandEnvironmentVariables('%LOCALAPPDATA%\Temp')) 'LocalAppData\Temp'
    AddHit 'C:\Windows\Temp'                                                         'Windows\Temp'

    # AI dev-tool caches (cache folders only — never the whole app profile)
    foreach ($p in @(Get-AiCacheTargetPaths)) {
        $full = [System.Environment]::ExpandEnvironmentVariables($p)
        $leaf = Split-Path (Split-Path $full -Parent) -Leaf
        AddHit $full "$leaf cache"
    }

    # Common browser caches (Chromium-family) — profile Cache dirs only, no full recurse
    foreach ($root in @(Get-KnownChromiumUserDataRoots)) {
        if (-not (Test-Path $root)) { continue }
        $appName = Get-BrowserLabelFromPath $root
        foreach ($prof in @(Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -eq 'Default' -or $_.Name -like 'Profile *' })) {
            AddHit (Join-Path $prof.FullName 'Cache') "$appName Cache"
            AddHit (Join-Path $prof.FullName 'Code Cache') "$appName Code Cache"
        }
    }

    # Firefox
    $ffBase = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $ffBase) {
        foreach ($prof in @(Get-ChildItem $ffBase -Directory -ErrorAction SilentlyContinue)) {
            AddHit (Join-Path $prof.FullName 'cache2') 'Firefox Cache'
        }
    }

    # INetCache / Thumbnail cache
    AddHit ([System.Environment]::ExpandEnvironmentVariables('%LOCALAPPDATA%\Microsoft\Windows\INetCache')) 'INetCache'
    AddHit ([System.Environment]::ExpandEnvironmentVariables('%LOCALAPPDATA%\Microsoft\Windows\Explorer'))  'Thumbnail DB'

    $items = New-Object System.Collections.Generic.List[object]
    $total = [long]0
    foreach ($hit in $hits) {
        $bytes = [long]0
        if ($hit.ContainsKey('Bytes')) { $bytes = [long]$hit['Bytes'] }
        $row = [pscustomobject]@{
            Label      = [string]$hit['Label']
            ShortLabel = [string]$hit['ShortLabel']
            Bytes      = $bytes
        }
        $total += $bytes
        [void]$items.Add($row)
    }
    $sorted = @($items | Sort-Object Bytes -Descending)

    return [pscustomobject]@{
        TotalBytes = $total
        Count      = $items.Count
        Top5       = @($sorted | Select-Object -First 5)
    }
}

# Returns a fun human-scale comparison for a given byte count.
# e.g.  "That's like 1,420 MP3 songs"  or  "That's like 312 holiday photos"
function Format-ByteComparison {
    param([long]$Bytes)
    if ($Bytes -le 10MB) { return '' }

    $songs  = [Math]::Round($Bytes / 4MB)
    $photos = [Math]::Round($Bytes / 4.5MB)
    $video  = [Math]::Round($Bytes / 50MB)    # HD Netflix ~50 MB/min
    $emails = [Math]::Round($Bytes / 0.3MB)   # avg email with attachment

    # Pick whichever gives the most satisfying number (50-9,999 range)
    if ($songs  -in 50..9999) { return "That's like $("{0:N0}" -f $songs) MP3 songs" }
    if ($photos -in 50..9999) { return "That's like $("{0:N0}" -f $photos) holiday photos" }
    if ($video  -in 5..999)   { return "That's like $("{0:N0}" -f $video) minutes of HD video" }
    if ($emails -in 50..9999) { return "That's like $("{0:N0}" -f $emails) emails" }
    if ($songs  -lt 50)       { return "That's like $("{0:N0}" -f $photos) holiday photos" }
    return "That's like $("{0:N0}" -f [Math]::Round($Bytes / 1GB * 250)) songs"
}

# ------------------------------------------------------------------------- #

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
    if ($full.StartsWith('\\')) { return '\\?\UNC\' + $full.Substring(2) }
    return '\\?\' + $full
}

function Clear-PathAttributes {
    param([Parameter(Mandatory)][string]$LiteralPath)
    try {
        if ([System.IO.Directory]::Exists($LiteralPath)) {
            [System.IO.File]::SetAttributes($LiteralPath, [System.IO.FileAttributes]::Normal)
        } elseif ([System.IO.File]::Exists($LiteralPath)) {
            [System.IO.File]::SetAttributes($LiteralPath, [System.IO.FileAttributes]::Normal)
        } else {
            $long = Get-LongLiteralPath $LiteralPath
            if ([System.IO.Directory]::Exists($long)) {
                [System.IO.File]::SetAttributes($long, [System.IO.FileAttributes]::Normal)
            } elseif ([System.IO.File]::Exists($long)) {
                [System.IO.File]::SetAttributes($long, [System.IO.FileAttributes]::Normal)
            }
        }
    } catch {}
}

function Get-CleanerStagingRoot {
    $candidates = @(
        (Join-Path $env:ProgramData "MyCleanPC"),
        (Join-Path ([System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%")) "MyCleanPC")
    )
    foreach ($candidate in $candidates) {
        try {
            if (-not (Test-Path -LiteralPath $candidate)) {
                New-Item -ItemType Directory -Path $candidate -Force | Out-Null
            }
            if (Test-Path -LiteralPath $candidate -PathType Container) { return $candidate }
        } catch {}
    }
    return ([System.IO.Path]::GetTempPath())
}

# cmd.exe rd/del - never invokes Explorer "do this for all" shell UI
function Invoke-ProcessAnswerAll {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$ArgumentList,
        [int]$TimeoutMilliseconds = 120000
    )
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath
        # Windows PowerShell 5.1 / .NET Framework has no ArgumentList — use Arguments.
        if ($psi.GetType().GetProperty('ArgumentList')) {
            foreach ($arg in $ArgumentList) { [void]$psi.ArgumentList.Add($arg) }
        } else {
            $quoted = foreach ($arg in $ArgumentList) {
                if ($null -eq $arg) { continue }
                if ($arg -match '[\s&()^|<>"]') { '"' + ($arg -replace '"', '\"') + '"' } else { $arg }
            }
            $psi.Arguments = ($quoted -join ' ')
        }
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        [void]$proc.Start()
        try {
            $proc.StandardInput.WriteLine('A')
            $proc.StandardInput.WriteLine('Y')
            $proc.StandardInput.Close()
        } catch {}
        if (-not $proc.WaitForExit($TimeoutMilliseconds)) {
            try { $proc.Kill() } catch {}
            return $false
        }
        return ($proc.ExitCode -eq 0)
    } catch {
        return $false
    }
}

function Remove-PathViaCmd {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [switch]$Recurse
    )
    if (-not (Test-Path -LiteralPath $LiteralPath)) { return $true }
    Clear-PathAttributes $LiteralPath
    $isDir = Test-Path -LiteralPath $LiteralPath -PathType Container
    if ($isDir -or $Recurse) {
        $ok = Invoke-ProcessAnswerAll -FilePath 'cmd.exe' -ArgumentList @('/c', 'rd', '/s', '/q', $LiteralPath)
    } else {
        $ok = Invoke-ProcessAnswerAll -FilePath 'cmd.exe' -ArgumentList @('/c', 'del', '/f', '/q', '/a', $LiteralPath)
    }
    if (-not $ok) { return $false }
    return -not (Test-Path -LiteralPath $LiteralPath)
}

function Initialize-RebootDeleteNative {
    if ('RebootDeleteNative' -as [type]) { return }
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class RebootDeleteNative {
    [DllImport("Kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName, int dwFlags);
    public const int MOVEFILE_DELAY_UNTIL_REBOOT = 0x4;
}
"@
}

function Register-DeleteOnReboot {
    param([Parameter(Mandatory)][string]$LiteralPath)
    try {
        Initialize-RebootDeleteNative
        $long = Get-LongLiteralPath $LiteralPath
        [RebootDeleteNative]::MoveFileEx($long, $null, [RebootDeleteNative]::MOVEFILE_DELAY_UNTIL_REBOOT) | Out-Null
    } catch {}
}

# Kernel-level delete - never routes through Explorer shell (no "do this for all" dialogs)
function Remove-PathViaDotNet {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [switch]$Recurse
    )
    if (-not (Test-Path -LiteralPath $LiteralPath)) { return $true }
    try {
        if ([System.IO.Directory]::Exists($LiteralPath)) {
            if ($Recurse) {
                foreach ($child in @([System.IO.Directory]::EnumerateFileSystemEntries($LiteralPath))) {
                    Remove-PathViaDotNet -LiteralPath $child -Recurse | Out-Null
                }
            }
            [System.IO.File]::SetAttributes($LiteralPath, [System.IO.FileAttributes]::Normal)
            [System.IO.Directory]::Delete($LiteralPath, $false)
        } elseif ([System.IO.File]::Exists($LiteralPath)) {
            [System.IO.File]::SetAttributes($LiteralPath, [System.IO.FileAttributes]::Normal)
            [System.IO.File]::Delete($LiteralPath)
        } else {
            $long = Get-LongLiteralPath $LiteralPath
            if ([System.IO.Directory]::Exists($long)) {
                if ($Recurse) {
                    foreach ($child in @([System.IO.Directory]::EnumerateFileSystemEntries($long))) {
                        Remove-PathViaDotNet -LiteralPath $child -Recurse | Out-Null
                    }
                }
                [System.IO.File]::SetAttributes($long, [System.IO.FileAttributes]::Normal)
                [System.IO.Directory]::Delete($long, $false)
            } elseif ([System.IO.File]::Exists($long)) {
                [System.IO.File]::SetAttributes($long, [System.IO.FileAttributes]::Normal)
                [System.IO.File]::Delete($long)
            } else {
                return $false
            }
        }
        return -not (Test-Path -LiteralPath $LiteralPath)
    } catch {
        return $false
    }
}

# Robocopy mirror-from-empty: bulk-clears directory CONTENTS with zero UI prompts.
# Locked files are silently skipped by robocopy - no Explorer dialog ever appears.
function Clear-DirectoryViaRobocopy {
    param([string]$TargetPath)
    if (-not (Test-Path $TargetPath)) { return 0 }
    $targetNorm = ([System.IO.Path]::GetFullPath($TargetPath)).TrimEnd('\') + '\'
    $stagingRoot = Get-CleanerStagingRoot
    $emptyDir = Join-Path $stagingRoot ("empty_" + [guid]::NewGuid().ToString('N'))
    $removed = 0
    $script:LastRobocopyExit = 16
    try {
        New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
        if ($emptyDir.StartsWith($targetNorm, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Staging dir must not be inside target"
        }
        $before = @(Get-ChildItem $TargetPath -Force -ErrorAction SilentlyContinue).Count
        # Robocopy /MIR from empty = wipe contents. Locked files are skipped (exit 0-8).
        # Do NOT MoveFileEx every leftover file — that made browser/AI cache passes take 10-30 min each.
        $null = & robocopy.exe $emptyDir $TargetPath /mir /r:0 /w:0 /mt:8 /nfl /ndl /njh /njs /nc /ns /np 2>&1
        $script:LastRobocopyExit = $LASTEXITCODE
        $after = @(Get-ChildItem $TargetPath -Force -ErrorAction SilentlyContinue).Count
        $removed = [Math]::Max(0, $before - $after)
    } finally {
        if (Test-Path $emptyDir) {
            Remove-PathViaDotNet -LiteralPath $emptyDir -Recurse | Out-Null
        }
    }
    return $removed
}

# -----------------------------------------------------------------------
# Remove-DirectorySilent - the right way to delete an entire directory.
#
# THREE-STAGE SILENT DELETE. Zero Explorer "Do this for all items" dialogs:
#   Stage 1 - Robocopy /MIR from an empty folder wipes all contents.
#              Robocopy skips locked files silently; no Shell involvement.
#   Stage 2 - cmd "rd /s /q" removes the now-empty (or near-empty) shell.
#              Runs as a hidden process; never touches the Explorer shell.
#   Stage 3 - MoveFileEx DELAY_UNTIL_REBOOT registers any still-locked
#              remnant for silent deletion at next Windows boot.
# -----------------------------------------------------------------------
function Remove-DirectorySilent {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [switch]$KeepContainer
    )
    if (Test-SkipCleanPath $LiteralPath) { return $false }
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Container)) { return $false }

    # Stage 1: Robocopy wipe - zero Explorer dialogs, locked files silently skipped
    $removed = Clear-DirectoryViaRobocopy $LiteralPath

    if ($KeepContainer) {
        $robocopyOk = ($script:LastRobocopyExit -lt 8)
        $empty = (@(Get-ChildItem -LiteralPath $LiteralPath -Force -ErrorAction SilentlyContinue).Count -eq 0)
        return $robocopyOk -or ($removed -gt 0) -or $empty
    }

    # Stage 2: Remove the (now mostly/fully empty) directory shell via cmd
    Remove-PathViaCmd -LiteralPath $LiteralPath -Recurse | Out-Null

    # Stage 3: folder-level reboot delete only (never enumerate every leftover cache file)
    if (Test-Path -LiteralPath $LiteralPath) {
        Register-DeleteOnReboot -LiteralPath $LiteralPath
        return $false
    }
    return $true
}

# Friendly names for apps we close so the user notice reads naturally.
$script:ProcessDisplayNames = @{
    chrome = 'Google Chrome'; msedge = 'Microsoft Edge'; brave = 'Brave'
    vivaldi = 'Vivaldi'; opera = 'Opera'; yandexbrowser = 'Yandex'
    chromium = 'Chromium'; firefox = 'Firefox'; waterfox = 'Waterfox'
    palemoon = 'Pale Moon'; librewolf = 'LibreWolf'; torbrowser = 'Tor Browser'
    basilisk = 'Basilisk'; gensparkbrowser = 'Genspark Browser'
    Kiro = 'Kiro'; Windsurf = 'Windsurf'; Trae = 'Trae'
    Antigravity = 'Antigravity'; Qoder = 'Qoder'; warp = 'Warp'
    Genspark = 'Genspark'; ChatGPT = 'ChatGPT'; Claude = 'Claude'
}

$script:ClosedAppLabels = New-Object System.Collections.Generic.List[string]

function Reset-ClosedAppLabels {
    $script:ClosedAppLabels = New-Object System.Collections.Generic.List[string]
}

function Add-ClosedAppLabel {
    param([string]$ProcessName)
    $label = $script:ProcessDisplayNames[$ProcessName]
    if (-not $label) { $label = $ProcessName }
    if ($script:ClosedAppLabels -notcontains $label) {
        [void]$script:ClosedAppLabels.Add($label)
    }
}

function Get-MyCleanPCBusyMessage {
    $closed = @($script:ClosedAppLabels)
    if ($closed.Count -eq 0) {
        return "Clearing browser and AI caches. You will get a notice when you can use those apps again."
    }
    $list = ($closed | Select-Object -First 4) -join ', '
    return "Temporarily closed $list so caches can be wiped. You will get a notice when you can use browsers and AI tools again."
}

function Get-MyCleanPCReadyMessage {
    $closed = @($script:ClosedAppLabels)
    if ($closed.Count -eq 0) {
        return "Scheduled cleanup is complete. You can now use your browsers and AI tools."
    }
    if ($closed.Count -eq 1) {
        return "Scheduled cleanup is complete. You can now use $($closed[0]) and your other browsers or AI tools."
    }
    if ($closed.Count -eq 2) {
        return "Scheduled cleanup is complete. You can now use $($closed[0]) and $($closed[1]) again."
    }
    $head = ($closed | Select-Object -First 3) -join ', '
    return "Scheduled cleanup is complete. You can now use $head, and your other browsers or AI tools."
}

function Show-MyCleanPCBalloon {
    param([string]$Title, [string]$Body)
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $icon = New-Object System.Windows.Forms.NotifyIcon
        $icon.Icon = [System.Drawing.SystemIcons]::Information
        $icon.Visible = $true
        $icon.BalloonTipTitle = $Title
        $icon.BalloonTipText = $Body
        $icon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
        $icon.ShowBalloonTip(20000)
        Start-Sleep -Milliseconds 800
        $icon.Visible = $false
        $icon.Dispose()
        return $true
    } catch {
        return $false
    }
}

function Show-MyCleanPCToast {
    param([string]$Title, [string]$Body)
    try {
        $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $escTitle = [System.Security.SecurityElement]::Escape($Title)
        $escBody = [System.Security.SecurityElement]::Escape($Body)
        $xmlText = @"
<toast duration="long">
  <visual>
    <binding template="ToastGeneric">
      <text>$escTitle</text>
      <text>$escBody</text>
    </binding>
  </visual>
  <audio src="ms-winsoundevent:Notification.Default" silent="false"/>
</toast>
"@
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($xmlText)
        # PowerShell's registered AppId so the toast appears from a hidden scheduled task.
        $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
        return $true
    } catch {
        return $false
    }
}

function Show-MyCleanPCNotice {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Body,
        [scriptblock]$Log = { param([string]$Message) }
    )
    & $Log "  [Notice] $Title — $Body"
    if ($env:MYCLEANPC_NO_TOAST -eq '1') { return }
    if (Show-MyCleanPCToast -Title $Title -Body $Body) { return }
    [void](Show-MyCleanPCBalloon -Title $Title -Body $Body)
}

function Close-AiToolProcesses {
    param([scriptblock]$Log = { param($m) })
    # Unlock AI caches. Do not stop Cursor/Code — this cleaner often runs from Cursor.
    $aiProcesses = @(
        "Kiro", "Windsurf", "Trae", "Antigravity", "Qoder", "warp",
        "Genspark", "ChatGPT", "Claude"
    )
    foreach ($procName in $aiProcesses) {
        try {
            $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
            if ($procs) {
                & $Log "  Closing $procName processes (unlock AI caches)..."
                Add-ClosedAppLabel $procName
                Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 1
            }
        } catch {}
    }
}

function Close-BrowserProcesses {
    param([scriptblock]$Log = { param($m) })
    $browserProcesses = @(
        "chrome", "msedge", "brave", "vivaldi", "opera", "yandexbrowser",
        "chromium", "arc", "wavebox", "sidekick", "centbrowser", "coccoc",
        "ucbrowser", "epicprivacybrowser", "gensparkbrowser",
        "firefox", "waterfox", "palemoon", "librewolf", "torbrowser", "basilisk"
    )
    foreach ($procName in $browserProcesses) {
        try {
            $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
            if ($procs) {
                & $Log "  Closing $procName processes..."
                Add-ClosedAppLabel $procName
                Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2  # Give processes time to close
            }
        } catch {}
    }
}

function Remove-SafePathWithRetry {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [switch]$Recurse,
        [int]$MaxRetries = 2
    )
    $attempt = 0
    $success = $false
    while ($attempt -le $MaxRetries -and -not $success) {
        $success = Remove-SafePath -LiteralPath $LiteralPath -Recurse:$Recurse
        if (-not $success -and $attempt -lt $MaxRetries) {
            Start-Sleep -Milliseconds 500
        }
        $attempt++
    }
    return $success
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
            Remove-SafePathWithRetry -LiteralPath $child.FullName -Recurse | Out-Null
        } else {
            Remove-SafePathWithRetry -LiteralPath $child.FullName | Out-Null
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
    if (Remove-PathViaDotNet -LiteralPath $LiteralPath -Recurse:$Recurse) { return $true }
    if (Remove-PathViaCmd -LiteralPath $LiteralPath -Recurse:$Recurse) { return $true }
    if (Test-Path -LiteralPath $LiteralPath) {
        Register-DeleteOnReboot -LiteralPath $LiteralPath
    }
    return $false
}

function Clear-SafeTempTree {
    # Combined del /f /s /q  +  Robocopy /MIR approach for Temp folders.
    #
    # Why two passes?
    #   Pass 1  - cmd "del /f /s /q path\*"
    #             Kills every unlocked file instantly (force, recurse, quiet).
    #             /f bypasses read-only; /s recurses subdirs; /q no confirmation.
    #             Completely bypasses the Explorer shell - zero dialogs.
    #             Locked files are silently skipped by cmd.exe (no dialog).
    #
    #   Pass 2  - Robocopy /MIR from an empty staging folder
    #             Wipes the remaining directory skeleton and any files
    #             that del couldn't reach (deep paths, unusual attributes).
    #             Also silent and dialog-free. Locked items are skipped.
    #
    #   Pass 3  - MoveFileEx DELAY_UNTIL_REBOOT
    #             Anything still present (genuinely locked by another process)
    #             is registered for silent deletion at the next Windows boot.
    param([string]$RootPath)
    $root = [System.Environment]::ExpandEnvironmentVariables($RootPath)
    if (-not (Test-Path $root)) { return 0 }
    $key = ([System.IO.Path]::GetFullPath($root)).TrimEnd('\').ToLowerInvariant()
    if ($script:ProcessedTempRoots.ContainsKey($key)) { return $script:ProcessedTempRoots[$key] }

    # Pass 1: del /f /s /q - fast file-kill, no Explorer shell, no dialogs
    $null = Invoke-ProcessAnswerAll -FilePath 'cmd.exe' `
        -ArgumentList @('/c', "del /f /s /q `"$root\*`"")

    # Pass 2: Robocopy /MIR - wipe remaining dirs and any files del skipped
    $removed = Clear-DirectoryViaRobocopy $root

    # Pass 3: register the temp root for next-boot deletion if still full of locked files
    if (@(Get-ChildItem -LiteralPath $root -Force -ErrorAction SilentlyContinue).Count -gt 0) {
        Register-DeleteOnReboot -LiteralPath $root
    }

    $script:ProcessedTempRoots[$key] = $removed
    return $removed
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
    $script:ProcessedTempRoots = @{}
    $fixed = @(
        "%TEMP%", "%LOCALAPPDATA%\Temp", "C:\Windows\Temp",
        "%LOCALAPPDATA%\CrashDumps", "%LOCALAPPDATA%\D3DSCache",
        "%LOCALAPPDATA%\Microsoft\Windows\WebCache",
        "%LOCALAPPDATA%\Microsoft\Windows\Burn\Burn"
    )
    foreach ($raw in $fixed) {
        $p = [System.Environment]::ExpandEnvironmentVariables($raw)
        if (Test-Path $p) {
            Clear-SafeTempTree $p | Out-Null
            & $OnItem $p
        }
    }
    $local = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%")
    Get-ChildItem $local -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        foreach ($n in @("Temp", "temp", "tmp", "Tmp")) {
            $tp = Join-Path $_.FullName $n
            if (Test-Path $tp) {
                Clear-SafeTempTree $tp | Out-Null
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
                if ($_.Name -in @('User Data', 'EBWebView', 'EdgeWebView', 'CefCache', 'DDGWebView', 'MyCleanPC', 'Packages')) { return }
                if (Test-JunkDirName $_.Name) {
                    # FIX: use Remove-DirectorySilent - robocopy wipe first,
                    # then cmd rd, then MoveFileEx reboot-delete fallback.
                    # Never routes through Explorer shell; zero "do this for all" dialogs.
                if (Remove-DirectorySilent -LiteralPath $child -KeepContainer) { $cleared++ }
                } elseif ($cur.Depth -lt 3) {
                    $stack.Push(@{ Path = $child; Depth = $cur.Depth + 1 })
                }
            }
        }
    }
    & $OnBatch $cleared
    return $cleared
}

function Clear-RoamingAppCachesAllApps {
    param(
        [scriptblock]$OnBatch = { param($Count) }
    )
    $root = [System.Environment]::ExpandEnvironmentVariables("%APPDATA%")
    if (-not (Test-Path $root)) { return 0 }

    $cacheNames = @(
        "Cache", "Caches", "CachedData", "Code Cache", "GPUCache", "Media Cache",
        "Temp", "Tmp", "tmp", "Logs", "Log", "crashpad", "CrashDumps",
        "blob_storage", "startupCache", "OfflineCache", "Application Cache"
    )
    $cleared = 0
    $stack = New-Object System.Collections.Stack
    foreach ($dir in @(Get-ChildItem $root -Directory -ErrorAction SilentlyContinue)) {
        $stack.Push(@{ Path = $dir.FullName; Depth = 0 })
    }

    while ($stack.Count -gt 0) {
        $cur = $stack.Pop()
        foreach ($child in @(Get-ChildItem $cur.Path -Directory -ErrorAction SilentlyContinue)) {
            if (Test-SkipCleanPath $child.FullName) { continue }
            if ($cacheNames -icontains $child.Name) {
                # FIX: use Remove-DirectorySilent - robocopy wipe first,
                # then cmd rd, then MoveFileEx reboot-delete fallback.
                # Never routes through Explorer shell; zero "do this for all" dialogs.
                if (Remove-DirectorySilent -LiteralPath $child.FullName -KeepContainer) { $cleared++ }
                continue
            }
            if ($cur.Depth -lt 7) {
                $stack.Push(@{ Path = $child.FullName; Depth = $cur.Depth + 1 })
            }
        }
    }

    & $OnBatch $cleared
    return $cleared
}

function Remove-CleanPaths {
    # Universal silent delete for all explicit paths.
    # Directories  -> Remove-DirectorySilent (del /f/s/q -> robocopy /MIR -> reboot-delete).
    #                Zero Explorer "Do this for all items" dialogs regardless of path.
    # Files        -> Remove-SafePathWithRetry (.NET delete -> cmd del -> reboot-delete).
    param([string[]]$Paths)
    foreach ($p in $Paths) {
        $exp = [System.Environment]::ExpandEnvironmentVariables($p)
        if (-not (Test-Path -LiteralPath $exp)) { continue }
        if (Test-Path -LiteralPath $exp -PathType Container) {
            Remove-DirectorySilent -LiteralPath $exp | Out-Null
        } else {
            Remove-SafePathWithRetry -LiteralPath $exp | Out-Null
        }
    }
}

# Non-browser apps / embedded WebViews that also use Chromium "Local State"
$script:BrowserDiscoveryExcludes = @(
    '\Cursor\', '\discord\', '\Discord\', '\Slack\', '\Teams\', '\Postman\',
    '\GitHub Desktop\', '\Notion\', '\Obsidian\', '\Spotify\', '\Zoom\',
    '\Antigravity\', '\Windsurf\', '\Qoder\', '\kiro\', '\Trae\', '\Devin\',
    '\electron\', '\Microsoft\Teams\', '\Code\',
    '\EBWebView\', '\EdgeWebView\', '\CefCache\', '\DDGWebView\', '\WebView2\',
    '\Packages\', '\INetCache\', '\Temp\'
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
    # Opera-style: the "User Data" folder itself is the profile
    if (Test-Path -LiteralPath (Join-Path $Path 'Cache') -PathType Container) { return $true }
    return $false
}

function Find-ChromiumBrowserRoots {
    $found = @{}
    foreach ($root in @(Get-KnownChromiumUserDataRoots)) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        if (Test-BrowserDiscoveryExcluded $root) { continue }
        if (-not (Test-ChromiumUserDataRoot $root)) { continue }
        $key = $root.ToLowerInvariant()
        if (-not $found.ContainsKey($key)) { $found[$key] = $root }
    }
    return @($found.Values | Sort-Object)
}

function Find-GeckoBrowserProfileDirs {
    $found = @{}
    $known = @(
        @{ Name = 'Mozilla\Firefox'; Path = "$env:APPDATA\Mozilla\Firefox\Profiles" },
        @{ Name = 'Waterfox'; Path = "$env:APPDATA\Waterfox\Profiles" },
        @{ Name = 'LibreWolf'; Path = "$env:APPDATA\librewolf\Profiles" },
        @{ Name = 'Pale Moon'; Path = "$env:APPDATA\Moonchild Productions\Pale Moon\Profiles" }
    )
    foreach ($g in $known) {
        if (-not (Test-Path $g.Path)) { continue }
        $key = $g.Path.ToLowerInvariant()
        if (-not $found.ContainsKey($key)) { $found[$key] = $g }
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
    "Cache", "Cache\Cache_Data", "Code Cache", "GPUCache", "Media Cache", "blob_storage",
    "Service Worker", "Service Worker\CacheStorage", "Service Worker\ScriptCache",
    "Local Storage", "IndexedDB", "Session Storage", "Application Cache",
    "File System", "DawnCache", "DawnWebGPUCache", "DawnGraphiteCache",
    "GrShaderCache", "ShaderCache", "Shared Dictionary",
    "optimization_guide_hint_cache_store"
)
$script:ChromiumCleanFiles = @(
    "Cookies", "Cookies-journal", "History", "History-journal",
    "Visited Links", "Top Sites", "Top Sites-journal",
    "Shortcuts", "Shortcuts-journal", "Network Action Predictor",
    "Favicons", "Favicons-journal",
    "Extension Cookies", "QuotaManager", "Reporting and NEL", "Reporting and NEL-journal"
)
$script:GeckoCleanDirs = @(
    "cache2", "startupCache", "OfflineCache", "thumbnails", "jumpListCache",
    "storage\default"
)
$script:GeckoCleanFiles = @(
    "cookies.sqlite", "cookies.sqlite-shm", "cookies.sqlite-wal",
    "favicons.sqlite", "favicons.sqlite-shm", "favicons.sqlite-wal",
    "webappsstore.sqlite", "content-prefs.sqlite", "permissions.sqlite",
    "sessionCheckpoints.json"
)

function Clear-ChromiumBrowserCache {
    param([string]$UserDataPath)
    $base = [System.Environment]::ExpandEnvironmentVariables($UserDataPath)
    if (-not (Test-Path $base)) { return }

    foreach ($d in @('GrShaderCache', 'ShaderCache', 'GraphiteDawnCache')) {
        $target = Join-Path $base $d
        if (Test-Path -LiteralPath $target -PathType Container) {
            Remove-DirectorySilent -LiteralPath $target -KeepContainer | Out-Null
        }
    }

    $profileDirs = @(Get-ChildItem $base -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq 'Default' -or $_.Name -like 'Profile *' -or $_.Name -eq 'Guest Profile' })
    if ($profileDirs.Count -eq 0) { $profileDirs = @(Get-Item -LiteralPath $base) }

    foreach ($prof in $profileDirs) {
        $profile = $prof.FullName
        foreach ($d in $script:ChromiumCleanDirs) {
            $target = Join-Path $profile $d
            if (Test-Path -LiteralPath $target -PathType Container) {
                Remove-DirectorySilent -LiteralPath $target -KeepContainer | Out-Null
            } elseif (Test-Path -LiteralPath $target) {
                Remove-SafePathWithRetry -LiteralPath $target | Out-Null
            }
        }
        foreach ($f in $script:ChromiumCleanFiles) {
            Remove-SafePathWithRetry -LiteralPath (Join-Path $profile $f) | Out-Null
        }
        $networkCookies = Join-Path $profile 'Network\Cookies'
        if (Test-Path -LiteralPath $networkCookies) {
            Remove-SafePathWithRetry -LiteralPath $networkCookies | Out-Null
            Remove-SafePathWithRetry -LiteralPath ($networkCookies + '-journal') | Out-Null
        }
        # Login Data + Web Data intentionally SKIPPED (passwords and autofill safe)
    }
}

function Clear-GeckoBrowserProfiles {
    param([string]$ProfilesPath)
    if (-not (Test-Path $ProfilesPath)) { return }
    Get-ChildItem $ProfilesPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $p = $_.FullName
        foreach ($d in $script:GeckoCleanDirs) {
            $target = Join-Path $p $d
            if (Test-Path -LiteralPath $target -PathType Container) {
                Remove-DirectorySilent -LiteralPath $target -KeepContainer | Out-Null
            } elseif (Test-Path -LiteralPath $target) {
                Remove-SafePathWithRetry -LiteralPath $target | Out-Null
            }
        }
        foreach ($f in $script:GeckoCleanFiles) {
            Remove-SafePathWithRetry -LiteralPath (Join-Path $p $f) | Out-Null
        }
        # key4.db, formhistory.sqlite, and places.sqlite intentionally SKIPPED
        # to protect passwords, autofill, and bookmarks.
    }
}

function Clear-FirefoxProfiles {
    Clear-GeckoBrowserProfiles ([System.Environment]::ExpandEnvironmentVariables("%APPDATA%\Mozilla\Firefox\Profiles"))
}

function Clear-AllInstalledBrowsers {
    param([scriptblock]$Log = { param([string]$Message) })

    & $Log "  Closing browser processes (to unlock files)..."
    Close-BrowserProcesses -Log $Log

    & $Log "  Scanning PC for all installed browsers..."
    $chromiumRoots = Find-ChromiumBrowserRoots
    $geckoBrowsers = Find-GeckoBrowserProfileDirs
    $count = $chromiumRoots.Count + $geckoBrowsers.Count

    if ($count -eq 0) {
        & $Log "  No browser profile folders found on this PC."
        return @{ Chromium = 0; Gecko = 0; Total = 0 }
    }

    & $Log "  Found $count browser profile location(s)."
    & $Log "  Cleaning: cache, cookies, history/site data where safe (like Ctrl+Shift+Delete)."
    & $Log "  Auto-skip: passwords, autofill, bookmarks, locked files - no prompts."

    foreach ($root in $chromiumRoots) {
        $label = Get-BrowserLabelFromPath $root
        $started = Get-Date
        & $Log "  -> $label  ($root)"
        Clear-ChromiumBrowserCache $root
        $secs = [int]((Get-Date) - $started).TotalSeconds
        $cacheLeft = 0
        $defaultCache = Join-Path $root 'Default\Cache'
        if (Test-Path -LiteralPath $defaultCache) {
            $cacheLeft = @(Get-ChildItem -LiteralPath $defaultCache -Force -ErrorAction SilentlyContinue).Count
        }
        & $Log "     done in ${secs}s; leftover Default\\Cache entries: $cacheLeft"
    }
    foreach ($g in $geckoBrowsers) {
        $label = Get-GeckoBrowserLabel $g.Name
        $started = Get-Date
        & $Log "  -> $label  ($($g.Path))"
        Clear-GeckoBrowserProfiles $g.Path
        $secs = [int]((Get-Date) - $started).TotalSeconds
        & $Log "     done in ${secs}s"
    }

    & $Log "  [All Browsers] cleared. Passwords and autofill NOT touched."
    return @{ Chromium = $chromiumRoots.Count; Gecko = $geckoBrowsers.Count; Total = $count }
}

function Clear-StoreAppTemp {
    $pkgs = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Packages")
    if (-not (Test-Path $pkgs)) { return }
    Get-ChildItem $pkgs -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $at = Join-Path $_.FullName "AC\Temp"
        $cn = Join-Path $_.FullName "AC\Microsoft\CryptnetUrlCache"
        # FIX: use Remove-DirectorySilent - robocopy wipe, then cmd rd, then reboot-delete fallback
        if (Test-Path $at) { Remove-DirectorySilent -LiteralPath $at | Out-Null }
        if (Test-Path $cn) { Remove-DirectorySilent -LiteralPath $cn | Out-Null }
    }
}

function Test-CleanMgrCategorySelected {
    param([Parameter(Mandatory)][string]$Name)
    if ($Name -match '(?i)download') { return $false }
    return $true
}

function Set-CleanMgrPreset {
    param(
        [int]$PresetId = 7142,
        [scriptblock]$Log = { param([string]$Message) }
    )
    $root = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
    if (-not (Test-Path $root)) { return $false }

    $valueName = ('StateFlags{0:d4}' -f $PresetId)
    $selected = 0
    $excluded = @()

    foreach ($key in @(Get-ChildItem $root -ErrorAction SilentlyContinue)) {
        $name = $key.PSChildName
        $shouldSelect = Test-CleanMgrCategorySelected -Name $name
        $value = if ($shouldSelect) { 2 } else { 0 }
        try {
            New-ItemProperty -Path $key.PSPath -Name $valueName -Value $value -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            if ($shouldSelect) { $selected++ } else { $excluded += $name }
        } catch {
            & $Log "  [Disk Cleanup] skipped (admin rights required to preset CleanMgr)."
            return $false
        }
    }

    if ($excluded.Count -gt 0) {
        & $Log ("  [Disk Cleanup] excluded download category/categories: " + ($excluded -join ', '))
    }
    & $Log "  [Disk Cleanup] preset ready ($selected categories selected)."
    return $true
}

function Invoke-CleanMgrSilent {
    param(
        [string]$Drive = $env:SystemDrive,
        [int]$PresetId = 7142,
        [scriptblock]$Log = { param([string]$Message) }
    )
    $cleanMgr = Join-Path $env:SystemRoot 'System32\cleanmgr.exe'
    if (-not (Test-Path $cleanMgr)) {
        & $Log "  [Disk Cleanup] skipped (cleanmgr.exe not found on this Windows install)."
        return $false
    }
    if (-not (Set-CleanMgrPreset -PresetId $PresetId -Log $Log)) { return $false }

    $targetDrive = if ($Drive) { $Drive.TrimEnd('\') } else { 'C:' }
    & $Log "  [Disk Cleanup] running CleanMgr on $targetDrive with no selection prompts."
    try {
        $proc = Start-Process -FilePath $cleanMgr -ArgumentList @('/d', $targetDrive, "/sagerun:$PresetId") `
            -WindowStyle Hidden -PassThru -ErrorAction Stop
        if (-not $proc.WaitForExit(1800000)) {
            try { $proc.Kill() } catch {}
            & $Log "  [Disk Cleanup] timed out after 30 minutes; continuing."
            return $false
        }
        & $Log "  [Disk Cleanup] completed. Downloads categories were NOT selected."
        return $true
    } catch {
        & $Log "  [Disk Cleanup] skipped (CleanMgr could not start)."
        return $false
    }
}

function Invoke-MyCleanPCCore {
    param(
        [scriptblock]$Log = { param([string]$Message) Write-Host $Message },
        [switch]$ManageWindowsUpdateService
    )

    # Snapshot free space on the system drive before anything is deleted.
    # We re-read it at the end and report the difference as "space freed".
    $sysDrive    = $env:SystemDrive
    $freeAtStart = Get-DriveFreeBytes $sysDrive

    # -- PRE-SCAN ------------------------------------------------------------
    # Read-only size measurement of everything that will be cleaned.
    # Gives the user a "you're about to free ~X GB" preview before we start.
    & $Log "-- PRE-SCAN: measuring junk (read-only, nothing deleted yet) --"
    $estimate  = Get-CleanupEstimate
    $estStr    = Format-ByteSize $estimate.TotalBytes
    $estCount  = $estimate.Count
    & $Log "  Estimated junk found:  $estStr across $estCount locations"
    foreach ($hit in $estimate.Top5) {
        $label = ([string]$hit.ShortLabel).PadRight(28)
        & $Log "    $label  $(Format-ByteSize ([long]$hit.Bytes))"
    }
    & $Log "PRESCAN_ESTIMATE:$estStr"   # machine-readable sentinel for GUI
    & $Log ""

    # AI + browsers first so the 6-hour task cannot burn its time limit on temp/AppData walks.
    Reset-ClosedAppLabels
    & $Log "-- STEP 1: AI App Caches --"
    Close-AiToolProcesses -Log $Log
    Close-BrowserProcesses -Log $Log
    Show-MyCleanPCNotice -Title "My Clean PC is cleaning caches" -Body (Get-MyCleanPCBusyMessage) -Log $Log
    $aiCleared = 0
    $aiTargets = @(Get-AiCacheTargetPaths)
    if ($aiTargets.Count -eq 0) {
        & $Log "  No AI cache folders found on this PC."
    }
    foreach ($raw in $aiTargets) {
        $exp = [System.Environment]::ExpandEnvironmentVariables($raw)
        if (-not (Test-Path -LiteralPath $exp)) { continue }
        & $Log "  -> $exp"
        if (Test-Path -LiteralPath $exp -PathType Container) {
            if (Remove-DirectorySilent -LiteralPath $exp -KeepContainer) { $aiCleared++ }
            $left = @(Get-ChildItem -LiteralPath $exp -Force -ErrorAction SilentlyContinue).Count
            if ($left -gt 0) {
                & $Log "     leftover items still locked: $left"
            }
        } else {
            if (Remove-SafePathWithRetry -LiteralPath $exp) { $aiCleared++ }
        }
    }
    & $Log "  [AI App Caches] cleared ($aiCleared cache folders wiped). Settings and chats NOT touched."

    & $Log "-- STEP 2: All Installed Browsers (auto-detect, passwords SAFE) --"
    Clear-AllInstalledBrowsers -Log $Log | Out-Null

    & $Log "-- STEP 3: Temporary Files + Recycle Bin --"
    & $Log "  (Robocopy bulk clear - zero Explorer prompts; locked files auto-skip)"
    Clear-RigorousTempLocations
    $localCount = Clear-AppDataJunkSweep "%LOCALAPPDATA%"
    $roamCount  = Clear-AppDataJunkSweep "%APPDATA%"
    & $Log "  [Rigorous Temp + AppData] cleared ($localCount local + $roamCount roaming junk folders)."
    try { Clear-RecycleBinSilent } catch {}
    & $Log "  [Recycle Bin] emptied."

    & $Log "-- STEP 4: Prefetch (Quick Access / Recent folder NOT touched) --"
    foreach ($pf in @(Get-ChildItem "C:\Windows\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue)) {
        Remove-SafePathWithRetry -LiteralPath $pf.FullName | Out-Null
    }
    & $Log "  [Prefetch] cleared. Quick Access pins and Recent folder left intact."

    & $Log "-- STEP 5: Windows Disk Cleanup (C: drive, Downloads excluded) --"
    Invoke-CleanMgrSilent -Drive 'C:' -Log $Log | Out-Null

    & $Log "-- STEP 6: Windows Update Cache + Store Temp + INetCache --"

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

    # FIX: INetCache cleared via robocopy wipe first, then remove empty shell.
    # Avoids Explorer "do this for all items" dialog for locked IE/Edge cache files.
    $inetCache = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Microsoft\Windows\INetCache")
    if (Test-Path $inetCache) {
        Clear-DirectoryViaRobocopy $inetCache | Out-Null
        Remove-PathViaCmd -LiteralPath $inetCache -Recurse | Out-Null
    }
    & $Log "  [INetCache] cleared."

    $explorerCache = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Microsoft\Windows\Explorer")
    if (Test-Path $explorerCache) {
        foreach ($thumb in @(Get-ChildItem $explorerCache -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue)) {
            Remove-SafePathWithRetry -LiteralPath $thumb.FullName | Out-Null
        }
        foreach ($icon in @(Get-ChildItem $explorerCache -Filter "iconcache_*.db" -ErrorAction SilentlyContinue)) {
            Remove-SafePathWithRetry -LiteralPath $icon.FullName | Out-Null
        }
    }
    & $Log "  [Thumbnail / Icon cache] cleared."

    & $Log "-- STEP 7: Event Logs and DNS Cache --"
    foreach ($logName in @("Application", "System", "Security", "Setup")) {
        try { wevtutil cl $logName 2>&1 | Out-Null } catch {}
        & $Log "  [Event Log: $logName] cleared."
    }
    try { Clear-DnsClientCache -ErrorAction Stop } catch { ipconfig /flushdns | Out-Null }
    & $Log "  [DNS Cache] flushed."

    # ---- Space-freed summary --------------------------------------------
    # Re-read drive free space and compute what was actually reclaimed.
    # DriveInfo reflects real filesystem state after all deletions.
    $freeAtEnd   = Get-DriveFreeBytes $sysDrive
    $totalFreed  = [Math]::Max(0, $freeAtEnd - $freeAtStart)
    $freedStr    = Format-ByteSize $totalFreed

    $comparison = Format-ByteComparison $totalFreed

    & $Log ""
    & $Log "============================================"
    & $Log "  Space freed this run:  $freedStr"
    if ($comparison) {
    & $Log "  $comparison"
    }
    & $Log "FREED_BYTES:$totalFreed"   # machine-readable sentinel for GUI
    & $Log "============================================"
    & $Log "THANKS CODEX FOR UR CLEAN PC"
    Show-MyCleanPCNotice -Title "You can use browsers and AI tools now" -Body (Get-MyCleanPCReadyMessage) -Log $Log
}
