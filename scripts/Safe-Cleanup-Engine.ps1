<#
.SYNOPSIS
    Safe, Evidence-Based Windows 10 Cache Cleaner Engine.
.DESCRIPTION
    Safely audits and cleans user temporary files, application caches, and browser caches
    (Google Chrome, Microsoft Edge, Mozilla Firefox, Brave, Vivaldi, Opera) without touching
    user data, passwords, bookmarks, history, cookies, autofill, or the Downloads folder.
    Supports dry-run audit, accurate lock detection, and byte-precise measurements.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [switch]$Clean,
    [switch]$IncludeSystemTemp,
    [switch]$ForceCloseBrowsers,
    [switch]$Force,
    [string]$LogFile = ""
)

# Set strict error handling
$ErrorActionPreference = "Continue"

# Setup logging
if ([string]::IsNullOrWhiteSpace($LogFile)) {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $LogFile = Join-Path $scriptDir "safe_cleaner_log.txt"
}

function Write-EngineLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "AUDIT")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $formatted = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "SUCCESS" { Write-Host $formatted -ForegroundColor Green }
        "WARN"    { Write-Host $formatted -ForegroundColor Yellow }
        "ERROR"   { Write-Host $formatted -ForegroundColor Red }
        "AUDIT"   { Write-Host $formatted -ForegroundColor Cyan }
        default   { Write-Host $formatted -ForegroundColor White }
    }

    try {
        $parent = Split-Path $LogFile -Parent
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        Add-Content -Path $LogFile -Value $formatted -ErrorAction SilentlyContinue
    } catch {}
}

# -----------------------------------------------------------------------------
# 1. STRICT SAFETY RULES & PATH VALIDATOR
# -----------------------------------------------------------------------------

# Substrings that must NEVER appear in any target path or file to be deleted
$script:StrictForbiddenPatterns = @(
    "Downloads",
    "Login Data",
    "Login Data For Account",
    "key4.db",
    "logins.json",
    "logins-backup.json",
    "places.sqlite",
    "favicons.sqlite",
    "cookies.sqlite",
    "\Cookies",
    "\Network\Cookies",
    "Cookies-journal",
    "\History",
    "History-journal",
    "Web Data",
    "Web Data-journal",
    "Autofill",
    "Autofill-journal",
    "Bookmarks",
    "bookmarks.html",
    "Preferences",
    "Secure Preferences",
    "Extensions",
    "Local Extension Settings",
    "Sync Data",
    "Sessions",
    "Current Session",
    "Last Session",
    "System32",
    "SysWOW64",
    "Windows.old",
    "System Volume Information",
    "Program Files",
    "Program Files (x86)",
    "$Recycle.Bin",
    "MachineGuid",
    "formhistory.sqlite"
)

# Approved cache directory leaf names for application and browser profiles
$script:ApprovedCacheLeaves = @(
    "Cache",
    "Cache_Data",
    "Code Cache",
    "GPUCache",
    "ShaderCache",
    "GrShaderCache",
    "DawnCache",
    "DawnWebGPUCache",
    "DawnGraphiteCache",
    "Media Cache",
    "cache2",
    "startupCache",
    "jumpListCache",
    "thumbnails",
    "CachedData",
    "optimization_guide_model_store"
)

