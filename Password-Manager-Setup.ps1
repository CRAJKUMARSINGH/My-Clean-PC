# Password Manager Setup and Weekly Synchronization
# Helps set up cross-browser password management with weekly backups

Write-Output "========================================"
Write-Output "Password Manager Setup Guide"
Write-Output "========================================"
Write-Output ""

Write-Output "RECOMMENDED PASSWORD MANAGERS:"
Write-Output "1. Bitwarden (Free, Open Source, Cross-Platform)"
Write-Output "2. KeePassXC (Free, Open Source, Local storage)"
Write-Output "3. LastPass (Free tier available)"
Write-Output "4. 1Password (Paid, excellent security)"
Write-Output ""

Write-Output "STEP 1: INSTALL PASSWORD MANAGER"
Write-Output "----------------------------------------"
Write-Output "For Bitwarden (Recommended):"
Write-Output "1. Download: https://bitwarden.com/download/"
Write-Output "2. Install desktop app and browser extensions"
Write-Output "3. Create account and master password"
Write-Output ""

Write-Output "For KeePassXC (Local, No Cloud):"
Write-Output "1. Download: https://keepassxc.org/download/"
Write-Output "2. Install desktop app"
Write-Output "3. Install KeePassXC-Browser extension for all browsers"
Write-Output "4. Create database file and master password"
Write-Output ""

Write-Output "STEP 2: BROWSER EXTENSION SETUP"
Write-Output "----------------------------------------"
Write-Output "Chrome/Edge/Brave/Vivaldi: Install respective password manager extension"
Write-Output "Firefox: Install Firefox extension"
Write-Output "Enable: Password saving, auto-fill, and sync features"
Write-Output ""

Write-Output "STEP 3: WEEKLY SYNCHRONIZATION SETUP"
Write-Output "----------------------------------------"
Write-Output "Creating weekly backup script..."

# Create weekly backup script
$BackupScript = @'
# Weekly Password Database Backup
# Run this weekly to backup your password database

$BackupDir = "$env:USERPROFILE\PasswordBackups"
$SourceFile = "$env:USERPROFILE\PasswordDatabase.kdbx"  # For KeePassXC
# For Bitwarden, use cloud sync or export function

if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force
}

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$BackupFile = "$BackupDir\PasswordBackup_$Timestamp.kdbx"

if (Test-Path $SourceFile) {
    Copy-Item -Path $SourceFile -Destination $BackupFile -Force
    Write-Output "Password database backed up to: $BackupFile"
    
    # Keep only last 4 backups
    $Backups = Get-ChildItem $BackupDir -Filter "PasswordBackup_*.kdbx" | Sort-Object LastWriteTime -Descending
    if ($Backups.Count -gt 4) {
        $Backups | Select-Object -Skip 4 | Remove-Item -Force
        Write-Output "Old backups cleaned up"
    }
} else {
    Write-Output "Source file not found: $SourceFile"
    Write-Output "Please update the script with your actual password database path"
}
'@

$BackupScriptPath = "$env:USERPROFILE\Weekly-Password-Backup.ps1"
$BackupScript | Out-File -FilePath $BackupScriptPath -Encoding UTF8

Write-Output "Weekly backup script created: $BackupScriptPath"
Write-Output ""

Write-Output "STEP 4: CREATE WEEKLY SCHEDULED TASK"
Write-Output "----------------------------------------"
Write-Output "Creating scheduled task for weekly password backup..."

$TaskName = "WeeklyPasswordBackup"
$ScriptPath = $BackupScriptPath

try {
    # Check if task already exists
    $ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($ExistingTask) {
        Write-Output "Task already exists. Removing old task..."
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }
    
    # Create the scheduled task action
    $Action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""
    
    # Create trigger - run weekly on Sundays at 2 AM
    $Trigger = New-ScheduledTaskTrigger `
        -Weekly `
        -DaysOfWeek Sunday `
        -At 2AM
    
    # Create settings
    $Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable:$false
    
    # Register the task
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Settings $Settings `
        -RunLevel Highest `
        -Force
    
    Write-Output "✓ Weekly password backup scheduled task created!"
    Write-Output "✓ Will run every Sunday at 2 AM"
    
} catch {
    Write-Output "✗ Failed to create scheduled task: $_"
    Write-Output "You may need to run this script as Administrator"
}

Write-Output ""
Write-Output "STEP 5: IMPORT EXISTING PASSWORDS"
Write-Output "----------------------------------------"
Write-Output "1. Export passwords from current browsers:"
Write-Output "   - Chrome: Settings > Autofill > Passwords > Export"
Write-Output "   - Firefox: Lockwise > Export Logins"
Write-Output "   - Edge: Settings > Profiles > Passwords > Export"
Write-Output ""
Write-Output "2. Import into password manager:"
Write-Output "   - Most password managers support CSV import"
Write-Output "   - Bitwarden: Settings > Import Data"
Write-Output "   - KeePassXC: File > Import"
Write-Output ""

Write-Output "STEP 6: ENABLE BROWSER INTEGRATION"
Write-Output "----------------------------------------"
Write-Output "1. Install password manager extension in each browser"
Write-Output "2. Enable browser integration in password manager settings"
Write-Output "3. Disable browser built-in password managers (optional)"
Write-Output "4. Test auto-fill functionality on websites"
Write-Output ""

Write-Output "========================================"
Write-Output "Setup Complete!"
Write-Output "========================================"
Write-Output "Next steps:"
Write-Output "1. Install your chosen password manager"
Write-Output "2. Import existing passwords"
Write-Output "3. Set up browser extensions"
Write-Output "4. Update the backup script with your database path"
Write-Output "5. Test the weekly backup manually once"
Write-Output ""
Write-Output "Backup script location: $BackupScriptPath"
Write-Output "To test backup manually: powershell -ExecutionPolicy Bypass -File `"$BackupScriptPath`""