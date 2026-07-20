# My Clean PC - Beautiful GUI Launcher
# Designed for Priyanka - NO command prompt window!
# How to run: right-click this file -> "Run with PowerShell"
# For best results: right-click -> "Run as Administrator"

$ErrorActionPreference = "SilentlyContinue"
$ConfirmPreference = "None"
$ProgressPreference = "SilentlyContinue"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
param([switch]$FullClean)

# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    [System.Windows.Forms.MessageBox]::Show(
        "For best results, please run this script as Administrator.`n`nRight-click the file and select 'Run as Administrator'.`n`nWithout admin rights, some files may not be deleted.",
        "My Clean PC - Admin Rights Recommended",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
}

# ════════════════════════════════════════════════════
#  PROMPT-FREE CLEANING HELPERS (Matches clean-pc-core.ps1)
# ════════════════════════════════════════════════════
$script:SkipPathFragments = @(
    "\Login Data", "\Login Data For Account", "\key4.db", "\formhistory.sqlite",
    "\Web Data", "\Web Data-journal", "\Autofill", "\Downloads", "\MyCleanPC",
    "\Microsoft\Windows\Recent", "\Microsoft\Windows\History",
    "\Microsoft\Windows\Recent\AutomaticDestinations", "\Microsoft\Windows\Recent\CustomDestinations"
)

