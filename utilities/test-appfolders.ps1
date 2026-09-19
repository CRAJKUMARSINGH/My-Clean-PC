# My Clean PC - AppFolder Check Script
# Check the existence and details of application folders to be cleaned
#

param(
    [string]$UserName = "Rajkumar"
)

$ErrorActionPreference = "SilentlyContinue"
$ConfirmPreference = "None"
$ProgressPreference = "SilentlyContinue"

$LogDir = "C:\Scripts\Logs"
$CheckFile = Join-Path $LogDir "appfolder-check-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "[$Timestamp] $Message"
    Write-Host $LogEntry -ForegroundColor Green
    Add-Content -Path $CheckFile -Value $LogEntry -ErrorAction SilentlyContinue
}

Write-Host "=== My Clean PC - AppFolder Check Script ===" -ForegroundColor Cyan
Write-Host "Checking application folders for user: $UserName" -ForegroundColor Yellow
Write-Host "" -ForegroundColor White

# Define all folders to check
$FoldersToCheck = @(
    @{ Path = "C:\Users\$UserName\AppData\Roaming\Trae"; Critical = $false },
    @{ Path = "C:\Users\$UserName\AppData\Roaming\Cursor"; Critical = $false },
    @{ Path = "C:\Users\$UserName\AppData\Roaming\Kiro"; Critical = $false },
    @{ Path = "C:\Users\$UserName\AppData\Roaming\Antigravity"; Critical = $false },
    @{ Path = "C:\Users\$UserName\AppData\Roaming\Qoder"; Critical = $false },
    @{ Path = "C:\Users\$UserName\AppData\Roaming\devin"; Critical = $false }
)

$existingFolders = 0
$totalFolderSize = 0

foreach ($folder in $FoldersToCheck) {
    $folderPath = $folder.Path
    $folderName = Split-Path $folderPath -Leaf
    
    Write-Log "Checking folder: $folderName"
    Write-Log "  Path: $folderPath"
    
    if (Test-Path $folderPath -PathType Container) {
        $existingFolders++
        try {
            $size = 0
            $items = Get-ChildItem -Path $folderPath -Recurse -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                if ($item.PSIsContainer) {
                    $size += (Get-ChildItem -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                } else {
                    $size += $item.Length
                }
            }
            $totalFolderSize += $size
            
            Write-Log "  Status: EXISTS"
            Write-Log "  Size: $(Get-FormattedSize $size)"
            Write-Log "  Type: $(if (Test-Path $folderPath -PathType Container) { 'Directory' } else { 'File' })"
            
            # List first level contents if directory
            if (Test-Path $folderPath -PathType Container) {
                $subItems = Get-ChildItem -Path $folderPath -ErrorAction SilentlyContinue
                Write-Log "  Top-level items: $(@($subItems | Measure-Object).Count)"
                foreach ($item in $subItems | Get-Member -MemberType Properties | Select-Object -First 5) {
                    Write-Log "    - $($item.Name)"
                }
            }
            
        } catch {
            Write-Log "  Status: EXISTS (error getting size: $_)"
        }
    } else {
        Write-Log "  Status: DOES NOT EXIST"
    }
    
    Write-Log ""
}

function Get-FormattedSize {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return "$($($Bytes / 1GB).ToString('F2')) GB" }
    elseif ($Bytes -ge 1MB) { return "$($($Bytes / 1MB).ToString('F1')) MB" }
    elseif ($Bytes -ge 1KB) { return "$($($Bytes / 1KB).ToString('F0')) KB" }
    else { return "$Bytes bytes" }
}

Write-Host "=== Check Summary ===" -ForegroundColor Green
Write-Host "User: $UserName" -ForegroundColor White
Write-Host "Existing folders: $existingFolders out of $($FoldersToCheck.Count)" -ForegroundColor White
Write-Host "Total size of existing folders: $(Get-FormattedSize $totalFolderSize)" -ForegroundColor White
Write-Host "" -ForegroundColor White

if ($existingFolders -eq 0) {
    Write-Host "All folders have been cleaned!" -ForegroundColor Green
} elseif ($existingFolders -lt 3) {
    Write-Host "Only $existingFolders folders exist. Recent cleanup may have been successful." -ForegroundColor Yellow
} else {
    Write-Host "$existingFolders folders exist and can be cleaned." -ForegroundColor Yellow
}

Write-Host "" -ForegroundColor White
Write-Host "Check complete. Details logged to: $CheckFile" -ForegroundColor Gray
Write-Host "=== End of Check ===" -ForegroundColor Cyan