$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== SCHEDULED TASK: MyCleanPC-24Min ===" -ForegroundColor Cyan
$t = Get-ScheduledTask -TaskName 'MyCleanPC-24Min'
if ($t) {
    Write-Host "  Task Name: $($t.TaskName)"
    Write-Host "  State:     $($t.State)"
    Write-Host "  Enabled:   $($t.Settings.Enabled)"
    $ti = Get-ScheduledTaskInfo -TaskName 'MyCleanPC-24Min'
    if ($ti) {
        Write-Host "  Last Run:   $($ti.LastRunTime)"
        Write-Host "  Next Run:  $($ti.NextRunTime)"
        Write-Host "  Last Exit:  $($ti.LastTaskResult)"
    }
    $a = $t.Actions[0]
    Write-Host "  Execute:  $($a.Execute)"
    Write-Host "  Args:     $($a.Arguments)"
    $tr = $t.Triggers[0]
    if ($tr.Repetition.Interval) {
        Write-Host "  Interval: Every $($tr.Repetition.Interval)"
    }
} else {
    Write-Host "  ERROR: MyCleanPC-24Min NOT FOUND" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== OTHER TASKS (should be absent) ===" -ForegroundColor Cyan
foreach ($n in @('MyCleanPC-7Min','MyCleanPC-Weekly','MyCleanPC-AI-Cache','24-Silent-Cleaner','MyCleanPC')) {
    $x = Get-ScheduledTask -TaskName $n
    if ($x) {
        Write-Host "  Found: $n  (State: $($x.State))"
    } else {
        Write-Host "  OK:    $n  absent"
    }
}

Write-Host ""
Write-Host "=== INSTALLED SCRIPTS ===" -ForegroundColor Cyan
$d = Join-Path $env:LOCALAPPDATA 'MyCleanPC'
if (Test-Path $d) {
    Get-ChildItem $d -File | ForEach-Object {
        $s = [Math]::Round($_.Length/1KB,1)
        Write-Host "  $($_.Name)   ($s KB,  LastWrite: $($_.LastWriteTime))"
    }
} else {
    Write-Host "  ERROR: $d NOT FOUND" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== SCRIPT DATE CHECK (repo vs installed) ===" -ForegroundColor Cyan
$repo = 'e:\Rajkumar\My-Clean-PC\scripts'
foreach ($f in @('ai-cache-cleaner.ps1','clean-pc-core.ps1','cleanup_task.ps1')) {
    $r = Get-Item (Join-Path $repo $f)
    $i = Get-Item (Join-Path $d $f)
    $ok = if ($i.LastWriteTime -ge $r.LastWriteTime) { 'MATCH (UP-TO-DATE)' } else { 'STALE!' }
    Write-Host "  $f :  Repo=$($r.LastWriteTime)  Installed=$($i.LastWriteTime)  [$ok]"
}

Write-Host ""
Write-Host "=== CHECK: TEMP/PREFETCH 3-PASS CLEANING LINES ===" -ForegroundColor Cyan
$aiFile = Join-Path $d 'ai-cache-cleaner.ps1'
$lines = Get-Content $aiFile
$hitTempAggressive = $false
$hitPrefetch = $false
foreach ($line in $lines) {
    if ($line -match 'Aggressive Temp file cleaning - ALL temp files') { $hitTempAggressive = $true }
    if ($line -match 'Prefetch cleaning - same 3-pass aggressive approach') { $hitPrefetch = $true }
}
Write-Host "  ai-cache-cleaner.ps1  Temp 3-pass (no 2hr limit): $(if ($hitTempAggressive) {'PRESENT'} else {'MISSING - OLD SCRIPT!'})"
Write-Host "  ai-cache-cleaner.ps1  Prefetch 3-pass: $(if ($hitPrefetch) {'PRESENT'} else {'MISSING - OLD SCRIPT!'})"

$coreFile = Join-Path $d 'clean-pc-core.ps1'
$clines = Get-Content $coreFile
$hitPFInRigorous = $false
$hitPF3Pass = $false
foreach ($line in $clines) {
    if ($line -match 'C:\\Windows\\Prefetch"') { $hitPFInRigorous = $true }
    if ($line -match 'Pass 1/3: 3-stage silent wipe') { $hitPF3Pass = $true }
}
Write-Host "  clean-pc-core.ps1  Prefetch in RigorousTemp: $(if ($hitPFInRigorous) {'PRESENT'} else {'MISSING!'})"
Write-Host "  clean-pc-core.ps1  Prefetch STEP4 3-pass: $(if ($hitPF3Pass) {'PRESENT'} else {'MISSING!'})"
