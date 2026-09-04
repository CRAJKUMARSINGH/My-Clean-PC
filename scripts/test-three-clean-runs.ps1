# Three consecutive clean runs against the installed 6-hour task scripts.
# Plants AI + browser + temp probes each round and verifies they are wiped.
# Also checks that Task Scheduler is set to PT6H. Does not wait 18 hours.

$ErrorActionPreference = 'Stop'
$installDir = Join-Path $env:LOCALAPPDATA 'MyCleanPC'
$corePath = Join-Path $installDir 'clean-pc-core.ps1'
$taskPath = Join-Path $installDir 'cleanup_task.ps1'
if (-not (Test-Path $corePath)) { throw "Installed core missing: $corePath" }
if (-not (Test-Path $taskPath)) { throw "Installed task script missing: $taskPath" }

$log = Join-Path $installDir 'three_run_test_log.txt'
function TLog([string]$m) {
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Host $line
    Add-Content -Path $log -Value $line
}

$sched = Get-ScheduledTask -TaskName 'MyCleanPC' -ErrorAction Stop
$interval = [string]$sched.Triggers[0].Repetition.Interval
$intervalOk = ($interval -match 'PT6H') -or ($interval -match '^0?6:00:00')
TLog "Scheduled task MyCleanPC repetition interval: $interval"
if (-not $intervalOk) {
    throw "MyCleanPC task interval is '$interval', expected 6 hours (PT6H)"
}

function New-Probes {
    $probes = @()
    $tempProbe = Join-Path $env:TEMP 'MyCleanPC_IntervalProbe'
    New-Item -ItemType Directory -Path $tempProbe -Force | Out-Null
    $tf = Join-Path $tempProbe 'round.tmp'
    Set-Content $tf 'temp-probe'
    $probes += $tf

    $kiroCache = Join-Path $env:APPDATA 'kiro\Cache'
    New-Item -ItemType Directory -Path $kiroCache -Force | Out-Null
    $kf = Join-Path $kiroCache 'MyCleanPC_AiProbe.tmp'
    Set-Content $kf 'ai-probe'
    $probes += $kf

    $kiroNested = Join-Path $env:APPDATA 'kiro\NestedCacheProbe\GPUCache'
    New-Item -ItemType Directory -Path $kiroNested -Force | Out-Null
    $kn = Join-Path $kiroNested 'MyCleanPC_AiNestedProbe.tmp'
    Set-Content $kn 'ai-nested-probe'
    $probes += $kn

    $cursorCache = Join-Path $env:APPDATA 'Cursor\Cache'
    if (Test-Path (Split-Path $cursorCache -Parent)) {
        TLog "Cursor Cache present; not planting a probe (Cursor stays running so files can stay locked)."
    }

    $chromeCache = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data\Default\Cache'
    if (Test-Path (Split-Path (Split-Path $chromeCache -Parent) -Parent)) {
        New-Item -ItemType Directory -Path $chromeCache -Force | Out-Null
        $bf = Join-Path $chromeCache 'MyCleanPC_BrowserProbe.tmp'
        Set-Content $bf 'chrome-probe'
        $probes += $bf
    }

    $edgeCache = Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data\Default\Cache'
    if (Test-Path (Split-Path (Split-Path $edgeCache -Parent) -Parent)) {
        New-Item -ItemType Directory -Path $edgeCache -Force | Out-Null
        $ef = Join-Path $edgeCache 'MyCleanPC_BrowserProbe.tmp'
        Set-Content $ef 'edge-probe'
        $probes += $ef
    }

    $ffBase = Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles'
    if (Test-Path $ffBase) {
        $prof = Get-ChildItem $ffBase -Directory | Select-Object -First 1
        if ($prof) {
            $ffCache = Join-Path $prof.FullName 'cache2'
            New-Item -ItemType Directory -Path $ffCache -Force | Out-Null
            $ff = Join-Path $ffCache 'MyCleanPC_BrowserProbe.tmp'
            Set-Content $ff 'firefox-probe'
            $probes += $ff
        }
    }

    return $probes
}

$failed = 0
1..3 | ForEach-Object {
    $n = $_
    TLog "===== TEST RUN $n / 3 ====="
    $probes = New-Probes
    TLog ("Planted {0} probe file(s)." -f $probes.Count)
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $taskPath
    $code = $LASTEXITCODE
    TLog "cleanup_task.ps1 exit=$code"
    $alive = @($probes | Where-Object { Test-Path $_ })
    foreach ($p in $probes) {
        if (Test-Path $p) {
            TLog "FAIL still present: $p"
            $script:failed++
        } else {
            TLog "PASS wiped: $p"
        }
    }
    if ($alive.Count -gt 0) {
        TLog "Run $n FAILED ($($alive.Count) probe(s) remain). Retrying targeted wipe for diagnosis."
    } else {
        TLog "Run $n PASSED all probes wiped."
    }
}

if ($failed -gt 0) {
    TLog "SUMMARY FAIL: $failed probe leftover(s) across 3 runs"
    exit 1
}
TLog "SUMMARY PASS: 3 consecutive clean runs wiped AI/browser/temp probes"
exit 0