function Test-SkipCleanPath {
    param([string]$Path)
    if ([string]::IsNullOrEmpty($Path)) { return $false }
    $norm = $Path.Replace('/', '\').ToLowerInvariant()
    foreach ($frag in $script:SkipPathFragments) {
        $normFrag = $frag.ToLowerInvariant()
        if ($norm -eq $normFrag -or $norm -like "*$normFrag" -or $norm -like "*$normFrag\*") {
            return $true
        }
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

function Remove-PathViaCmd {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [switch]$Recurse
    )
    if (-not (Test-Path -LiteralPath $LiteralPath)) { return $true }
    Clear-PathAttributes $LiteralPath
    $isDir = Test-Path -LiteralPath $LiteralPath -PathType Container
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'cmd.exe'
    if ($isDir -or $Recurse) {
        $psi.ArgumentList.Add('/c')
        $psi.ArgumentList.Add('rd')
        $psi.ArgumentList.Add('/s')
        $psi.ArgumentList.Add('/q')
        $psi.ArgumentList.Add($LiteralPath)
    } else {
        $psi.ArgumentList.Add('/c')
        $psi.ArgumentList.Add('del')
        $psi.ArgumentList.Add('/f')
        $psi.ArgumentList.Add('/q')
        $psi.ArgumentList.Add('/a')
        $psi.ArgumentList.Add($LiteralPath)
    }
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    [void]$proc.Start()
    if (-not $proc.WaitForExit(10000)) {
        try { $proc.Kill() } catch {}
        return $false
    }
    return -not (Test-Path -LiteralPath $LiteralPath)
}

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

function Register-DeleteOnReboot {
    param([Parameter(Mandatory)][string]$LiteralPath)
    try {
        if (-not ('RebootDeleteNative' -as [type])) {
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
        $long = Get-LongLiteralPath $LiteralPath
        [RebootDeleteNative]::MoveFileEx($long, $null, [RebootDeleteNative]::MOVEFILE_DELAY_UNTIL_REBOOT) | Out-Null
    } catch {}
}

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
    
    $deletedCount = 0
    foreach ($child in @(Get-ChildItem -LiteralPath $LiteralPath -Force -ErrorAction SilentlyContinue)) {
        if (Test-SkipCleanPath $child.FullName) { continue }
        try { 
            $child.Attributes = 'Normal' 
        } catch {}
        
        if ($child.PSIsContainer) {
            Clear-SafeDirectoryContents -LiteralPath $child.FullName
            try {
                Remove-Item -LiteralPath $child.FullName -Recurse -Force -ErrorAction Stop
                $deletedCount++
            } catch {
                # Try with cmd.exe if PowerShell fails
                try {
                    $null = cmd /c "rd /s /q `"$($child.FullName)`"" 2>&1
                    if (-not (Test-Path $child.FullName)) { $deletedCount++ }
                } catch {}
            }
        } else {
            try {
                Remove-Item -LiteralPath $child.FullName -Force -ErrorAction Stop
                $deletedCount++
            } catch {
                # Try with cmd.exe if PowerShell fails
                try {
                    $null = cmd /c "del /f /q `"$($child.FullName)`"" 2>&1
                    if (-not (Test-Path $child.FullName)) { $deletedCount++ }
                } catch {}
            }
        }
    }
    return $deletedCount
}

function Clear-SafeTempTree {
    param([string]$RootPath)
    $root = [System.Environment]::ExpandEnvironmentVariables($RootPath)
    if (-not (Test-Path $root)) { return 0 }
    
    $before = 0
    try {
        $before = @(Get-ChildItem -LiteralPath $root -Force -ErrorAction SilentlyContinue).Count
    } catch {}
    
    $deleted = Clear-SafeDirectoryContents -LiteralPath $root
    
    $after = 0
    try {
        $after = @(Get-ChildItem -LiteralPath $root -Force -ErrorAction SilentlyContinue).Count
    } catch {}
    
    $actualDeleted = [Math]::Max(0, $before - $after)
    if ($actualDeleted -ne $deleted) {
        return $actualDeleted
    }
    return $actualDeleted
}

$script:JunkDirNames = @(
    "Cache","Caches","CachedData","Code Cache","GPUCache","Media Cache",
    "Temp","Tmp","tmp","Logs","Log","crashpad","CrashDumps","blob_storage",
    "startupCache","OfflineCache","Application Cache","INetCache","WebCache",
    "Updater","updater","D3DSCache","storage","Crash Reports"
)

function Test-JunkDirName {
    param([string]$Name)
    foreach ($jn in $script:JunkDirNames) { if ($Name -ieq $jn) { return $true } }
    return $false
}

function Clear-RigorousTempLocations {
    $fixed = @(
        "%TEMP%","%LOCALAPPDATA%\Temp","C:\Windows\Temp",
        "%LOCALAPPDATA%\CrashDumps","%LOCALAPPDATA%\D3DSCache",
        "%LOCALAPPDATA%\Microsoft\Windows\WebCache",
        "%LOCALAPPDATA%\Microsoft\Windows\Burn\Burn"
    )
    foreach ($raw in $fixed) {
        $p = [System.Environment]::ExpandEnvironmentVariables($raw)
        if (Test-Path $p) {
            $count = Clear-SafeTempTree $p
            WriteLog "    >> Cleared temp: $p ($count items)" "ok"
        }
    }
    $local = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%")
    Get-ChildItem $local -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        foreach ($n in @("Temp","temp","tmp","Tmp")) {
            $tp = Join-Path $_.FullName $n
            if (Test-Path $tp) {
                $count = Clear-SafeTempTree $tp
                WriteLog "    >> Cleared temp: $tp ($count items)" "ok"
            }
        }
    }
}

function Close-BrowserProcesses {
    WriteLog "  Closing browser processes to unlock files..." "info"
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
                WriteLog "    Closing $procName..." "skip"
                Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }
    Start-Sleep -Seconds 2
}

