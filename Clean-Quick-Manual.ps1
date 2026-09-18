# Quick Manual Cleanup Script
# For immediate temp cleaning and manual duplicate handling

Write-Output "========================================"
Write-Output "Quick Manual Cleanup"
Write-Output "========================================"
Write-Output ""

# 1. Quick Temp Cleanup
Write-Output "Step 1: Cleaning Temp Files..."
$tempPaths = @(
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp", 
    "C:\Windows\Temp"
)

foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        try {
            $filesRemoved = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
            Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Output "Cleaned: $path (removed ~$filesRemoved files)"
        } catch {
            Write-Output "Could not clean: $path"
        }
    }
}

Write-Output ""
Write-Output "Step 2: Cleaning Recycle Bin..."
try {
    $Shell = New-Object -ComObject Shell.Application
    $RecycleBin = $Shell.Namespace(0xA)
    $RecycleBin.Items() | ForEach-Object { 
        try {
            Remove-Item -Path $_.Path -Force -Recurse -ErrorAction SilentlyContinue
        } catch { }
    }
    Write-Output "Recycle bin emptied"
} catch {
    Write-Output "Could not empty recycle bin"
}

Write-Output ""
Write-Output "========================================"
Write-Output "Manual Duplicate File Cleanup Tips:"
Write-Output "========================================"
Write-Output "For duplicate files, consider:"
Write-Output "1. Use Windows Search with 'dup:' filter"
Write-Output "2. Check Downloads folder for duplicate downloads"
Write-Output "3. Use tools like Duplicate Cleaner or CCleaner"
Write-Output "4. Manually review folders like Documents/Pictures"
Write-Output ""
Write-Output "Quick cleanup completed!"