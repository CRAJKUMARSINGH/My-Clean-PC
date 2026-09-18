# Bitwarden Setup and Configuration Guide
# Complete setup for cross-browser password management with weekly sync

Write-Output "========================================"
Write-Output "Bitwarden Setup Guide"
Write-Output "========================================"
Write-Output ""

Write-Output "STEP 1: BITWARDEN ACCOUNT SETUP"
Write-Output "----------------------------------------"
Write-Output "1. If you haven't already, create a Bitwarden account at https://bitwarden.com"
Write-Output "2. Set a strong master password (memorize this!)"
Write-Output "3. Enable 2FA (Two-Factor Authentication) for extra security"
Write-Output ""

Write-Output "STEP 2: BROWSER EXTENSION INSTALLATION"
Write-Output "----------------------------------------"
Write-Output "Install Bitwarden extension in ALL your browsers:"
Write-Output ""

$browsers = @(
    "Chrome: https://chrome.google.com/webstore/detail/bitwarden-password-manager/nngceckbapebfimnlniiiahkandclblb",
    "Edge: https://microsoftedge.microsoft.com/addons/detail/bitwarden-free-password/jbkfoedapelehhkgydjjpjllcgcobkdm", 
    "Firefox: https://addons.mozilla.org/en-US/firefox/addon/bitwarden-password-manager/",
    "Brave: https://chrome.google.com/webstore/detail/bitwarden-password-manager/nngceckbapebfimnlniiiahkandclblb",
    "Vivaldi: https://chrome.google.com/webstore/detail/bitwarden-password-manager/nngceckbapebfimnlniiiahkandclblb",
    "Opera: https://addons.opera.com/en/extensions/details/bitwarden-password-manager/"
)

foreach ($browser in $browsers) {
    Write-Output $browser
}

Write-Output ""
Write-Output "STEP 3: IMPORT EXISTING PASSWORDS"
Write-Output "----------------------------------------"
Write-Output "Export passwords from your current browsers:"
Write-Output ""
Write-Output "Chrome/Edge/Brave/Vivaldi:"
Write-Output "  Settings > Autofill > Passwords > Export (save as CSV)"
Write-Output ""
Write-Output "Firefox:"
Write-Output "  Settings > Privacy & Security > Passwords > Export Logins"
Write-Output ""
Write-Output "Then import into Bitwarden:"
Write-Output "  Bitwarden Web Vault > Settings > Import Data > Choose CSV file"
Write-Output ""

Write-Output "STEP 4: BITWARDEN EXTENSION CONFIGURATION"
Write-Output "----------------------------------------"
Write-Output "In each browser extension:"
Write-Output "1. Log in with your Bitwarden account"
Write-Output "2. Enable: 'Offer to save passwords'"
Write-Output "3. Enable: 'Auto-fill on page load'"
Write-Output "4. Enable: 'Show passwords on hover'"
Write-Output "5. Set default vault timeout (recommended: 15 minutes)"
Write-Output ""

Write-Output "STEP 5: DISABLE BROWSER PASSWORD MANAGERS"
Write-Output "----------------------------------------"
Write-Output "Optional but recommended to avoid conflicts:"
Write-Output ""
Write-Output "Chrome/Edge/Brave/Vivaldi:"
Write-Output "  Settings > Autofill > Passwords > Turn OFF 'Offer to save passwords'"
Write-Output ""
Write-Output "Firefox:"
Write-Output "  Settings > Privacy & Security > Passwords > Turn OFF 'Ask to save passwords'"
Write-Output ""

Write-Output "STEP 6: WEEKLY SYNCHRONIZATION (AUTOMATIC)"
Write-Output "----------------------------------------"
Write-Output "Bitwarden automatically syncs your passwords to the cloud!"
Write-Output "All browsers sync automatically when connected to internet"
Write-Output "Changes made on one device appear on all others"
Write-Output "No manual sync needed - it's always up to date"
Write-Output ""

Write-Output "STEP 7: WEEKLY BACKUP (EXTRA SECURITY)"
Write-Output "----------------------------------------"
Write-Output "Creating weekly export backup script for extra security..."

$BackupDir = "$env:USERPROFILE\BitwardenBackups"
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force
}

Write-Output "Bitwarden backup directory created: $BackupDir"
Write-Output ""

Write-Output "STEP 8: CREATE WEEKLY BACKUP REMINDER"
Write-Output "----------------------------------------"
Write-Output "Creating scheduled task for weekly backup reminder..."

$TaskName = "WeeklyBitwardenBackupReminder"
$ReminderScript = "$env:USERPROFILE\Weekly-Bitwarden-Reminder.ps1"

$ReminderContent = @"
# Weekly Bitwarden Backup Reminder
Write-Output "========================================"
Write-Output "Bitwarden Weekly Backup Reminder"
Write-Output "========================================"
Write-Output ""
Write-Output "Time to create your weekly Bitwarden backup!"
Write-Output ""
Write-Output "To create a backup:"
Write-Output "1. Open Bitwarden Web Vault: https://vault.bitwarden.com"
Write-Output "2. Go to Settings > Export Data"
Write-Output "3. Choose format (encrypted .json recommended)"
Write-Output "4. Save to your backup folder"
Write-Output ""
Write-Output "Backup folder: $env:USERPROFILE\BitwardenBackups"
Write-Output ""
Write-Output "This reminder runs weekly to ensure you have regular backups."
"@

$ReminderContent | Out-File -FilePath $ReminderScript -Encoding UTF8

try {
    $ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($ExistingTask) {
        Write-Output "Task already exists. Removing old task..."
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }
    
    $Action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -File `"$ReminderScript`""
    
    $Trigger = New-ScheduledTaskTrigger `
        -Weekly `
        -DaysOfWeek Sunday `
        -At 3AM
    
    $Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable:$false
    
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Settings $Settings `
        -RunLevel Highest `
        -Force
    
    Write-Output "Weekly Bitwarden backup reminder scheduled!"
    Write-Output "Will run every Sunday at 3 AM"
    
} catch {
    Write-Output "Scheduled task creation failed (needs admin rights)"
    Write-Output "Run this script as Administrator to complete scheduled task setup"
}

Write-Output ""
Write-Output "========================================"
Write-Output "Bitwarden Setup Summary"
Write-Output "========================================"
Write-Output "Automatic cloud sync enabled (built-in)"
Write-Output "Cross-browser password management ready"
Write-Output "Weekly backup reminder script created"
Write-Output ""
Write-Output "Next steps:"
Write-Output "1. Complete Bitwarden account setup if not done"
Write-Output "2. Install extensions in all browsers"
Write-Output "3. Import existing passwords from browsers"
Write-Output "4. Test auto-fill functionality"
Write-Output "5. Run this script as Administrator for scheduled task"
Write-Output ""
Write-Output "Your passwords will now sync automatically across all browsers!"