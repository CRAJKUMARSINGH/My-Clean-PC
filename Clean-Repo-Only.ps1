# Clean Temp and Find Duplicates in This Repo Folder Only
# Target: E:\Rajkumar\My-Clean-PC

$RepoPath = "E:\Rajkumar\My-Clean-PC"

Write-Output "========================================"
Write-Output "Repo Folder Cleanup"
Write-Output "========================================"
Write-Output "Target: $RepoPath"
Write-Output ""

# STEP 1: Clean temp files in repo
Write-Output "Step 1: Cleaning temp files in repo..."

$tempPatterns = @("*.tmp", "*.temp", "*.cache", "*.log", "*.bak", "~*", "*.swp")
$TotalRemoved = 0

foreach ($pattern in $tempPatterns) {
    try {
        $files = Get-ChildItem -Path $RepoPath -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                $TotalRemoved++
                Write-Output "Removed: $($file.Name)"
            } catch {
                # Skip locked files
            }
        }
    } catch {
        # Pattern may not match anything
    }
}

Write-Output "Removed $TotalRemoved temp files from repo"
Write-Output ""

# STEP 2: Find duplicate files in repo
Write-Output "Step 2: Finding duplicate files in repo..."

function Get-FileHashSafe {
    param([string]$FilePath)
    try {
        return (Get-FileHash -Path $FilePath -Algorithm SHA256 -ErrorAction Stop).Hash
    } catch {
        return $null
    }
}

$FileHashes = @{}
$TotalFiles = 0

try {
    $Files = Get-ChildItem -Path $RepoPath -File -Recurse -ErrorAction SilentlyContinue | 
             Where-Object { $_.FullName -notmatch '\.git' }
    
    foreach ($File in $Files) {
        $Hash = Get-FileHashSafe -FilePath $File.FullName
        if ($Hash) {
            if ($FileHashes.ContainsKey($Hash)) {
                $FileHashes[$Hash] += ,@($File.FullName, $File.Length)
            } else {
                $FileHashes[$Hash] = ,@($File.FullName, $File.Length)
            }
            $TotalFiles++
        }
    }
} catch {
    Write-Output "Error scanning files: $_"
}

Write-Output "Scanned $TotalFiles files in repo"

# Find duplicates
$Duplicates = @{}
foreach ($Hash in $FileHashes.Keys) {
    $Files = $FileHashes[$Hash]
    if ($Files.Count -gt 1) {
        $Duplicates[$Hash] = $Files
    }
}

Write-Output "Duplicate groups found: $($Duplicates.Count)"
Write-Output ""

if ($Duplicates.Count -eq 0) {
    Write-Output "No duplicate files found in repo!"
} else {
    # Calculate space savings
    $TotalSpaceSaved = 0
    foreach ($Hash in $Duplicates.Keys) {
        $Files = $Duplicates[$Hash]
        $FileSize = $Files[0][1]
        $DuplicateCount = $Files.Count - 1
        $TotalSpaceSaved += ($FileSize * $DuplicateCount)
    }

    $SpaceSavedKB = [math]::Round($TotalSpaceSaved / 1KB, 2)
    Write-Output "Total space that could be saved: $SpaceSavedKB KB"
    Write-Output ""

    # Display duplicates
    $GroupNumber = 1
    foreach ($Hash in $Duplicates.Keys) {
        $Files = $Duplicates[$Hash]
        Write-Output "--- Duplicate Group $GroupNumber ---"
        Write-Output "File size: $($Files[0][1]) bytes"
        Write-Output "Locations:"
        
        for ($i = 0; $i -lt $Files.Count; $i++) {
            $relativePath = $Files[$i][0].Replace($RepoPath, "")
            Write-Output "  [$i] $relativePath"
        }
        
        Write-Output ""
        $GroupNumber++
    }
}

Write-Output "========================================"
Write-Output "Repo cleanup completed!"
Write-Output "========================================"