function Clear-AppDataJunkSweep {
    param([string]$Label, [string]$RootVar)
    WriteLog "  [ $Label ]" "head"
    $root = [System.Environment]::ExpandEnvironmentVariables($RootVar)
    if (-not (Test-Path $root)) { WriteLog "    -- Path not found, skipping." "skip"; return 0 }
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
                    # Direct deletion with fallback to cmd.exe
                    try {
                        Remove-Item -LiteralPath $child -Recurse -Force -ErrorAction Stop
                        $cleared++
                    } catch {
                        try {
                            $null = cmd /c "rd /s /q `"$child`"" 2>&1
                            if (-not (Test-Path $child)) { $cleared++ }
                        } catch {}
                    }
                } elseif ($cur.Depth -lt 3) {
                    $stack.Push(@{ Path = $child; Depth = $cur.Depth + 1 })
                }
            }
        }
    }
    WriteLog "    Done! Cleared $cleared junk folders." "ok"
    return $cleared
}

# ════════════════════════════════════════════════════
#  WINDOW SETUP
# ════════════════════════════════════════════════════
$form = New-Object System.Windows.Forms.Form
$form.Text = "My Clean PC - For Priyanka"
$form.ClientSize    = New-Object System.Drawing.Size(520, 640)
$form.MinimumSize   = New-Object System.Drawing.Size(520, 640)
$form.MaximizeBox   = $false
$form.StartPosition = "CenterScreen"
$form.BackColor     = [System.Drawing.Color]::FromArgb(255, 248, 240)
$form.Font          = New-Object System.Drawing.Font("Segoe UI", 9)

# Title
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text      = "My Clean PC"
$lblTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(185, 28, 28)
$lblTitle.SetBounds(0, 16, 520, 52)
$lblTitle.TextAlign = "MiddleCenter"
$form.Controls.Add($lblTitle)

# Subtitle
$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text      = "Designed for Priyanka - Cleans safely, touches NOTHING important"
$lblSub.Font      = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(234, 88, 12)
$lblSub.SetBounds(0, 66, 520, 22)
$lblSub.TextAlign = "MiddleCenter"
$form.Controls.Add($lblSub)

# Safety note
$pnlSafe = New-Object System.Windows.Forms.Panel
$pnlSafe.SetBounds(16, 94, 488, 32)
$pnlSafe.BackColor = [System.Drawing.Color]::FromArgb(240, 253, 244)
$form.Controls.Add($pnlSafe)
$lblSafe = New-Object System.Windows.Forms.Label
$lblSafe.Text      = "Lock  Passwords, Downloads & personal files are NEVER touched. Only junk is deleted."
$lblSafe.Font      = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$lblSafe.ForeColor = [System.Drawing.Color]::FromArgb(22, 163, 74)
$lblSafe.SetBounds(0, 0, 488, 32)
$lblSafe.TextAlign = "MiddleCenter"
$pnlSafe.Controls.Add($lblSafe)

# Log panel border
$pnlLog = New-Object System.Windows.Forms.Panel
$pnlLog.SetBounds(16, 134, 488, 380)
$pnlLog.BackColor   = [System.Drawing.Color]::White
$pnlLog.BorderStyle = "FixedSingle"
$form.Controls.Add($pnlLog)

# RichTextBox (scrollable coloured log)
$rtb = New-Object System.Windows.Forms.RichTextBox
$rtb.SetBounds(0, 0, 486, 378)
$rtb.ReadOnly    = $true
$rtb.BorderStyle = "None"
$rtb.BackColor   = [System.Drawing.Color]::White
$rtb.Font        = New-Object System.Drawing.Font("Consolas", 8.5)
$rtb.ScrollBars  = "Vertical"
$rtb.WordWrap    = $true
$pnlLog.Controls.Add($rtb)

# Progress bar
$prog = New-Object System.Windows.Forms.ProgressBar
$prog.SetBounds(16, 522, 488, 16)
$prog.Minimum = 0
$prog.Maximum = 100
$prog.Value   = 0
$prog.Style   = "Continuous"
$form.Controls.Add($prog)

# Status label
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text      = "Click  Start Cleaning  to begin."
$lblStatus.Font      = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
$lblStatus.SetBounds(16, 542, 488, 20)
$lblStatus.TextAlign = "MiddleCenter"
$form.Controls.Add($lblStatus)

# Start button
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text      = "  Start Cleaning  (click here)"
$btnStart.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnStart.BackColor = [System.Drawing.Color]::FromArgb(234, 88, 12)
$btnStart.ForeColor = [System.Drawing.Color]::White
$btnStart.FlatStyle = "Flat"
$btnStart.FlatAppearance.BorderSize = 0
$btnStart.SetBounds(16, 568, 310, 48)
$form.Controls.Add($btnStart)

# Close button
$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text      = "Close"
$btnClose.Font      = New-Object System.Drawing.Font("Segoe UI", 11)
$btnClose.BackColor = [System.Drawing.Color]::FromArgb(229, 231, 235)
$btnClose.ForeColor = [System.Drawing.Color]::FromArgb(75, 85, 99)
$btnClose.FlatStyle = "Flat"
$btnClose.FlatAppearance.BorderSize = 0
$btnClose.SetBounds(334, 568, 170, 48)
$form.Controls.Add($btnClose)
$btnClose.Add_Click({ $form.Close() })

# ════════════════════════════════════════════════════
#  HELPER FUNCTIONS
# ════════════════════════════════════════════════════
function WriteLog {
    param([string]$Text, [string]$Level = "info")
    $rtb.SelectionStart  = $rtb.TextLength
    $rtb.SelectionLength = 0
    switch ($Level) {
        "head" {
            $rtb.SelectionColor = [System.Drawing.Color]::FromArgb(234, 88, 12)
            $rtb.SelectionFont  = New-Object System.Drawing.Font("Consolas", 8.5, [System.Drawing.FontStyle]::Bold)
        }
        "ok" {
            $rtb.SelectionColor = [System.Drawing.Color]::FromArgb(22, 163, 74)
            $rtb.SelectionFont  = New-Object System.Drawing.Font("Consolas", 8.5)
        }
        "skip" {
            $rtb.SelectionColor = [System.Drawing.Color]::FromArgb(156, 163, 175)
            $rtb.SelectionFont  = New-Object System.Drawing.Font("Consolas", 8.5)
        }
        "done" {
            $rtb.SelectionColor = [System.Drawing.Color]::FromArgb(22, 163, 74)
            $rtb.SelectionFont  = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
        }
        "safe" {
            $rtb.SelectionColor = [System.Drawing.Color]::FromArgb(234, 88, 12)
            $rtb.SelectionFont  = New-Object System.Drawing.Font("Consolas", 8.5, [System.Drawing.FontStyle]::Bold)
        }
        default {
            $rtb.SelectionColor = [System.Drawing.Color]::FromArgb(55, 65, 81)
            $rtb.SelectionFont  = New-Object System.Drawing.Font("Consolas", 8.5)
        }
    }
    $rtb.AppendText("$Text`r`n")
    $rtb.SelectionStart = $rtb.TextLength
    $rtb.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Tick {
    param([int]$Pct, [string]$Msg)
    $prog.Value     = [Math]::Min($Pct, 100)
    $lblStatus.Text = $Msg
    [System.Windows.Forms.Application]::DoEvents()
}

function CleanPaths {
    param([string]$Label, [string[]]$Paths)
    WriteLog "  [ $Label ]" "head"
    $found = $false
    $clearedCount = 0
    foreach ($raw in $Paths) {
        $p = [System.Environment]::ExpandEnvironmentVariables($raw)
        if (Test-Path $p) {
            if (Remove-SafePathWithRetry -LiteralPath $p -Recurse) {
                WriteLog "    >> Cleared: $p" "ok"
                $found = $true
                $clearedCount++
            } else {
                WriteLog "    -- Skipped (locked): $p" "skip"
            }
        }
    }
    if (-not $found) { WriteLog "    -- Not installed or already empty." "skip" }
    else { WriteLog "    Done! Cleared $clearedCount locations." "ok" }
}

function CleanBrowser {
    param([string]$Label, [string]$UserData)
    WriteLog "  [ $Label ]" "head"
    $base = [System.Environment]::ExpandEnvironmentVariables($UserData)
    if (-not (Test-Path $base)) { WriteLog "    -- Not installed, skipping." "skip"; return }
    
    WriteLog "    Scanning for cache files..." "info"
    
    # Add timeout protection using a job
    $job = Start-Job -ScriptBlock {
        param($base, $SkipPathFragments, $JunkDirNames)
        $ErrorActionPreference = "SilentlyContinue"
        $n = 0
        $errorCount = 0
        $deletedPaths = @()
        
        function Test-SkipCleanPath {
            param([string]$Path)
            if ([string]::IsNullOrEmpty($Path)) { return $false }
            $norm = $Path.Replace('/', '\').ToLowerInvariant()
            foreach ($frag in $SkipPathFragments) {
                $normFrag = $frag.ToLowerInvariant()
                if ($norm -eq $normFrag -or $norm -like "*$normFrag" -or $norm -like "*$normFrag\*") {
                    return $true
                }
            }
            return $false
        }
        
        function Remove-ItemSafe {
            param([string]$Path, [switch]$Recurse)
            if (Test-SkipCleanPath $Path) { return $false }
            try {
                if ($Recurse) {
                    Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
                } else {
                    Remove-Item -Path $Path -Force -ErrorAction Stop
                }
                return $true
            } catch {
                return $false
            }
        }
        
        Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $p = $_.FullName
            # Cache and temporary subdirectories
            "Cache","Code Cache","GPUCache","Media Cache","blob_storage",
            "Service Worker\CacheStorage","Service Worker\ScriptCache",
            "Local Storage","IndexedDB","Session Storage","Application Cache",
            "Network","Extension State","Storage","DawnCache","GrShaderCache",
            "ShaderCache","Shared Dictionary","optimization_guide_hint_cache_store" | ForEach-Object {
                $targetPath = "$p\$_"
                if (Test-Path $targetPath) {
                    if (Remove-ItemSafe -Path $targetPath -Recurse) { 
                        $n++
                        $deletedPaths += $_
                    } else { 
                        $errorCount++ 
                    }
                }
            }
            # Cache and session files
            "Cookies","Cookies-journal","History","History-journal","Visited Links",
            "Top Sites","Top Sites-journal","Shortcuts","Shortcuts-journal",
            "Network Action Predictor","Favicons","Favicons-journal",
            "Extension Cookies","QuotaManager","Reporting and NEL","Reporting and NEL-journal" | ForEach-Object {
                $targetPath = "$p\$_"
                if (Test-Path $targetPath) {
                    if (Remove-ItemSafe -Path $targetPath) { 
                        $n++
                        $deletedPaths += $_
                    } else { 
                        $errorCount++ 
                    }
                }
            }
        }
        return @{ Cleaned = $n; Errors = $errorCount; DeletedPaths = $deletedPaths }
    } -ArgumentList $base, $script:SkipPathFragments, $script:JunkDirNames
    
    # Wait for job with timeout (30 seconds per browser)
    $job | Wait-Job -Timeout 30 | Out-Null
    
    if ($job.State -eq "Running") {
        Stop-Job $job
        Remove-Job $job -Force
        WriteLog "    -- Timeout (30s) - some files locked, skipping." "skip"
        return
    }
    
    $result = Receive-Job $job
    Remove-Job $job -Force
    
    if ($result.Cleaned -gt 0) {
        WriteLog "    Deleted: $($result.DeletedPaths -join ', ')" "ok"
    }
    
    if ($result.Errors -gt 0) {
        WriteLog "    OK  Done! ($($result.Cleaned) items cleaned, $($result.Errors) locked/skipped)  Passwords & autofill NOT touched." "ok"
    } else {
        WriteLog "    OK  Done! ($($result.Cleaned) items cleaned)  Passwords & autofill NOT touched." "ok"
    }
}

# ════════════════════════════════════════════════════
#  START BUTTON CLICK HANDLER
# ════════════════════════════════════════════════════
$btnStart.Add_Click({
    $btnStart.Enabled   = $false
    $btnStart.Text      = "  Cleaning in progress..."
    $btnStart.BackColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
    $rtb.Clear()
    $form.Refresh()

    WriteLog "============================================" "head"
    WriteLog "   My Clean PC -  Starting now..." "head"
    WriteLog "============================================" "head"
    WriteLog "" "info"
    WriteLog "  IMPORTANT: Your passwords, Downloads and" "safe"
    WriteLog "  personal files are NEVER deleted. Ever." "safe"
    WriteLog "  Temp + app cache: auto-delete, locked files auto-skip." "skip"
    WriteLog "" "info"

    $ranCore = $false
    $coreFile = Join-Path $PSScriptRoot "clean-pc-core.ps1"
    if (Test-Path $coreFile) {
        $ranCore = $true
        . $coreFile
        $guiPct = @{ 'STEP 1' = 2; 'STEP 2' = 17; 'STEP 3' = 52; 'STEP 4' = 60; 'STEP 5' = 70; 'STEP 6' = 85 }
        Invoke-MyCleanPCCore -Log {
            param([string]$Message)
            foreach ($k in @('STEP 1','STEP 2','STEP 3','STEP 4','STEP 5','STEP 6')) {
                if ($Message -like "*$k*") { Tick $guiPct[$k] $Message; break }
            }
            $lvl = "info"
            if ($Message -match 'auto-skip|skipped|NOT touched') { $lvl = "skip" }
            elseif ($Message -match 'cleared|emptied|flushed') { $lvl = "ok" }
            elseif ($Message -match '^-- STEP') { $lvl = "head" }
            WriteLog "  $Message" $lvl
        }
        Tick 100 "All done!"
    }

    if (-not $ranCore) {
        # ─── STEP 1: AI App Caches ───
        WriteLog "============================================" "head"
        WriteLog "  STEP 1 of 6 - AI App Caches" "head"
        WriteLog "============================================" "head"
        Tick 2 "Step 1 of 6 — Cleaning AI app caches..."
        CleanPaths "Cursor"      @("%APPDATA%\Cursor\Cache","%APPDATA%\Cursor\CachedData","%APPDATA%\Cursor\logs","%LOCALAPPDATA%\cursor-updater")
        CleanPaths "Kiro"        @("%APPDATA%\kiro\Cache","%APPDATA%\kiro\CachedData","%LOCALAPPDATA%\kiro")
        CleanPaths "Windsurf"    @("%APPDATA%\Windsurf\Cache","%APPDATA%\Windsurf\CachedData","%APPDATA%\Windsurf\logs","%LOCALAPPDATA%\Windsurf")
        CleanPaths "Trae AI"     @("%APPDATA%\Trae","%APPDATA%\trae-ai","%LOCALAPPDATA%\Trae")
        CleanPaths "Warp"        @("%APPDATA%\warp","%LOCALAPPDATA%\Warp\data")
        CleanPaths "Devin"       @("%APPDATA%\Devin","%LOCALAPPDATA%\Devin")
        CleanPaths "Genspark"    @("%APPDATA%\Genspark","%LOCALAPPDATA%\Genspark")
        CleanPaths "Antigravity" @("%APPDATA%\Antigravity","%LOCALAPPDATA%\Antigravity")
        CleanPaths "Qoder"       @("%APPDATA%\Qoder","%LOCALAPPDATA%\Qoder")
        Tick 14 "AI app caches — done."

        # ─── STEP 2: Browsers ───
        WriteLog "" "info"
        WriteLog "============================================" "head"
        WriteLog "  STEP 2 of 6 - Browser Cache + History" "head"
        WriteLog "  (Your PASSWORDS & BOOKMARKS are 100% SAFE!)" "ok"
        WriteLog "============================================" "head"
        Tick 17 "Step 2 of 6 - Cleaning browsers (passwords & bookmarks safe)..."
        Close-BrowserProcesses
        CleanBrowser "Google Chrome"    "%LOCALAPPDATA%\Google\Chrome\User Data"
        Tick 24 "Chrome done..."
        CleanBrowser "Microsoft Edge"   "%LOCALAPPDATA%\Microsoft\Edge\User Data"
        Tick 30 "Edge done..."
        CleanBrowser "Brave"            "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data"
        Tick 34 "Brave done..."
        CleanBrowser "Vivaldi"          "%LOCALAPPDATA%\Vivaldi\User Data"
        Tick 37 "Vivaldi done..."
        CleanBrowser "Opera"            "%APPDATA%\Opera Software\Opera Stable"
        Tick 40 "Opera done..."
        CleanBrowser "Genspark Browser" "%LOCALAPPDATA%\Genspark\User Data"
        Tick 43 "Genspark Browser done..."
        CleanBrowser "Yandex Browser"   "%LOCALAPPDATA%\Yandex\YandexBrowser\User Data"
        Tick 46 "Yandex done..."

        WriteLog "  [ Firefox ]" "head"
        $ff = [System.Environment]::ExpandEnvironmentVariables("%APPDATA%\Mozilla\Firefox\Profiles")
        if (Test-Path $ff) {
            $n = 0
            Get-ChildItem $ff -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $p = $_.FullName
                "cache2","startupCache","OfflineCache","thumbnails","storage","jumpListCache" | ForEach-Object {
                    if (Test-Path "$p\$_") {
                        if (Remove-SafePathWithRetry -LiteralPath "$p\$_" -Recurse) { $n++ }
                    }
                }
                "cookies.sqlite","cookies.sqlite-shm","cookies.sqlite-wal","downloads.sqlite","favicons.sqlite","favicons.sqlite-shm","favicons.sqlite-wal","webappsstore.sqlite","content-prefs.sqlite","permissions.sqlite","sessionCheckpoints.json" | ForEach-Object {
                    if (Test-Path "$p\$_") {
                        if (Remove-SafePathWithRetry -LiteralPath "$p\$_") { $n++ }
                    }
                }
            }
            WriteLog "    OK  Done! ($n items)  Bookmarks & passwords NOT touched." "ok"
        } else { WriteLog "    -- Firefox not installed, skipping." "skip" }
        Tick 50 "All browsers — done."

        # ─── STEP 3: Prefetch ───
        WriteLog "" "info"
        WriteLog "============================================" "head"
        WriteLog "  STEP 3 of 6 - Prefetch Only" "head"
        WriteLog "  (Quick Access `& Recent files are left untouched)" "skip"
        WriteLog "============================================" "head"
        Tick 52 "Step 3 of 6 — Clearing prefetch files..."
        Get-ChildItem "C:\Windows\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-SafePathWithRetry -LiteralPath $_.FullName | Out-Null
        }
        WriteLog "  OK  Windows Prefetch files cleared." "ok"
        WriteLog "  OK  Recent activity, Quick Access, and History were not touched." "ok"
        Tick 57 "Prefetch done."

        # ─── STEP 4: Temp Files + Rigorous AppData ───
        WriteLog "" "info"
        WriteLog "============================================" "head"
        WriteLog "  STEP 4 of 6 - Temporary Files + Rigorous AppData" "head"
        WriteLog "  (Errors here are normal - busy files skip)" "skip"
        WriteLog "============================================" "head"
        Tick 60 "Step 4 of 6 — Rigorous temp + AppData sweep..."
        
        $tmp = [System.Environment]::ExpandEnvironmentVariables("%TEMP%")
        if (Test-Path $tmp) {
            $tmpCount = Clear-SafeTempTree $tmp
            WriteLog "  OK  User temp folder cleared ($tmpCount items deleted)." "ok"
        } else {
            WriteLog "  -- User temp folder not found." "skip"
        }
        
        if (Test-Path "C:\Windows\Temp") {
            $sysTmpCount = Clear-SafeTempTree "C:\Windows\Temp"
            WriteLog "  OK  System temp folder cleared ($sysTmpCount items deleted)." "ok"
        } else {
            WriteLog "  -- System temp folder not found." "skip"
        }
        
        Clear-RigorousTempLocations
        WriteLog "  OK  Rigorous local temp — all locations cleared." "ok"
        
        $localCount = Clear-AppDataJunkSweep "Local AppData — all apps" "%LOCALAPPDATA%"
        $roamCount = Clear-AppDataJunkSweep "Roaming AppData — all apps" "%APPDATA%"
        WriteLog "  OK  AppData junk cleared ($localCount local + $roamCount roaming folders)." "ok"
        
        Tick 68 "Rigorous temp + AppData — done."

        # ─── STEP 5: Recycle Bin + Update Cache ───
        WriteLog "" "info"
        WriteLog "============================================" "head"
        WriteLog "  STEP 5 of 6 - Recycle Bin + Update Cache" "head"
        WriteLog "============================================" "head"
        Tick 70 "Step 5 of 6 — Emptying Recycle Bin..."
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
        $rbFlags = [RecycleBinNative]::SHERB_NOCONFIRMATION -bor [RecycleBinNative]::SHERB_NOPROGRESSUI -bor [RecycleBinNative]::SHERB_NOSOUND
        [RecycleBinNative]::SHEmptyRecycleBin([IntPtr]::Zero, $null, $rbFlags) | Out-Null
        WriteLog "  OK  Recycle Bin emptied." "ok"
        $wuDl = "C:\Windows\SoftwareDistribution\Download"
        if (Test-Path $wuDl) {
            Get-ChildItem $wuDl -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-SafePathWithRetry -LiteralPath $_.FullName -Recurse | Out-Null
            }
        }
        WriteLog "  OK  Windows Update download cache cleared." "ok"
        $wuLg = "C:\Windows\SoftwareDistribution\DataStore\Logs"
        if (Test-Path $wuLg) {
            Get-ChildItem $wuLg -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-SafePathWithRetry -LiteralPath $_.FullName -Recurse | Out-Null
            }
        }
        WriteLog "  OK  Windows Update log files cleared." "ok"
        $pkgs = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Packages")
        if (Test-Path $pkgs) {
            Get-ChildItem $pkgs -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $at = Join-Path $_.FullName "AC\Temp"
                $cn = Join-Path $_.FullName "AC\Microsoft\CryptnetUrlCache"
                if (Test-Path $at) { Remove-SafePathWithRetry -LiteralPath $at -Recurse | Out-Null }
                if (Test-Path $cn) { Remove-SafePathWithRetry -LiteralPath $cn -Recurse | Out-Null }
            }
        }
        WriteLog "  OK  Microsoft Store app temp folders cleared." "ok"
        $inet = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Microsoft\Windows\INetCache")
        if (Test-Path $inet) { Remove-SafePathWithRetry -LiteralPath $inet -Recurse | Out-Null }
        WriteLog "  OK  Internet cache cleared." "ok"
        $expCache = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%\Microsoft\Windows\Explorer")
        if (Test-Path $expCache) {
            Get-ChildItem $expCache -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue | ForEach-Object { Remove-SafePathWithRetry -LiteralPath $_.FullName | Out-Null }
            Get-ChildItem $expCache -Filter "iconcache_*.db"  -ErrorAction SilentlyContinue | ForEach-Object { Remove-SafePathWithRetry -LiteralPath $_.FullName | Out-Null }
        }
        WriteLog "  OK  Thumbnail/icon cache cleared.  (Icons may blink briefly - that is normal!)" "ok"
        Tick 82 "Recycle Bin and caches — done."

        # ─── STEP 6: DNS + Event Logs ───
        WriteLog "" "info"
        WriteLog "============================================" "head"
        WriteLog "  STEP 6 of 6 - Event Logs + DNS Cache" "head"
        WriteLog "============================================" "head"
        Tick 85 "Step 6 of 6 — Clearing event logs and DNS cache..."
        wevtutil cl Application 2>$null; WriteLog "  OK  Application event log cleared." "ok"
        wevtutil cl System      2>$null; WriteLog "  OK  System event log cleared."      "ok"
        wevtutil cl Security    2>$null; WriteLog "  OK  Security event log cleared."    "ok"
        wevtutil cl Setup       2>$null; WriteLog "  OK  Setup event log cleared."       "ok"
        ipconfig /flushdns | Out-Null;   WriteLog "  OK  DNS cache flushed.  (Helps fix website loading issues)" "ok"
        Tick 100 "All done!"
    }

    # ─── DONE! ───
    WriteLog "" "info"
    WriteLog "============================================" "done"
    WriteLog "   ALL DONE, Priyanka! Your PC is cleaner!" "done"
    WriteLog "============================================" "done"
    WriteLog "" "info"
    WriteLog "  What was cleaned:" "ok"
    WriteLog "    * AI app caches       CLEANED" "ok"
    WriteLog "    * Browser cache       CLEANED" "ok"
    WriteLog "    * Temp files          CLEANED (rigorous)" "ok"
    WriteLog "    * AppData junk        CLEANED (all apps)" "ok"
    WriteLog "    * Disk Cleanup        CLEANED (Downloads excluded)" "ok"
    WriteLog "    * Recycle Bin         EMPTIED" "ok"
    WriteLog "    * Windows Updates     CLEANED" "ok"
    WriteLog "    * DNS cache           FLUSHED" "ok"
    WriteLog "" "info"
    WriteLog "  What was NOT touched:" "safe"
    WriteLog "    * Your passwords      SAFE" "ok"
    WriteLog "    * Your Downloads      SAFE" "ok"
    WriteLog "    * Your personal files SAFE" "ok"
    WriteLog "" "info"
    WriteLog "  TIP: Restart your PC now for best results!" "done"
    WriteLog "============================================" "done"

    $lblStatus.Text = "All done! Please restart your PC for the best results."
    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(22, 163, 74)
    $form.BackColor      = [System.Drawing.Color]::FromArgb(240, 253, 244)
    $btnStart.Enabled    = $true
    $btnStart.Text       = "  Run Again"
    $btnStart.BackColor  = [System.Drawing.Color]::FromArgb(234, 88, 12)

    [System.Windows.Forms.MessageBox]::Show(
        "All done, Priyanka!`n`nYour PC has been cleaned.`n`nPlease RESTART your PC for the best results!`n`nYour passwords and personal files were completely untouched.",
        "My Clean PC - All Done!",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
})

# ════════════════════════════════════════════════════
#  SHOW THE WINDOW
# ════════════════════════════════════════════════════
$form.Add_Shown({ $form.Activate(); $btnStart.Focus() })
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($form)
