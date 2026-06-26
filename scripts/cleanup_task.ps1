$logFile = "C:\Scripts\cleanup_log.txt"

function Write-Log {
    param([string]$Message)
    Add-Content -Path $logFile -Value "[$( Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ErrorAction SilentlyContinue
}

function Remove-Items {
    param([string]$Path, [string]$Label)
    if (Test-Path $Path) {
        Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "$Label cleaned."
    } else {
        Write-Log "$Label path not found, skipped."
    }
}

function Run-Cleanup {
    Write-Log "===== Cleanup Started ====="

    # ── User Temp ─────────────────────────────────────────────────────────────
    Remove-Items "$env:TEMP" "User Temp (%TEMP%)"

    # ── System Temp ───────────────────────────────────────────────────────────
    Remove-Items "C:\Windows\Temp" "Windows Temp"

    # ── Windows Prefetch ──────────────────────────────────────────────────────
    Remove-Items "C:\Windows\Prefetch" "Prefetch"

    # ── Windows Update Cache ──────────────────────────────────────────────────
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Items "C:\Windows\SoftwareDistribution\Download" "Windows Update Cache"
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue

    # ── Windows Error Reporting ───────────────────────────────────────────────
    Remove-Items "C:\ProgramData\Microsoft\Windows\WER\ReportQueue" "WER ReportQueue"
    Remove-Items "C:\ProgramData\Microsoft\Windows\WER\ReportArchive" "WER ReportArchive"

    # ── Recent Items ──────────────────────────────────────────────────────────
    Remove-Items "$env:APPDATA\Microsoft\Windows\Recent" "Recent Items"

    # ── Thumbnail Cache ───────────────────────────────────────────────────────
    Remove-Items "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" "Thumbnail Cache"

    # ── Google Chrome Cache ───────────────────────────────────────────────────
    Remove-Items "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" "Chrome Cache"
    Remove-Items "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache" "Chrome Code Cache"

    # ── Microsoft Edge Cache ──────────────────────────────────────────────────
    Remove-Items "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache" "Edge Cache"
    Remove-Items "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache" "Edge Code Cache"

    # ── Firefox Cache ─────────────────────────────────────────────────────────
    $ffProfiles = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue
    foreach ($p in $ffProfiles) {
        Remove-Items "$($p.FullName)\cache2" "Firefox Cache ($($p.Name))"
    }

    # ── Recycle Bin ───────────────────────────────────────────────────────────
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Log "Recycle Bin emptied."
    } catch {
        Write-Log "Recycle Bin: could not empty ($($_.Exception.Message))."
    }

    # ── DNS Cache ─────────────────────────────────────────────────────────────
    try {
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        Write-Log "DNS Cache flushed."
    } catch {
        Write-Log "DNS Cache flush failed ($($_.Exception.Message))."
    }

    # ── Windows Event Logs ────────────────────────────────────────────────────
    try {
        Get-EventLog -LogName * -ErrorAction SilentlyContinue |
            ForEach-Object { Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue }
        Write-Log "Event Logs cleared."
    } catch {
        Write-Log "Event Logs: could not clear ($($_.Exception.Message))."
    }

    # ── Disk Cleanup (sageset:1) ───────────────────────────────────────────────
    Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -NoNewWindow
    Write-Log "Disk Cleanup (cleanmgr) done."

    Write-Log "===== Cleanup Finished ====="
}

Run-Cleanup
