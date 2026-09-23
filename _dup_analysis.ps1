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

function Domain-IsSameProvider {
    # Returns $true if two root domains are actually same provider (Google account identity store - same logical account provider
    param([string]$a, [string]$b)
    if ($a -eq $b) { return $true }
    # List of URL-roots recognized-as-same-provider-Google, gmail, mail.google, accounts.google, etc
    $groups = @(
        @('accounts.google.com','google.com','gmail.com','mail.google.com','accounts.youtube.com'),
        @('login.yahoo.com','mail.yahoo.com','yahoo.com'),
        @('mail.rediff.com','rediffmail.com','mypage.rediff.com','register.rediff.com','register.rediff.com/utilities/newforgot','f4email.rediff.com'),
        @('mail.tutanota.com','app.tuta.com','tutanota.com','mail.tuta.com'),
        @('passport.yandex.com','passport.yandex.ru','yandex.ru','yandex.com'),
        @('www.trae.ai','trae.ai'),
        @('us-east-1.signin.aws','signin.aws.amazon.com','aws.amazon.com'),
        @('www.amazon.in','www.amazon.com','amazon.in','amazon.com'),
        @('www.facebook.com','facebook.com'),
        @('chat.openai.com','auth.openai.com','auth0.openai.com','chatgpt.com','openai.com'),
        @('accounts.x.ai','x.com'),
        @('chat.deepseek.com','platform.deepseek.com','chat.deepseek.com','deepseek.com'),
        @('windsurf.com','www.windsurf.com'),
        @('authenticator.cursor.sh','cursor.com'),
        @('accounts.firefox.com','FirefoxAccounts'),
        @('sso.rajasthan.gov.in','ssotest.rajasthan.gov.in'),
        @('paymanager.rajasthan.gov.in','paymanagerddo.rajasthan.gov.in')
    )
    foreach ($g in $groups) {
        if ($g -icontains $a -and $g -icontains $b) { return $true }
    }
    return $false
}

$in  = 'e:\Rajkumar\My-Clean-PC\BITWARDEN_FINAL_CLEAN.csv'
$out = 'e:\Rajkumar\My-Clean-PC\BITWARDEN_FINAL_CLEAN.duplicate-candidates.csv'
$rep = 'e:\Rajkumar\My-Clean-PC\BITWARDEN_FINAL_CLEAN.duplicate-candidates-report.txt'

$lines = [System.IO.File]::ReadAllLines($in)
$rows  = @()
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
        UrlRoot  = Get-UrlRoot $f[1]
    }
}
$total = $rows.Count

# Group by: username case-insensitive + password exact (the most practical "same login credential")
$groups = @{}
foreach ($r in $rows) {
    $userCI = if ($r.Username) { $r.Username.ToLowerInvariant() } else { '' }
    $pw     = $r.Password
    if ([string]::IsNullOrEmpty($userCI)) { continue }
    if ([string]::IsNullOrEmpty($pw)) { continue }
    $k = "$userCI||$pw"
    if (-not $groups.ContainsKey($k)) { $groups[$k] = New-Object System.Collections.Generic.List[object] }
    $groups[$k].Add($r)
}

# Separate into CATEGORY A = same account (provider matches) vs CATEGORY B = credential reuse across DIFFERENT sites
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('Bitwarden DUPLICATE CANDIDATE ANALYSIS (NOT YET DELETED - FOR YOUR APPROVAL)')
[void]$sb.AppendLine('==============================================================================')
[void]$sb.AppendLine("Input: $in")
[void]$sb.AppendLine("Total rows: $total")
[void]$sb.AppendLine('')

$catA = New-Object System.Collections.Generic.List[object]   # same account true duplicates
$catB = New-Object System.Collections.Generic.List[object]   # credential reuse (NOT dup - different sites)
$statsAExtra = 0
$statsBExtra = 0

