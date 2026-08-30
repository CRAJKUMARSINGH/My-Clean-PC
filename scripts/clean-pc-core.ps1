# My Clean PC - shared cleaning core (single source of truth)
# Dot-source from my-clean-pc.ps1, cleanup_task.ps1, etc.
# Passwords (Login Data, key4.db), autofill data, Downloads, and Quick Access pins are NEVER touched.

$ErrorActionPreference = "SilentlyContinue"
$ConfirmPreference = "None"
$ProgressPreference = "SilentlyContinue"

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
    param([long]$Bytes)
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

    # AI dev-tool caches
    $aiMap = @{
        '%APPDATA%\kiro'              = 'Kiro (Roaming)'
        '%LOCALAPPDATA%\kiro'         = 'Kiro (Local)'
        '%APPDATA%\Cursor\Cache'      = 'Cursor Cache'
        '%APPDATA%\Cursor\CachedData' = 'Cursor CachedData'
        '%LOCALAPPDATA%\cursor-updater' = 'Cursor Updater'
        '%APPDATA%\Windsurf\Cache'    = 'Windsurf Cache'
        '%LOCALAPPDATA%\Windsurf'     = 'Windsurf Local'
        '%APPDATA%\Trae'              = 'Trae'
        '%APPDATA%\warp'              = 'Warp'
        '%APPDATA%\Genspark'          = 'Genspark'
    }
    foreach ($kv in $aiMap.GetEnumerator()) {
        AddHit ([System.Environment]::ExpandEnvironmentVariables($kv.Key)) $kv.Value
    }

    # Common browser caches (Chromium-family)
    $chromiumRoots = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data",
        "$env:LOCALAPPDATA\Vivaldi\User Data"
    )
    foreach ($root in $chromiumRoots) {
        if (-not (Test-Path $root)) { continue }
        $appName = (Split-Path $root -Parent | Split-Path -Leaf)
        foreach ($cache in @(Get-ChildItem $root -Recurse -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -in @('Cache','Code Cache','GPUCache') } |
                Select-Object -First 4)) {
            AddHit $cache.FullName "$appName Cache"
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

    $sorted = $hits | Sort-Object { $_.Bytes } -Descending
    $total  = [long]($hits | Measure-Object -Property Bytes -Sum).Sum

    return @{
        TotalBytes = $total
        Count      = $hits.Count
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
    return "That's like $("{0:N0}" -f ($Bytes / 1GB * 250) | [Math]::Round) songs"
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
        foreach ($arg in $ArgumentList) { [void]$psi.ArgumentList.Add($arg) }
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
    try {
        New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
        if ($emptyDir.StartsWith($targetNorm, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Staging dir must not be inside target"
        }
        $before = @(Get-ChildItem $TargetPath -Force -ErrorAction SilentlyContinue).Count
        foreach ($child in @(Get-ChildItem $TargetPath -Force -ErrorAction SilentlyContinue)) {
            if (Test-SkipCleanPath $child.FullName) { continue }
            if (Remove-SafePathWithRetry -LiteralPath $child.FullName -Recurse) {
                $removed++
            }
        }
        $null = & robocopy.exe $emptyDir $TargetPath /mir /r:0 /w:0 /nfl /ndl /njh /njs /nc /ns /np 2>&1
        $after = @(Get-ChildItem $TargetPath -Force -ErrorAction SilentlyContinue).Count
        $removed = [Math]::Max($removed, [Math]::Max(0, $before - $after))
        if ($after -gt 0) {
            foreach ($child in @(Get-ChildItem $TargetPath -Force -ErrorAction SilentlyContinue)) {
                if (Remove-SafePathWithRetry -LiteralPath $child.FullName -Recurse) {
                    $removed++
                } elseif (Test-Path -LiteralPath $child.FullName) {
                    Register-DeleteOnReboot -LiteralPath $child.FullName
                }
            }
        }
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
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (Test-SkipCleanPath $LiteralPath) { return $false }
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Container)) { return $false }

    # Stage 1: Robocopy wipe - zero Explorer dialogs, locked files silently skipped
    Clear-DirectoryViaRobocopy $LiteralPath | Out-Null

    # Stage 2: Remove the (now mostly/fully empty) directory shell via cmd
    Remove-PathViaCmd -LiteralPath $LiteralPath -Recurse | Out-Null

    # Stage 3: If anything is still stuck (locked), register for next-boot deletion
    if (Test-Path -LiteralPath $LiteralPath) {
        foreach ($item in @(Get-ChildItem -LiteralPath $LiteralPath -Force -Recurse -ErrorAction SilentlyContinue)) {
            Register-DeleteOnReboot -LiteralPath $item.FullName
        }
        Register-DeleteOnReboot -LiteralPath $LiteralPath
        return $false
    }
    return $true
}

function Close-BrowserProcesses {
    param([scriptblock]$Log = { param($m) })
    $browserProcesses = @(
        "chrome", "msedge", "brave", "vivaldi", "opera", "yandexbrowser",
        "chromium", "arc", "wavebox", "sidekick", "centbrowser", "coccoc",
        "ucbrowser", "epicprivacybrowser", "gensparkbrowser", "firefox",
        "waterfox", "palemoon", "librewolf", "torbrowser", "basilisk", "thunderbird"
    )
    foreach ($procName in $browserProcesses) {
        try {
            $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
            if ($procs) {
                & $Log "  Closing $procName processes..."
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

    # Pass 3: register any still-locked stragglers for next-boot deletion
    foreach ($stuck in @(Get-ChildItem -LiteralPath $root -Force -Recurse -ErrorAction SilentlyContinue)) {
        Register-DeleteOnReboot -LiteralPath $stuck.FullName
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
                if (Test-JunkDirName $_.Name) {
                    # FIX: use Remove-DirectorySilent - robocopy wipe first,
                    # then cmd rd, then MoveFileEx reboot-delete fallback.
                    # Never routes through Explorer shell; zero "do this for all" dialogs.
                    if (Remove-DirectorySilent -LiteralPath $child) { $cleared++ }
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
                if (Remove-DirectorySilent -LiteralPath $child.FullName) { $cleared++ }
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
    "Favicons", "Favicons-journal",
    "Extension Cookies", "QuotaManager", "Reporting and NEL", "Reporting and NEL-journal"
)
$script:GeckoCleanDirs = @("cache2", "startupCache", "OfflineCache", "thumbnails", "storage", "jumpListCache")
$script:GeckoCleanFiles = @(
    "cookies.sqlite", "cookies.sqlite-shm", "cookies.sqlite-wal",
    "downloads.sqlite", "favicons.sqlite", "favicons.sqlite-shm", "favicons.sqlite-wal",
    "webappsstore.sqlite", "content-prefs.sqlite", "permissions.sqlite",
    "sessionCheckpoints.json"
)

function Clear-ChromiumBrowserCache {
    param([string]$UserDataPath)
    $base = [System.Environment]::ExpandEnvironmentVariables($UserDataPath)
    if (-not (Test-Path $base)) { return }

    Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $profile = $_.FullName
        foreach ($d in $script:ChromiumCleanDirs) {
            $target = Join-Path $profile $d
            if (Test-Path -LiteralPath $target -PathType Container) {
                # FIX: robocopy wipe first - zero Explorer dialogs for locked browser cache files
                Remove-DirectorySilent -LiteralPath $target | Out-Null
            } elseif (Test-Path -LiteralPath $target) {
                Remove-SafePathWithRetry -LiteralPath $target | Out-Null
            }
        }
        foreach ($f in $script:ChromiumCleanFiles) {
            Remove-SafePathWithRetry -LiteralPath (Join-Path $profile $f) | Out-Null
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
                # FIX: robocopy wipe first - zero Explorer dialogs for locked Firefox cache files
                Remove-DirectorySilent -LiteralPath $target | Out-Null
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
        & $Log "  -> $label"
        Clear-ChromiumBrowserCache $root
    }
    foreach ($g in $geckoBrowsers) {
        $label = Get-GeckoBrowserLabel $g.Name
        & $Log "  -> $label"
        Clear-GeckoBrowserProfiles $g.Path
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
        $label = $hit.ShortLabel.PadRight(28)
        & $Log "    $label  $(Format-ByteSize $hit.Bytes)"
    }
    & $Log "PRESCAN_ESTIMATE:$estStr"   # machine-readable sentinel for GUI
    & $Log ""

    & $Log "-- STEP 1: AI App Caches --"
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
    & $Log "  [AI App Caches] cleared."

    & $Log "-- STEP 2: All Installed Browsers (auto-detect, passwords SAFE) --"
    Clear-AllInstalledBrowsers -Log $Log | Out-Null

    & $Log "-- STEP 3: Prefetch (Quick Access / Recent folder NOT touched) --"
    foreach ($pf in @(Get-ChildItem "C:\Windows\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue)) {
        Remove-SafePathWithRetry -LiteralPath $pf.FullName | Out-Null
    }
    & $Log "  [Prefetch] cleared. Quick Access pins and Recent folder left intact."

    & $Log "-- STEP 4: Temporary Files + Rigorous AppData --"
    & $Log "  (Robocopy bulk clear - zero Explorer prompts; locked files auto-skip)"
    Clear-RigorousTempLocations
    $localCount = Clear-AppDataJunkSweep "%LOCALAPPDATA%"
    $roamCount = Clear-AppDataJunkSweep "%APPDATA%"
    & $Log "  [Rigorous Temp + AppData] cleared ($localCount local + $roamCount roaming junk folders)."

    & $Log "-- STEP 5: Windows Disk Cleanup (C: drive, Downloads excluded) --"
    Invoke-CleanMgrSilent -Drive 'C:' -Log $Log | Out-Null

    & $Log "-- STEP 6: Recycle Bin and Update Cache --"
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
}
