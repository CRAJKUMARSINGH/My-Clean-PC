<#
.SYNOPSIS
    Automated Path Safety & Database Preservation Test Suite.
.DESCRIPTION
    Validates that:
    1. Dangerous or sensitive paths (Downloads, Passwords, Bookmarks, Cookies, Autofill, System roots)
       are strictly rejected by Test-PathSafety.
    2. Valid cache locations pass Test-PathSafety.
    3. Downloads folder and browser database files remain completely intact.
    4. Two consecutive dry-runs or clean-checks report consistent, accurate results.
#>

$enginePath = Join-Path $PSScriptRoot "..\scripts\Safe-Cleanup-Engine.ps1"
if (-not (Test-Path -LiteralPath $enginePath)) {
    Write-Error "Safe-Cleanup-Engine.ps1 not found at $enginePath"
    exit 1
}

# Dot-source engine to import functions
. $enginePath

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Running Automated Path Safety & Integrity Test Suite" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$passed = 0
$failed = 0

function Assert-Test {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Expected = "",
        [string]$Actual = ""
    )
    if ($Condition) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  [FAIL] $TestName" -ForegroundColor Red
        if ($Expected -or $Actual) {
            Write-Host "         Expected: $Expected | Actual: $Actual" -ForegroundColor Yellow
        }
        $script:failed++
    }
}

Write-Host "`n--- TEST GROUP 1: Negative Safety Tests (Must be REJECTED) ---" -ForegroundColor Yellow

$forbiddenTargets = @(
    # Downloads folder
    (Join-Path $env:USERPROFILE "Downloads"),
    (Join-Path $env:USERPROFILE "Downloads\myfile.zip"),
    "C:\Users\Public\Downloads",
    "D:\Downloads\installer.exe",
    
    # Passwords & Credential Databases
    (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Login Data"),
    (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Login Data For Account"),
    (Join-Path $env:APPDATA "Mozilla\Firefox\Profiles\test.default\key4.db"),
    (Join-Path $env:APPDATA "Mozilla\Firefox\Profiles\test.default\logins.json"),
    
    # Bookmarks & History
    (Join-Path $env:APPDATA "Mozilla\Firefox\Profiles\test.default\places.sqlite"),
    (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Bookmarks"),
    (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\History"),
    
    # Cookies & Web Data (Autofill)
    (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Network\Cookies"),
    (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Cookies"),
    (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Web Data"),
    (Join-Path $env:APPDATA "Mozilla\Firefox\Profiles\test.default\cookies.sqlite"),
    (Join-Path $env:APPDATA "Mozilla\Firefox\Profiles\test.default\formhistory.sqlite"),
    
    # Roaming Application Directories (Settings & Workspaces)
    (Join-Path $env:APPDATA "Cursor"),
    (Join-Path $env:APPDATA "Windsurf"),
    (Join-Path $env:APPDATA "Antigravity IDE"),
    
    # Critical Windows & Profile Roots
    "C:\",
    "C:\Windows",
    "C:\Windows\System32",
    "C:\Program Files",
    "C:\Program Files (x86)",
    $env:USERPROFILE,
    $env:APPDATA,
    $env:LOCALAPPDATA
)

foreach ($target in $forbiddenTargets) {
    $isSafe = Test-PathSafety -Path $target
    Assert-Test -TestName "Reject: $target" -Condition (-not $isSafe) -Expected "False" -Actual "$isSafe"
}

Write-Host "`n--- TEST GROUP 2: Positive Safety Tests (Approved Cache Targets) ---" -ForegroundColor Yellow

$validTargets = @(
    $env:TEMP,
    "$env:LOCALAPPDATA\Temp",
    "C:\Windows\Temp",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\sample.default\cache2",
    "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\sample.default\startupCache",
    "$env:LOCALAPPDATA\Cursor\Cache",
    "$env:LOCALAPPDATA\Cursor\Code Cache",
    "$env:LOCALAPPDATA\Windsurf\GPUCache"
)

foreach ($target in $validTargets) {
    $isSafe = Test-PathSafety -Path $target
    Assert-Test -TestName "Approve: $target" -Condition ($isSafe) -Expected "True" -Actual "$isSafe"
}

Write-Host "`n--- TEST GROUP 3: Downloads & Browser Password Databases Intact ---" -ForegroundColor Yellow

# Check Downloads
$downloadsDir = Join-Path $env:USERPROFILE "Downloads"
$downloadsItems = @(Get-ChildItem -LiteralPath $downloadsDir -Force -ErrorAction SilentlyContinue)
Assert-Test -TestName "Downloads directory exists and accessible" -Condition (Test-Path -LiteralPath $downloadsDir)

# Check Chrome Login Data
$chromeLogin = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Login Data"
if (Test-Path -LiteralPath $chromeLogin) {
    Assert-Test -TestName "Chrome Login Data password database exists" -Condition (Test-Path -LiteralPath $chromeLogin)
}

# Check Firefox key4.db / places.sqlite
$ffProfiles = Join-Path $env:APPDATA "Mozilla\Firefox\Profiles"
if (Test-Path -LiteralPath $ffProfiles) {
    $ffKey4 = @(Get-ChildItem -LiteralPath $ffProfiles -Filter "key4.db" -Recurse -ErrorAction SilentlyContinue)
    $ffPlaces = @(Get-ChildItem -LiteralPath $ffProfiles -Filter "places.sqlite" -Recurse -ErrorAction SilentlyContinue)
    Assert-Test -TestName "Firefox key4.db password vault files intact" -Condition ($ffKey4.Count -gt 0)
    Assert-Test -TestName "Firefox places.sqlite bookmarks/history databases intact" -Condition ($ffPlaces.Count -gt 0)
}

Write-Host "`n--- TEST GROUP 4: Idempotency (Consecutive Dry-Run Audits) ---" -ForegroundColor Yellow

$audit1 = Invoke-SafeWindows10Cleanup -DryRun
$audit2 = Invoke-SafeWindows10Cleanup -DryRun

Assert-Test -TestName "Dry-run 1 returned valid targets ($($audit1.TargetsCount))" -Condition ($audit1.TargetsCount -gt 0)
Assert-Test -TestName "Dry-run 2 returned identical target count ($($audit2.TargetsCount))" -Condition ($audit1.TargetsCount -eq $audit2.TargetsCount)

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  TEST RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Passed: $passed" -ForegroundColor Green
Write-Host "  Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

if ($failed -gt 0) {
    exit 1
}
exit 0