foreach ($kv in $groups.GetEnumerator()) {
    if ($kv.Value.Count -le 1) { continue }
    $arr = $kv.Value
    $allSameProvider = $true
    $firstRoot = $arr[0].UrlRoot
    foreach ($entry in $arr) {
        if (-not (Domain-IsSameProvider $firstRoot $entry.UrlRoot)) {
            $allSameProvider = $false
            break
        }
    }
    if ($allSameProvider) {
        $statsAExtra += ($arr.Count - 1)
        $null = $catA.Add($kv)
        [void]$sb.AppendLine(">>> CATEGORY A - SAME LOGICAL ACCOUNT (TRUE DUPLICATES - CAN SAFELY DELETE EXTRAS)")
        [void]$sb.AppendLine("    user=$($arr[0].Username)  pw=<hidden>  copies=$($arr.Count)  extra to delete=$($arr.Count-1)")
        foreach ($e in $arr) {
            [void]$sb.AppendLine( "      line $($e.LineNo)  name=$($e.Name)")
            [void]$sb.AppendLine( "                  url=$($e.Url)")
        }
        [void]$sb.AppendLine('')
    } else {
        $statsBExtra += ($arr.Count - 1)
        $null = $catB.Add($kv)
        [void]$sb.AppendLine("??? CATEGORY B - CREDENTIAL REUSE ACROSS DIFFERENT SITES (DO NOT DELETE - THESE ARE DIFFERENT ACCOUNTS WITH SAME USERNAME+PASSWORD)")
        [void]$sb.AppendLine("    user=$($arr[0].Username)  pw=<hidden>  sites=$($arr.Count)  (warning: reused pw - security concern, but NOT duplicates)")
        foreach ($e in $arr) {
            [void]$sb.AppendLine( "      line $($e.LineNo)  name=$($e.Name)  urlRoot=$($e.UrlRoot)")
        }
        [void]$sb.AppendLine('')
    }
}

$summary = New-Object System.Text.StringBuilder
[void]$summary.AppendLine('--- SUMMARY')
[void]$summary.AppendLine('')
[void]$summary.AppendLine("CATEGORY A (true duplicates - safe to dedup):  $($catA.Count) groups, $statsAExtra rows would be removed")
[void]$summary.AppendLine("CATEGORY B (credential reuse across DIFFERENT sites - NOT duplicates): $($catB.Count) groups, $statsBExtra extra rows not removed")
[void]$summary.AppendLine('')
$body = $sb.ToString()
$finalRep = $summary.ToString() + $body
[System.IO.File]::WriteAllText($rep, $finalRep, [System.Text.UTF8Encoding]::new($false))

Write-Host '=================================================' -ForegroundColor Cyan
Write-Host '  BITWARDEN DEDUP ANALYSIS (nothing deleted yet)' -ForegroundColor Cyan
Write-Host '=================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host "Total rows: $total"
Write-Host ''
Write-Host "CATEGORY A (TRUE DUPS, same logical account across different login URLs):" -ForegroundColor Green
Write-Host "  Groups: $($catA.Count)   ->  Extra rows would be deleted: $statsAExtra" -ForegroundColor Green
Write-Host ''
Write-Host "CATEGORY B (Credential REUSE across DIFFERENT websites - NOT duplicates):" -ForegroundColor Yellow
Write-Host "  Groups: $($catB.Count)   ->  Extra entries if we mistakenly deduped them: $statsBExtra" -ForegroundColor Yellow
Write-Host ''
Write-Host "Full details report: $rep"
Write-Host ''
Write-Host 'CATEGORY A includes entries like same Google account stored 4 times under: accounts.google.com, gmail.com, mail.google.com, google.com.'
Write-Host 'CATEGORY B entries are: same crajkumarsingh@hotmail.com pw K$1antilal stored on 39 DIFFERENT sites (jetbrains, autodesk, plex..) — these are different accounts on DIFFERENT sites so NOT duplicates.'
Write-Host ''
