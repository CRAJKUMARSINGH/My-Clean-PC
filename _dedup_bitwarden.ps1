$ErrorActionPreference = 'Stop'

function Get-UrlRoot {
    param([string]$url)
    if ([string]::IsNullOrWhiteSpace($url)) { return '__NOURL__' }
    $u = $url.Trim()
    if ($u -match '[?#]') { $u = $u -replace '[?#].*$','' }
    if ($u -match '^(vivaldi|chrome|about|moz|edge)://') { return $u.ToLowerInvariant() }
    if ($u -notmatch '^[a-z]+://') { $u = "http://$u" }
    try {
        $uri = [uri]$u
        $host = $uri.DnsSafeHost
        if ($host -match '^www\.(.+)$') { $host = $Matches[1] }
        $host = $host -replace ':\d+$',''
        return $host.ToLowerInvariant()
    } catch { return $u.ToLowerInvariant() }
}

function Format-CsvField {
    param([string]$s)
    if ($null -eq $s) { $s = '' }
    if ($s -match '[",\r\n]') { return '"' + ($s -replace '"','""') + '"' }
    return '"' + $s + '"'
}

function Parse-CsvLine([string]$line){
    $fields = @()
    $cur = ''
    $inQuotes = $false
    for ($c=0; $c -lt $line.Length; $c++) {
        $ch = $line[$c]
        if ($inQuotes) {
            if ($ch -eq '"') {
                if ($c+1 -lt $line.Length -and $line[$c+1] -eq '"') { $cur += '"'; $c++ }
                else { $inQuotes = $false }
            } else { $cur += $ch }
        } else {
            if ($ch -eq '"') { $inQuotes = $true }
            elseif ($ch -eq ',') { $fields += $cur; $cur = '' }
            else { $cur += $ch }
        }
    }
    $fields += $cur
    while ($fields.Count -lt 5) { $fields += '' }
    if ($fields.Count -gt 5) {
        $note = ($fields[4..($fields.Count-1)] -join ',')
        $fields = @($fields[0],$fields[1],$fields[2],$fields[3],$note)
    }
    return $fields
}

$in  = 'e:\Rajkumar\My-Clean-PC\BITWARDEN_FINAL_CLEAN.csv'
$out = 'e:\Rajkumar\My-Clean-PC\BITWARDEN_FINAL_CLEAN.deduped.csv'
$rep = 'e:\Rajkumar\My-Clean-PC\BITWARDEN_FINAL_CLEAN.dedup-report.txt'

$lines = [System.IO.File]::ReadAllLines($in)
$header = $lines[0]
$rows   = @()
for ($i=1; $i -lt $lines.Count; $i++) {
    if ([string]::IsNullOrWhiteSpace($lines[$i])) { continue }
    $f = Parse-CsvLine $lines[$i]
    $rows += [PSCustomObject]@{
        LineNo   = $i+1
        Name     = $f[0]
        Url      = $f[1]
        Username = $f[2]
        Password = $f[3]
        Note     = $f[4]
    }
}
$totalIn = $rows.Count

$kept     = New-Object System.Collections.Generic.List[object]
$removed  = New-Object System.Collections.Generic.List[object]

$seenPWCI = @{}
$seenPWEX = @{}
$seenNAME = @{}
$seenANYURL = @{}

:nextRow foreach ($r in $rows) {
    $nameCI  = if ($r.Name)     { $r.Name.ToLowerInvariant() }     else { '' }
    $userCI  = if ($r.Username) { $r.Username.ToLowerInvariant() } else { '' }
    $urlRoot = Get-UrlRoot $r.Url
    $pw      = $r.Password
    $pwCI    = if ($pw) { $pw.ToLowerInvariant() } else { '' }

    # Stage 1: username-CI + urlRoot + password-CI  (same cred, case diff anywhere -> dup)
    $k = "$userCI||$urlRoot||$pwCI"
    if ($seenPWCI.ContainsKey($k)) {
        $removed.Add([PSCustomObject]@{Stage='S1_userCI_urlRoot_pwCI'; Row=$r})
        continue nextRow
    }

    # Stage 2: username-CI + urlRoot + password-EXACT  (stage 1 covers this, kept as secondary)
    $k2 = "$userCI||$urlRoot||$pw"
    if ($seenPWEX.ContainsKey($k2)) {
        $removed.Add([PSCustomObject]@{Stage='S2_userCI_urlRoot_pwEXACT'; Row=$r})
        continue nextRow
    }

    # Stage 3: username-CI + password-CI + name-CI  (ignore URL subpath entirely - google.com vs mail.google.com same user/pw = same google account)
    # Only apply if urlRoot is in same base domain OR one has no URL
    $k3 = "$userCI||$nameCI||$pwCI"
    if ($seenNAME.ContainsKey($k3)) {
        $removed.Add([PSCustomObject]@{Stage='S3_userCI_nameCI_pwCI'; Row=$r})
        continue nextRow
    }

    # register all keys and keep
    $seenPWCI[$k]   = $r.LineNo
    $seenPWEX[$k2]  = $r.LineNo
    $seenNAME[$k3]  = $r.LineNo
    $kept.Add($r)
}

