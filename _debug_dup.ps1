# Debug: show which canonical keys actually collide
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

$in  = 'e:\Rajkumar\My-Clean-PC\BITWARDEN_FINAL_CLEAN.csv'
$lines = [System.IO.File]::ReadAllLines($in)
$rows = @()
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

Write-Host "Total rows: $($rows.Count)"

# Case 1: same user+password, ANY URL root (gmail.com vs google.com vs accounts.google.com same user/pw)
# These are the SAME credential across different URLs for the same provider
Write-Host ''
Write-Host '--- CHECK 1: same user case-insensitive + same password exact, any URL ---'
$d = @{}
foreach ($r in $rows) {
    $userCI  = if ($r.Username) { $r.Username.ToLowerInvariant() } else { '' }
    $pw      = $r.Password
    if ([string]::IsNullOrEmpty($userCI)) { continue }
    if ([string]::IsNullOrEmpty($pw)) { continue }
    $k = "$userCI||$pw"
    if (-not $d.ContainsKey($k)) { $d[$k] = @() }
    $d[$k] += $r
}
$countDup1 = 0
foreach ($kv in $d.GetEnumerator()) {
    if ($kv.Value.Count -gt 1) {
        $countDup1 += ($kv.Value.Count - 1)
        $arr = $kv.Value
        Write-Host "  [$($arr.Count) copies] user=$($arr[0].Username)  pw=$($arr[0].Password)"
        foreach ($a in $arr) {
            $root = Get-UrlRoot $a.Url
            Write-Host "      line $($a.LineNo)  name=$($a.Name)  urlRoot=$root"
        }
    }
}
Write-Host "Total dup candidates (CHECK1): $countDup1"

Write-Host ''
Write-Host '--- CHECK 2: exact full row match byte-for-byte (raw line strings) ---'
$d2 = @{}
for ($i=1; $i -lt $lines.Count; $i++) {
    $raw = $lines[$i]
    if ([string]::IsNullOrWhiteSpace($raw)) { continue }
    if (-not $d2.ContainsKey($raw)) { $d2[$raw] = @() }
    $d2[$raw] += ($i+1)
}
$countDup2 = 0
foreach ($kv in $d2.GetEnumerator()) {
    if ($kv.Value.Count -gt 1) {
        $countDup2 += ($kv.Value.Count - 1)
        Write-Host "  Exact dup on lines: $($kv.Value -join ', ')"
    }
}
Write-Host "Exact byte dup rows: $countDup2"
