# Test script to verify temp file deletion actually works
$ErrorActionPreference = "SilentlyContinue"

Write-Host "Testing temp file deletion..." -ForegroundColor Cyan

# Create test temp files
$testDir = Join-Path $env:TEMP "MyCleanPC-Test"
if (-not (Test-Path $testDir)) {
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
}

# Create some test files
1..10 | ForEach-Object {
    "Test file $_" | Out-File (Join-Path $testDir "test$_.txt")
}

Write-Host "Created 10 test files in: $testDir" -ForegroundColor Yellow
Write-Host "Files before deletion:" -ForegroundColor Yellow
Get-ChildItem $testDir | ForEach-Object { Write-Host "  $($_.Name)" }

# Try deletion with PowerShell
try {
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction Stop
    Write-Host "PowerShell deletion: SUCCESS" -ForegroundColor Green
} catch {
    Write-Host "PowerShell deletion: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    # Try with cmd.exe
    try {
        $null = cmd /c "rd /s /q `"$testDir`"" 2>&1
        if (-not (Test-Path $testDir)) {
            Write-Host "cmd.exe deletion: SUCCESS" -ForegroundColor Green
        } else {
            Write-Host "cmd.exe deletion: FAILED" -ForegroundColor Red
        }
    } catch {
        Write-Host "cmd.exe deletion: FAILED" -ForegroundColor Red
    }
}

# Verify
if (Test-Path $testDir) {
    Write-Host "Directory still exists after deletion attempt!" -ForegroundColor Red
    Write-Host "Remaining files:" -ForegroundColor Yellow
    Get-ChildItem $testDir -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $($_.Name)" }
} else {
    Write-Host "Directory successfully deleted!" -ForegroundColor Green
}

Write-Host "`nTest complete." -ForegroundColor Cyan