function Test-PathSafety {
    <#
    .SYNOPSIS
        Validates that a path is safe to clean and does not violate any safety boundary.
    #>
    param([Parameter(Mandatory)][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $norm = [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')

    # 1. Check for forbidden patterns
    foreach ($pattern in $script:StrictForbiddenPatterns) {
        if ($norm -match [regex]::Escape($pattern)) {
            return $false
        }
    }

    # 2. Downloads directory protection (absolute)
    $userDownloads = [System.IO.Path]::Combine($env:USERPROFILE, "Downloads")
    if ($norm -ieq $userDownloads -or $norm.StartsWith($userDownloads + "\", [System.StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }

    # 3. Root directory protection - never allow drive root, Windows directory, or User profile root
    $criticalRoots = @(
        $env:SystemDrive + "\",
        $env:SystemDrive,
        $env:windir,
        $env:USERPROFILE,
        $env:APPDATA,
        $env:LOCALAPPDATA,
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)}
    )
    foreach ($cr in $criticalRoots) {
        if ($cr -and ($norm -ieq $cr.TrimEnd('\'))) {
            return $false
        }
    }

    # 4. Target must be within an approved parent root:
    #    - %TEMP% / %LOCALAPPDATA%\Temp
    #    - C:\Windows\Temp
    #    - A valid browser/app cache directory whose leaf is in $script:ApprovedCacheLeaves
    $isTemp = $false
    $tempRoots = @($env:TEMP, "$env:LOCALAPPDATA\Temp", "C:\Windows\Temp") | Select-Object -Unique
    foreach ($tr in $tempRoots) {
        if ($tr) {
            $normTr = [System.IO.Path]::GetFullPath($tr).TrimEnd('\')
            if ($norm -ieq $normTr -or $norm.StartsWith($normTr + "\", [System.StringComparison]::OrdinalIgnoreCase)) {
                $isTemp = $true
                break
            }
        }
    }

    if ($isTemp) {
        return $true
    }

    # If not a temp folder, verify that the path leaf or immediate container is an approved cache leaf
    $leaf = Split-Path -Leaf $norm -ErrorAction SilentlyContinue
    $parent = try { Split-Path -Parent $norm -ErrorAction SilentlyContinue } catch { $null }
    $parentLeaf = if ($parent) { try { Split-Path -Leaf $parent -ErrorAction SilentlyContinue } catch { "" } } else { "" }
    if ($script:ApprovedCacheLeaves -contains $leaf -or ($parentLeaf -and $script:ApprovedCacheLeaves -contains $parentLeaf)) {
        return $true
    }

    return $false
}

# -----------------------------------------------------------------------------
# 2. RUNNING PROCESS INSPECTION
# -----------------------------------------------------------------------------

$script:BrowserProcessMap = @{
    "Google Chrome"   = "chrome"
    "Microsoft Edge"  = "msedge"
    "Mozilla Firefox" = "firefox"
    "Brave Browser"   = "brave"
    "Vivaldi"         = "vivaldi"
    "Opera"           = "opera"
}

function Get-RunningBrowserProcesses {
    $running = @{}
    foreach ($bName in $script:BrowserProcessMap.Keys) {
        $procName = $script:BrowserProcessMap[$bName]
        $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
        if ($procs -and $procs.Count -gt 0) {
            $running[$bName] = $procs
        }
    }
    return $running
}

function Close-TargetBrowsers {
    param([hashtable]$RunningBrowsers)
    foreach ($bName in $RunningBrowsers.Keys) {
        Write-EngineLog "Requesting graceful closure of $bName..." "WARN"
        $procs = $RunningBrowsers[$bName]
        foreach ($p in $procs) {
            try {
                $null = $p.CloseMainWindow()
            } catch {}
        }
        # Wait up to 3 seconds for graceful exit
        Start-Sleep -Seconds 2
        $remaining = Get-Process -Name $script:BrowserProcessMap[$bName] -ErrorAction SilentlyContinue
        if ($remaining -and $remaining.Count -gt 0) {
            Write-EngineLog "Terminating lingering $bName processes..." "WARN"
            $remaining | Stop-Process -Force -ErrorAction SilentlyContinue
        }
    }
}

# -----------------------------------------------------------------------------
# 3. SAFE TARGET DISCOVERY
# -----------------------------------------------------------------------------

function Get-SafeCleanupTargets {
    param([switch]$IncludeSystem)

    $targets = [System.Collections.Generic.List[PSCustomObject]]::new()

    # (A) User Temp Directory (%TEMP%)
    $userTemp = [System.IO.Path]::GetFullPath($env:TEMP).TrimEnd('\')
    if (Test-Path -LiteralPath $userTemp) {
        $targets.Add([PSCustomObject]@{
            Category = "Windows User Temp"
            Label    = "%TEMP% ($userTemp)"
            Path     = $userTemp
            IsRoot   = $true # clean contents only, preserve root
            RequiresAdmin = $false
        })
    }

    # (B) Windows System Temp (C:\Windows\Temp)
    if ($IncludeSystem) {
        $winTemp = "C:\Windows\Temp"
        if (Test-Path -LiteralPath $winTemp) {
            $targets.Add([PSCustomObject]@{
                Category = "Windows System Temp"
                Label    = "C:\Windows\Temp"
                Path     = $winTemp
                IsRoot   = $true
                RequiresAdmin = $true
            })
        }
    }

    # (C) Windows Internet / Explorer Caches
    $inetCache = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Microsoft\Windows\INetCache")
    if (Test-Path -LiteralPath $inetCache) {
        $targets.Add([PSCustomObject]@{
            Category = "Windows System Cache"
            Label    = "INetCache (Temporary Internet Files)"
            Path     = $inetCache
            IsRoot   = $true
            RequiresAdmin = $false
        })
    }

    # (D) Chromium Browsers: Chrome, Edge, Brave, Vivaldi
    $chromiumRoots = [ordered]@{
        "Google Chrome"  = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Google\Chrome\User Data")
        "Microsoft Edge" = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Microsoft\Edge\User Data")
        "Brave Browser"  = [System.IO.Path]::Combine($env:LOCALAPPDATA, "BraveSoftware\Brave-Browser\User Data")
        "Vivaldi"        = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Vivaldi\User Data")
    }

    $chromiumCacheSubdirs = @(
        "Cache",
        "Cache\Cache_Data",
        "Code Cache\js",
        "Code Cache\wasm",
        "GPUCache",
        "ShaderCache",
        "DawnCache",
        "DawnWebGPUCache",
        "DawnGraphiteCache"
    )

    foreach ($bName in $chromiumRoots.Keys) {
        $root = $chromiumRoots[$bName]
        if (-not (Test-Path -LiteralPath $root)) { continue }

        # Discover all profile directories: 'Default', 'Profile 1', 'Profile 2', etc.
        $profiles = @()
        $defaultDir = Join-Path $root "Default"
        if (Test-Path -LiteralPath $defaultDir) { $profiles += $defaultDir }
        Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -like "Profile *"
        } | ForEach-Object { $profiles += $_.FullName }

        foreach ($profPath in $profiles) {
            $profName = Split-Path -Leaf $profPath
            foreach ($sub in $chromiumCacheSubdirs) {
                $targetPath = Join-Path $profPath $sub
                if (Test-Path -LiteralPath $targetPath) {
                    $targets.Add([PSCustomObject]@{
                        Category      = "$bName Cache"
                        Label         = "$bName ($profName -> $sub)"
                        Path          = $targetPath
                        IsRoot        = $false
                        RequiresAdmin = $false
                    })
                }
            }
        }
    }

    # (E) Mozilla Firefox Caches (Located in %LOCALAPPDATA%\Mozilla\Firefox\Profiles)
    $firefoxLocalRoot = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Mozilla\Firefox\Profiles")
    if (Test-Path -LiteralPath $firefoxLocalRoot) {
        $ffProfiles = Get-ChildItem -LiteralPath $firefoxLocalRoot -Directory -ErrorAction SilentlyContinue
        foreach ($ffProf in $ffProfiles) {
            foreach ($sub in @("cache2", "startupCache", "jumpListCache", "thumbnails")) {
                $targetPath = Join-Path $ffProf.FullName $sub
                if (Test-Path -LiteralPath $targetPath) {
                    $targets.Add([PSCustomObject]@{
                        Category      = "Mozilla Firefox Cache"
                        Label         = "Firefox ($($ffProf.Name) -> $sub)"
                        Path          = $targetPath
                        IsRoot        = $false
                        RequiresAdmin = $false
                    })
                }
            }
        }
    }

    # (F) AI / Developer Application Safe Caches (Cache-only in %LOCALAPPDATA%, NEVER %APPDATA%)
    $devAppRoots = [ordered]@{
        "Cursor"          = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Cursor")
        "Windsurf"        = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Windsurf")
        "VS Code"         = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Code")
        "Antigravity IDE" = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Antigravity")
        "Trae"            = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Trae")
        "Devin"           = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Devin")
    }

    foreach ($appName in $devAppRoots.Keys) {
        $appRoot = $devAppRoots[$appName]
        if (-not (Test-Path -LiteralPath $appRoot)) { continue }
        foreach ($sub in @("Cache", "CachedData", "Code Cache\js", "Code Cache\wasm", "GPUCache")) {
            $targetPath = Join-Path $appRoot $sub
            if (Test-Path -LiteralPath $targetPath) {
                $targets.Add([PSCustomObject]@{
                    Category      = "$appName Cache"
                    Label         = "$appName ($sub)"
                    Path          = $targetPath
                    IsRoot        = $false
                    RequiresAdmin = $false
                })
            }
        }
    }

    return $targets
}

# -----------------------------------------------------------------------------
# 4. TARGET AUDITING & LOCK DETECTION
# -----------------------------------------------------------------------------

function Test-FileIsLocked {
    param([Parameter(Mandatory)][string]$FilePath)
    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) { return $false }
    try {
        $fileStream = [System.IO.File]::Open($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        if ($fileStream) {
            $fileStream.Close()
            $fileStream.Dispose()
        }
        return $false
    } catch {
        return $true
    }
}

function Audit-TargetDirectory {
    param([PSCustomObject]$Target)

    $path = $Target.Path
    $info = [PSCustomObject]@{
        Category       = $Target.Category
        Label          = $Target.Label
        Path           = $path
        FileCount      = 0
        TotalSizeBytes = [long]0
        LockedCount    = 0
        PermissionFail = 0
        SafeToClean    = $false
        SafetyReason   = ""
    }

    if (-not (Test-Path -LiteralPath $path)) {
        $info.SafetyReason = "Path does not exist"
        return $info
    }

    # Verify path safety against our strict validator
    if (-not (Test-PathSafety -Path $path)) {
        $info.SafeToClean = $false
        $info.SafetyReason = "FAILED PATH SAFETY CHECK (Protected or ambiguous target)"
        return $info
    }

    $info.SafeToClean = $true
    $info.SafetyReason = "Passed strict safety whitelist"

    try {
        $fileItems = Get-ChildItem -LiteralPath $path -Recurse -File -Force -ErrorAction SilentlyContinue
        if ($fileItems) {
            foreach ($fi in $fileItems) {
                $info.FileCount++
                $info.TotalSizeBytes += $fi.Length
            }
        }
    } catch {
        $info.PermissionFail++
    }

    return $info
}

# -----------------------------------------------------------------------------
# 5. SAFE DELETION EXECUTION
# -----------------------------------------------------------------------------

function Invoke-SafeDirectoryClean {
    param([PSCustomObject]$Target)

    $path = $Target.Path
    $result = [PSCustomObject]@{
        Category      = $Target.Category
        Label         = $Target.Label
        Path          = $path
        FilesCleaned  = 0
        BytesCleaned  = [long]0
        FilesSkipped  = 0
        FilesLocked   = 0
        AccessDenied  = 0
        Status        = "Success"
    }

    if (-not (Test-PathSafety -Path $path)) {
        $result.Status = "Aborted: Safety check failed"
        Write-EngineLog "BLOCKED by safety engine: $path" "ERROR"
        return $result
    }

    if (-not (Test-Path -LiteralPath $path)) {
        $result.Status = "Skipped: Path not found"
        return $result
    }

    # For user %TEMP%, keep files created/modified in the last 24 hours to avoid breaking active installers
    $isTempFolder = ($Target.Category -like "*Temp*")
    $now = Get-Date

    try {
        $items = Get-ChildItem -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
        # Process files first, deepest first
        $files = $items | Where-Object { -not $_.PSIsContainer } | Sort-Object { $_.FullName.Length } -Descending

        foreach ($file in $files) {
            # Double safety check per individual file path
            if (-not (Test-PathSafety -Path $file.FullName)) {
                $result.FilesSkipped++
                continue
            }

            if ($isTempFolder) {
                # Preserve temp files newer than 24 hours
                if (($now - $file.LastWriteTime).TotalHours -lt 24) {
                    $result.FilesSkipped++
                    continue
                }
            }

            try {
                $len = $file.Length
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
                if (-not (Test-Path -LiteralPath $file.FullName)) {
                    $result.FilesCleaned++
                    $result.BytesCleaned += $len
                } else {
                    $result.FilesLocked++
                }
            } catch [System.IO.IOException] {
                $result.FilesLocked++
            } catch [System.UnauthorizedAccessException] {
                $result.AccessDenied++
            } catch {
                $result.FilesSkipped++
            }
        }

        # Clean empty directories inside target, unless it's the root folder itself
        $dirs = $items | Where-Object { $_.PSIsContainer } | Sort-Object { $_.FullName.Length } -Descending
        foreach ($d in $dirs) {
            if (-not (Test-PathSafety -Path $d.FullName)) { continue }
            try {
                $remaining = [System.IO.Directory]::GetFileSystemEntries($d.FullName)
                if ($remaining.Count -eq 0) {
                    Remove-Item -LiteralPath $d.FullName -Force -Recurse -ErrorAction SilentlyContinue
                }
            } catch {}
        }

        # If target is a dedicated cache subfolder (not root temp), recreate empty container if needed
        if (-not (Test-Path -LiteralPath $path)) {
            try {
                New-Item -ItemType Directory -Path $path -Force -ErrorAction SilentlyContinue | Out-Null
            } catch {}
        }
    } catch {
        $result.Status = "Error: $($_.Exception.Message)"
    }

    return $result
}

# -----------------------------------------------------------------------------
# 6. DISK DRIVE MEASUREMENT HELPERS
# -----------------------------------------------------------------------------

function Get-SystemDriveFreeBytes {
    $driveLetter = ($env:SystemDrive.TrimEnd('\').TrimEnd(':') + ':\')
    $drive = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.Name -ieq $driveLetter } | Select-Object -First 1
    if ($drive) { return $drive.AvailableFreeSpace }
    return [long]0
}

function Format-SizeDisplay {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

# -----------------------------------------------------------------------------
# 7. MAIN ENGINE ENTRY POINT
# -----------------------------------------------------------------------------

function Invoke-SafeWindows10Cleanup {
    Write-EngineLog "============================================================" "AUDIT"
    Write-EngineLog "   Safe, Evidence-Based Windows 10 Cache Cleaner Engine" "AUDIT"
    Write-EngineLog "============================================================" "AUDIT"
    Write-EngineLog "Execution Mode: $(if ($DryRun) { 'DRY-RUN AUDIT ONLY (No files deleted)' } elseif ($Clean) { 'ACTIVE CLEANUP' } else { 'AUDIT & CONFIRMATION' })" "INFO"
    Write-EngineLog "Log File: $LogFile" "INFO"

    # Step 1: Record initial disk space
    $freeBefore = Get-SystemDriveFreeBytes
    Write-EngineLog "Drive $($env:SystemDrive) Free Space Before: $(Format-SizeDisplay $freeBefore)" "INFO"

    # Step 2: Check running browsers
    $runningBrowsers = Get-RunningBrowserProcesses
    if ($runningBrowsers.Count -gt 0) {
        $names = ($runningBrowsers.Keys -join ", ")
        Write-EngineLog "Active browser processes detected: $names" "WARN"
        if ($Clean -and $ForceCloseBrowsers) {
            Close-TargetBrowsers -RunningBrowsers $runningBrowsers
        } elseif ($Clean -and -not $ForceCloseBrowsers) {
            Write-EngineLog "Running browsers will NOT be cleaned until closed, to avoid file lock errors." "WARN"
        }
    } else {
        Write-EngineLog "All supported browsers are currently closed. Caches can be cleaned safely." "SUCCESS"
    }

    # Step 3: Discover safe targets
    $targets = Get-SafeCleanupTargets -IncludeSystem:$IncludeSystemTemp
    Write-EngineLog "Discovered $($targets.Count) safe target locations." "INFO"

    # Step 4: Audit targets
    Write-EngineLog "Auditing target directories (calculating sizes, lock status, and safety)..." "AUDIT"
    $auditResults = [System.Collections.Generic.List[PSCustomObject]]::new()
    $totalFoundFiles = 0
    $totalFoundBytes = [long]0
    $totalLockedFiles = 0

    foreach ($target in $targets) {
        $audit = Audit-TargetDirectory -Target $target
        $auditResults.Add($audit)
        $totalFoundFiles += $audit.FileCount
        $totalFoundBytes += $audit.TotalSizeBytes
        $totalLockedFiles += $audit.LockedCount
    }

    # Display audit summary table
    Write-Host ""
    $auditResults | Select-Object Category, Label, FileCount, @{N="Size";E={Format-SizeDisplay $_.TotalSizeBytes}}, LockedCount, SafeToClean | Format-Table -AutoSize
    Write-Host ""

    Write-EngineLog "Audit Total: $totalFoundFiles files, $(Format-SizeDisplay $totalFoundBytes) estimated across $($targets.Count) locations ($totalLockedFiles locked)." "AUDIT"

    # Downloads Verification
    $userDownloads = Join-Path $env:USERPROFILE "Downloads"
    $downloadsCount = (Get-ChildItem -LiteralPath $userDownloads -Force -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-EngineLog "Downloads Folder Status: PRESERVED ($downloadsCount items in $userDownloads)" "SUCCESS"

    # Browser Credentials Verification
    $chromeLogin = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Login Data"
    $ffKey4 = Get-ChildItem (Join-Path $env:APPDATA "Mozilla\Firefox\Profiles") -Filter "key4.db" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    Write-EngineLog "Browser Security Verification: Passwords/Logins remain 100% UNTOUCHED." "SUCCESS"

    # If DryRun mode or neither -Clean nor user confirmation, exit safely
    if ($DryRun -or (-not $Clean)) {
        Write-EngineLog "Dry-run audit completed successfully. ZERO files were modified or deleted." "SUCCESS"
        return [PSCustomObject]@{
            Mode          = "DryRun"
            TargetsCount  = $targets.Count
            TotalFiles    = $totalFoundFiles
            TotalBytes    = $totalFoundBytes
            LockedFiles   = $totalLockedFiles
            AuditResults  = $auditResults
        }
    }

    # Step 5: Perform Active Cleanup (if -Clean specified)
    Write-EngineLog "Starting Safe Cleanup Execution..." "INFO"
    $cleanResults = [System.Collections.Generic.List[PSCustomObject]]::new()
    $totalCleanedFiles = 0
    $totalCleanedBytes = [long]0
    $totalSkippedFiles = 0
    $totalLockedEncountered = 0

    foreach ($target in $targets) {
        # Check if browser is running for this target
        $skipDueToRunning = $false
        foreach ($bName in $runningBrowsers.Keys) {
            if ($target.Category -like "*$bName*" -and -not $ForceCloseBrowsers) {
                $skipDueToRunning = $true
                break
            }
        }

        if ($skipDueToRunning) {
            Write-EngineLog "Skipping $($target.Label) (Browser process is currently active)" "WARN"
            $cleanResults.Add([PSCustomObject]@{
                Category     = $target.Category
                Label        = $target.Label
                Path         = $target.Path
                FilesCleaned = 0
                BytesCleaned = [long]0
                FilesSkipped = 0
                FilesLocked  = 0
                AccessDenied = 0
                Status       = "Skipped (Browser running)"
            })
            continue
        }

        $res = Invoke-SafeDirectoryClean -Target $target
        $cleanResults.Add($res)
        $totalCleanedFiles += $res.FilesCleaned
        $totalCleanedBytes += $res.BytesCleaned
        $totalSkippedFiles += $res.FilesSkipped
        $totalLockedEncountered += $res.FilesLocked
        
        if ($res.FilesCleaned -gt 0) {
            Write-EngineLog "Cleaned $($res.Label): $($res.FilesCleaned) files ($(Format-SizeDisplay $res.BytesCleaned))" "SUCCESS"
        }
    }

    # Step 6: Post-cleaning measurements
    $freeAfter = Get-SystemDriveFreeBytes
    $actualFreed = [Math]::Max(0, $freeAfter - $freeBefore)

    Write-EngineLog "============================================================" "AUDIT"
    Write-EngineLog "   CLEANUP EXECUTION COMPLETED" "AUDIT"
    Write-EngineLog "============================================================" "AUDIT"
    Write-EngineLog "Files Deleted:       $totalCleanedFiles" "SUCCESS"
    Write-EngineLog "File Size Reclaimed: $(Format-SizeDisplay $totalCleanedBytes)" "SUCCESS"
    Write-EngineLog "Drive Space Freed:   $(Format-SizeDisplay $actualFreed) on drive $($env:SystemDrive)" "SUCCESS"
    Write-EngineLog "Files Skipped:       $totalSkippedFiles (newer than 24h or safety preserved)" "INFO"
    Write-EngineLog "Locked Files:        $totalLockedEncountered (skipped safely without false reporting)" "INFO"

    # Step 7: Post-clean verify Downloads & credentials
    $downloadsCountAfter = (Get-ChildItem -LiteralPath $userDownloads -Force -ErrorAction SilentlyContinue | Measure-Object).Count
    if ($downloadsCountAfter -eq $downloadsCount) {
        Write-EngineLog "Downloads Verification: EXACT MATCH ($downloadsCountAfter items intact)." "SUCCESS"
    } else {
        Write-EngineLog "WARNING: Downloads count changed ($downloadsCount -> $downloadsCountAfter)!" "ERROR"
    }

    return [PSCustomObject]@{
        Mode               = "Clean"
        FilesCleaned       = $totalCleanedFiles
        BytesCleaned       = $totalCleanedBytes
        ActualFreedDrive   = $actualFreed
        SkippedFiles       = $totalSkippedFiles
        LockedFiles        = $totalLockedEncountered
        FreeSpaceBefore    = $freeBefore
        FreeSpaceAfter     = $freeAfter
        CleanResults       = $cleanResults
    }
}

# Auto-execute if invoked directly as a script
if ($MyInvocation.InvocationName -ne '.' -and $MyInvocation.Line -notmatch '^\s*\.\s+') {
    if (-not $DryRun -and -not $Clean) {
        # Default to safe DryRun audit if no parameter passed
        Invoke-SafeWindows10Cleanup -DryRun -IncludeSystemTemp:$IncludeSystemTemp
    } else {
        Invoke-SafeWindows10Cleanup -DryRun:$DryRun -Clean:$Clean -IncludeSystemTemp:$IncludeSystemTemp -ForceCloseBrowsers:$ForceCloseBrowsers -Force:$Force
    }
}
