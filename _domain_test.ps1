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

function Domain-IsSameProvider {
    param([string]$a, [string]$b)
    if ($a -eq $b) { return $true }
    $groups = @(
        @('accounts.google.com','google.com','gmail.com','mail.google.com','accounts.youtube.com','workspace.google.com','myaccount.google.com'),
        @('login.yahoo.com','mail.yahoo.com','yahoo.com','www.yahoo.com'),
        @('mail.rediff.com','rediffmail.com','mypage.rediff.com','register.rediff.com','register.rediff.com/utilities/newforgot','f4email.rediff.com'),
        @('mail.tutanota.com','app.tuta.com','tutanota.com','mail.tuta.com','tuta.com'),
        @('passport.yandex.com','passport.yandex.ru','yandex.ru','yandex.com','mail.yandex.ru','mail.yandex.com'),
        @('www.trae.ai','trae.ai'),
        @('us-east-1.signin.aws','signin.aws.amazon.com','aws.amazon.com','console.aws.amazon.com'),
        @('www.amazon.in','www.amazon.com','amazon.in','amazon.com'),
        @('www.facebook.com','facebook.com','m.facebook.com'),
        @('chat.openai.com','auth.openai.com','auth0.openai.com','chatgpt.com','openai.com','platform.openai.com'),
        @('accounts.x.ai','x.com','x.ai','www.x.ai'),
        @('chat.deepseek.com','platform.deepseek.com','deepseek.com'),
        @('windsurf.com','www.windsurf.com'),
        @('authenticator.cursor.sh','cursor.com','www.cursor.com'),
        @('accounts.firefox.com','FirefoxAccounts','firefox.com'),
        @('sso.rajasthan.gov.in','ssotest.rajasthan.gov.in'),
        @('paymanager.rajasthan.gov.in','paymanagerddo.rajasthan.gov.in'),
        @('replit.com','www.replit.com'),
        @('github.com','www.github.com','githubuniverse.com'),
        @('www.linkedin.com','linkedin.com'),
        @('www.reddit.com','reddit.com'),
        @('mail.google.com','accounts.google.com','google.com','gmail.com'),
        @('login.live.com','outlook.live.com','microsoft.com','login.microsoftonline.com'),
        @('www.irctc.co.in','www.air.irctc.co.in','www.hotel.irctctourism.com')
    )
    foreach ($g in $groups) {
        if (($g -icontains $a) -and ($g -icontains $b)) { return $true }
    }
    return $false
}

Write-Host '--- Domain-IsSameProvider quick tests:'
$tests = @(
    @('accounts.google.com','gmail.com'),
    @('gmail.com','mail.google.com'),
    @('accounts.google.com','google.com'),
    @('accounts.x.ai','x.com'),
    @('www.trae.ai','trae.ai'),
    @('yandex.ru','yandex.com'),
    @('us-east-1.signin.aws','signin.aws.amazon.com'),
    @('accounts.google.com','replit.com'),     # should be FALSE
    @('github.com','google.com'),               # FALSE
    @('sso.rajasthan.gov.in','ssotest.rajasthan.gov.in')
)
foreach ($t in $tests) {
    $r = Domain-IsSameProvider $t[0] $t[1]
    Write-Host "$($t[0]) <-> $($t[1])  =  $r"
}
