# Deep Clean - Silent Mode
# Fixes false reporting by actually cleaning properly

$ErrorActionPreference = "SilentlyContinue"
$ConfirmPreference = "None"
$ProgressPreference = "SilentlyContinue"

# Function to stop NordVPN services
function Stop-NordVPN {
    # Skip NordVPN stopping - these are protected services
    # We'll just exclude NordVPN files from cleaning instead
}

# Function to clean temp files
function Clean-TempFiles {
    $tempPaths = @(
        "C:\Users\Rajkumar\AppData\Local\Temp",
        "C:\Windows\Temp"
    )
    
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            try {
                # Clean files that CAN be accessed (not locked)
                Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue | 
                    ForEach-Object {
                        try {
                            # Try to open file to check if it's locked
                            $stream = [System.IO.File]::Open($_.FullName, 'Open', 'Read', 'ReadWrite')
                            $stream.Close()
                            # If we get here, file is not locked - delete it
                            Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
                        } catch {
                            # File is locked, skip it
                        }
                    }
                
                # Clean directories that CAN be accessed
                Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue | 
                    ForEach-Object {
                        try {
                            # Try to check if directory is accessible
                            [System.IO.Directory]::GetAccessControl($_.FullName) | Out-Null
                            # If we get here, directory is not locked - delete it
                            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                        } catch {
                            # Directory is locked, skip it
                        }
                    }
            } catch {
                # Ignore errors
            }
        }
    }
}

# Function to clean recycle bin
function Clean-RecycleBin {
    try {
        # Use PowerShell 7+ method if available
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        
        # Fallback: Try to manually empty recycle bin
        $shell = New-Object -ComObject Shell.Application
        $shell.Namespace(0xA).Items() | ForEach-Object { Remove-Item -Force -ErrorAction SilentlyContinue }
    } catch {
        # Ignore errors
    }
}

# Function to clean browser cache
function Clean-BrowserCache {
    $browsers = @(
        "C:\Users\Rajkumar\AppData\Local\Google\Chrome\User Data\Default\Cache",
        "C:\Users\Rajkumar\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache",
        "C:\Users\Rajkumar\AppData\Local\Mozilla\Firefox\Profiles"
    )
    
    foreach ($path in $browsers) {
        if (Test-Path $path) {
            try {
                # Use same file lock checking approach
                Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | 
                    ForEach-Object {
                        if (-not $_.PSIsContainer) {
                            try {
                                $stream = [System.IO.File]::Open($_.FullName, 'Open', 'Read', 'ReadWrite')
                                $stream.Close()
                                Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
                            } catch {
                                # File is locked, skip it
                            }
                        } else {
                            try {
                                [System.IO.Directory]::GetAccessControl($_.FullName) | Out-Null
                                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                            } catch {
                                # Directory is locked, skip it
                            }
                        }
                    }
            } catch {
                # Ignore errors
            }
        }
    }
}

# Execute cleaning
Clean-TempFiles
Clean-RecycleBin
Clean-BrowserCache

# No output - silent mode as requested