$totalOut  = $kept.Count
$totalDups = $totalIn - $totalOut

# ---- write output CSV ----
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine($header)
foreach ($p in $kept) {
    $line = (Format-CsvField $p.Name) + ',' +
            (Format-CsvField $p.Url)  + ',' +
            (Format-CsvField $p.Username) + ',' +
            (Format-CsvField $p.Password) + ',' +
            (Format-CsvField $p.Note)
    [void]$sb.AppendLine($line)
}
[System.IO.File]::WriteAllText($out, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))

# ---- report ----
$repSb = New-Object System.Text.StringBuilder
[void]$repSb.AppendLine('Bitwarden CSV Deduplicate Report')
[void]$repSb.AppendLine('==============================')
[void]$repSb.AppendLine("Input : $in")
[void]$repSb.AppendLine("Output: $out")
[void]$repSb.AppendLine('')
[void]$repSb.AppendLine('Duplicate Definition (all 3 stages keep the FIRST occurrence):')
[void]$repSb.AppendLine('  S1  username (case-insensitive) + URL root domain + password (case-insensitive)')
[void]$repSb.AppendLine('      -> a@B.com == A@b.com AND /v3/signin/identifier == root accounts.google.com')
[void]$repSb.AppendLine('  S2  username-CI + urlRoot + password-EXACT')
[void]$repSb.AppendLine('  S3  username-CI + name-CI + password-CI  (ignore URL subpath)')
[void]$repSb.AppendLine('')
[void]$repSb.AppendLine("Rows in input   : $totalIn")
[void]$repSb.AppendLine("Rows in output  : $totalOut")
[void]$repSb.AppendLine('Duplicates removed: ' + $totalDups)
[void]$repSb.AppendLine('')

$byStage = $removed | Group-Object Stage | Sort-Object Name
foreach ($g in $byStage) {
    [void]$repSb.AppendLine( "--- $($g.Name)  ->  $($g.Count) rows deleted" )
    foreach ($x in $g.Group) {
        $rr = $x.Row
        $nm = if ($rr.Name.Length -gt 50) { $rr.Name.Substring(0,50) } else { $rr.Name }
        [void]$repSb.AppendLine( "  Del line $($rr.LineNo.ToString().PadLeft(4)) | name=$nm")
        [void]$repSb.AppendLine( "                       | user=$($rr.Username) | urlRoot=$(Get-UrlRoot $rr.Url)")
    }
    [void]$repSb.AppendLine('')
}

# Flagged: same userCI + same urlRoot but DIFFERENT password -> NOT deleted. Manual review only.
$flagGroups = @{}
foreach ($p in $kept) {
    $userCI  = if ($p.Username) { $p.Username.ToLowerInvariant() } else { '' }
    $urlRoot = Get-UrlRoot $p.Url
    $k = "$userCI||$urlRoot"
    if (-not $flagGroups.ContainsKey($k)) { $flagGroups[$k] = @() }
    $flagGroups[$k] += $p
}
$flagCount = 0
foreach ($kv in $flagGroups.GetEnumerator()) { if ($kv.Value.Count -gt 1) { $flagCount++ } }

if ($flagCount -gt 0) {
    [void]$repSb.AppendLine( ('--- FLAGGED (NOT DELETED) - same user+site DIFFERENT password -> manual review: ' + $flagCount + ' groups') )
    [void]$repSb.AppendLine('    (Different passwords on the same logical account. These are NOT auto-deleted')
    [void]$repSb.AppendLine('     because they may represent real different passwords over time / test creds)')
    foreach ($kv in $flagGroups.GetEnumerator()) {
        if ($kv.Value.Count -le 1) { continue }
        $arr = $kv.Value
        [void]$repSb.AppendLine( "  [$($arr.Count) passwords]  root=$(Get-UrlRoot $arr[0].Url)  user=$($arr[0].Username)" )
        foreach ($a in $arr) {
            [void]$repSb.AppendLine( "     line $($a.LineNo)  pw=$($a.Password)  name=$($a.Name)" )
        }
    }
}

[System.IO.File]::WriteAllText($rep, $repSb.ToString(), [System.Text.UTF8Encoding]::new($false))

Write-Host '=================================================' -ForegroundColor Cyan
Write-Host '  BITWARDEN DEDUPLICATE COMPLETE' -ForegroundColor Cyan
Write-Host '=================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host "Rows in:   $totalIn"
Write-Host "Rows out:  $totalOut"
Write-Host ("Duplicates DELETED: $totalDups")  -ForegroundColor Red
Write-Host ''
Write-Host 'By stage:'
$byStage | ForEach-Object { Write-Host "  $($_.Name) : $($_.Count)" }
Write-Host ''
Write-Host "Output CSV  : $out"
Write-Host "Report (txt): $rep"
Write-Host ''
if ($flagCount -gt 0) {
    Write-Host ("Manual review groups (NOT deleted, diff passwords same site): $flagCount") -ForegroundColor Yellow
}
Write-Host ''
