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
$roamFileLeft = @(Get-ChildItem $roamingProbe -Force -ErrorAction SilentlyContinue -File).Count
Assert ($roamFileLeft -eq 0) "Roaming AppData cache probe files deleted silently"
$recentCountAfter2 = @(Get-ChildItem $recentPath -Force -ErrorAction SilentlyContinue).Count
Assert ($recentCountAfter -eq $recentCountAfter2) "Roaming sweep did not touch Recent ($recentCountAfter2 items)"
Assert (-not (Test-CleanMgrCategorySelected -Name 'DownloadsFolder')) "CleanMgr DownloadsFolder category excluded"
Assert (-not (Test-CleanMgrCategorySelected -Name 'Downloaded Program Files')) "CleanMgr downloaded category excluded"
Assert (Test-CleanMgrCategorySelected -Name 'Temporary Files') "CleanMgr non-download category selected"
Assert (-not ($script:ChromiumCleanFiles -contains 'Web Data')) "Chromium autofill Web Data is protected"
Assert (-not ($script:ChromiumCleanFiles -contains 'Current Tabs')) "Chromium open-tab restore files are protected"
Assert (-not ($script:GeckoCleanFiles -contains 'formhistory.sqlite')) "Firefox autofill form history is protected"
Assert (-not ($script:GeckoCleanFiles -contains 'places.sqlite')) "Firefox bookmarks database is protected"
Assert (-not ($script:GeckoCleanFiles -contains 'downloads.sqlite')) "Firefox downloads database is protected"
Assert (-not ($script:ChromiumCleanFiles -contains 'Login Data')) "Chromium passwords are protected"

$chromiumRoots = @(Find-ChromiumBrowserRoots)
$webviewHit = @($chromiumRoots | Where-Object { $_ -match 'EBWebView|CefCache|DDGWebView|EdgeWebView' })
Assert ($webviewHit.Count -eq 0) "Embedded WebView folders are not treated as browsers"
Assert ($chromiumRoots.Count -lt 15) "Browser discovery stays on real browsers, not a full AppData scan"

$aiPaths = @(Get-AiCacheTargetPaths)
$cursorCache = Join-Path $env:APPDATA 'Cursor\Cache'
if (Test-Path $cursorCache) {
    Assert (@($aiPaths | Where-Object { $_ -ieq $cursorCache }).Count -gt 0) "Cursor Cache is in the AI target list"
}

$kiroCache = Join-Path $env:APPDATA 'kiro\Cache'
New-Item -ItemType Directory -Path $kiroCache -Force | Out-Null
$kiroProbe = Join-Path $kiroCache 'MyCleanPC_AiProbe.tmp'
Set-Content -Path $kiroProbe -Value 'ai-probe'
$kiroNested = Join-Path $env:APPDATA 'kiro\NestedCacheProbe\GPUCache'
New-Item -ItemType Directory -Path $kiroNested -Force | Out-Null
$kiroNestedProbe = Join-Path $kiroNested 'MyCleanPC_AiNestedProbe.tmp'
Set-Content -Path $kiroNestedProbe -Value 'ai-nested-probe'
$aiPaths = @(Get-AiCacheTargetPaths)
Assert (@($aiPaths | Where-Object { $_ -ieq $kiroCache }).Count -gt 0) "Kiro Cache is in the AI target list"
Assert (@($aiPaths | Where-Object { $_ -ieq $kiroNested }).Count -gt 0) "Nested AI GPUCache is discovered"
Close-AiToolProcesses | Out-Null
Remove-DirectorySilent -LiteralPath $kiroCache -KeepContainer | Out-Null
Remove-DirectorySilent -LiteralPath $kiroNested -KeepContainer | Out-Null
Assert (-not (Test-Path $kiroProbe)) "Kiro Cache probe deleted"
Assert (-not (Test-Path $kiroNestedProbe)) "Nested AI GPUCache probe deleted"

$chromeRoot = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'
if (Test-Path $chromeRoot) {
    $chromeCache = Join-Path $chromeRoot 'Default\Cache'
    New-Item -ItemType Directory -Path $chromeCache -Force | Out-Null
    $chromeProbe = Join-Path $chromeCache 'MyCleanPC_BrowserProbe.tmp'
    Set-Content -Path $chromeProbe -Value 'browser-probe'
    $loginData = Join-Path $chromeRoot 'Default\Login Data'
    $loginExisted = Test-Path $loginData
    Close-BrowserProcesses | Out-Null
    Clear-ChromiumBrowserCache $chromeRoot
    Assert (-not (Test-Path $chromeProbe)) "Chrome Cache probe deleted like Ctrl+Shift+Delete"
    if ($loginExisted) {
        Assert (Test-Path $loginData) "Chrome Login Data (passwords) still present"
    }
}

$est = Get-CleanupEstimate
Assert ($est.Count -ge 0) "Cleanup estimate returns a count"
if ($est.Count -gt 0) {
    Assert ($est.TotalBytes -gt 0) "Cleanup estimate total is not zero when locations exist"
    $topSum = [long]0
    foreach ($hit in @($est.Top5)) { $topSum += [long]$hit.Bytes }
    Assert ($est.TotalBytes -ge $topSum) "Cleanup estimate total is at least the top-5 sum"
}

Reset-ClosedAppLabels
Assert ((Get-MyCleanPCReadyMessage) -match 'You can now use') "Ready notice mentions apps can be used"
Assert ((Get-MyCleanPCBusyMessage) -match 'notice when you can use') "Busy notice promises a follow-up when apps are ready"
Add-ClosedAppLabel 'chrome'
Add-ClosedAppLabel 'Kiro'
$ready = Get-MyCleanPCReadyMessage
Assert ($ready -match 'Google Chrome') "Ready notice names closed Chrome"
Assert ($ready -match 'Kiro') "Ready notice names closed Kiro"
Assert ((Get-MyCleanPCBusyMessage) -match 'Google Chrome') "Busy notice names closed Chrome"
$env:MYCLEANPC_NO_TOAST = '1'
Show-MyCleanPCNotice -Title 't' -Body 'b' | Out-Null
Assert $true "User notice helper runs without throwing when toasts are muted"
Remove-Item Env:MYCLEANPC_NO_TOAST -ErrorAction SilentlyContinue
Reset-ClosedAppLabels

Write-Host ""
Write-Host "Summary: $(@($results | Where-Object { $_.Pass }).Count)/$($results.Count) passed"
if (Test-Path $tempProbeRoot) {
    Remove-SafePathWithRetry -LiteralPath $tempProbeRoot -Recurse | Out-Null
}
if (Test-Path $roamingProbeRoot) {
    Remove-SafePathWithRetry -LiteralPath $roamingProbeRoot -Recurse | Out-Null
}
if (@($results | Where-Object { -not $_.Pass }).Count -gt 0) { exit 1 }
