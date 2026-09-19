# Smoke test for clean-pc-core.ps1 (real temp deletion + Quick Access protection)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'clean-pc-core.ps1')

$results = @()
function Assert([bool]$cond, [string]$name) {
    $script:results += [pscustomobject]@{ Test = $name; Pass = $cond }
    Write-Host ("[{0}] {1}" -f $(if ($cond) { 'PASS' } else { 'FAIL' }), $name)
}

$temp = [Environment]::ExpandEnvironmentVariables('%LOCALAPPDATA%\Temp')
$tempProbeRoot = Join-Path $temp 'MyCleanPC_TestProbeRoot'
$tempProbeDir = Join-Path $tempProbeRoot 'PromptFreeDelete'
New-Item -ItemType Directory -Path $tempProbeDir -Force | Out-Null
1..5 | ForEach-Object { Set-Content -Path (Join-Path $tempProbeDir "file$_.tmp") -Value 'junk' }

$roamingProbeRoot = Join-Path ([Environment]::ExpandEnvironmentVariables('%APPDATA%')) 'MyCleanPC_TestProbeRoot'
$roamingProbe = Join-Path $roamingProbeRoot 'DemoApp\Cache'
New-Item -ItemType Directory -Path $roamingProbe -Force | Out-Null
1..3 | ForEach-Object { Set-Content -Path (Join-Path $roamingProbe "roam$_.tmp") -Value 'junk' }

$recentPath = [Environment]::ExpandEnvironmentVariables('%APPDATA%\Microsoft\Windows\Recent')
$autoDestPath = Join-Path $recentPath 'AutomaticDestinations'
$customDestPath = Join-Path $recentPath 'CustomDestinations'
$recentCountBefore = @(Get-ChildItem $recentPath -Force -ErrorAction SilentlyContinue).Count
$pinStateCountBefore = @(
    Get-ChildItem $autoDestPath -Force -ErrorAction SilentlyContinue
    Get-ChildItem $customDestPath -Force -ErrorAction SilentlyContinue
).Count

Clear-SafeTempTree $tempProbeRoot | Out-Null
Assert (-not (Test-Path $tempProbeDir)) "Temp probe folder deleted silently"

$recentCountAfter = @(Get-ChildItem $recentPath -Force -ErrorAction SilentlyContinue).Count
$pinStateCountAfter = @(
    Get-ChildItem $autoDestPath -Force -ErrorAction SilentlyContinue
    Get-ChildItem $customDestPath -Force -ErrorAction SilentlyContinue
).Count
Assert ($pinStateCountBefore -eq $pinStateCountAfter) "Quick Access pin-state files unchanged ($pinStateCountBefore items)"
Assert ($recentCountBefore -eq $recentCountAfter) "Recent folder count unchanged ($recentCountBefore items)"

$rc = Clear-AppDataJunkSweep $roamingProbeRoot
Assert (-not (Test-Path $roamingProbe)) "Roaming AppData cache probe deleted silently"
$recentCountAfter2 = @(Get-ChildItem $recentPath -Force -ErrorAction SilentlyContinue).Count
Assert ($recentCountAfter -eq $recentCountAfter2) "Roaming sweep did not touch Recent ($recentCountAfter2 items)"
Assert (-not (Test-CleanMgrCategorySelected -Name 'DownloadsFolder')) "CleanMgr DownloadsFolder category excluded"
Assert (-not (Test-CleanMgrCategorySelected -Name 'Downloaded Program Files')) "CleanMgr downloaded category excluded"
Assert (Test-CleanMgrCategorySelected -Name 'Temporary Files') "CleanMgr non-download category selected"
Assert (-not ($script:ChromiumCleanFiles -contains 'Web Data')) "Chromium autofill Web Data is protected"
Assert (-not ($script:ChromiumCleanFiles -contains 'Current Tabs')) "Chromium open-tab restore files are protected"
Assert (-not ($script:GeckoCleanFiles -contains 'formhistory.sqlite')) "Firefox autofill form history is protected"
Assert (-not ($script:GeckoCleanFiles -contains 'places.sqlite')) "Firefox bookmarks database is protected"

Write-Host ""
Write-Host "Summary: $(@($results | Where-Object { $_.Pass }).Count)/$($results.Count) passed"
if (Test-Path $tempProbeRoot) {
    Remove-SafePathWithRetry -LiteralPath $tempProbeRoot -Recurse | Out-Null
}
if (Test-Path $roamingProbeRoot) {
    Remove-SafePathWithRetry -LiteralPath $roamingProbeRoot -Recurse | Out-Null
}
if (@($results | Where-Object { -not $_.Pass }).Count -gt 0) { exit 1 }
