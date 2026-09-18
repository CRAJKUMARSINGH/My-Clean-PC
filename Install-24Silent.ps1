# Install 24 Silent as a Windows Scheduled Task
# This will run the cleaning script every 24 minutes automatically in the background

$TaskName = "24-Silent-Cleaner"
$ScriptPath = "E:\Rajkumar\My-Clean-PC\24-Silent.ps1"

# Check if task already exists
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($ExistingTask) {
    Write-Output "Task '$TaskName' already exists. Removing old task..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create the scheduled task action
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -WindowStyle Hidden"

# Create trigger - run every 24 minutes
$Trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes 24)

# Create settings - run even if user is logged on, don't stop on idle
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable:$false `
    -DontStopOnIdleEnd `
    -RestartOnIdle

# Register the task
Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -RunLevel Highest `
    -Force

Write-Output "24 Silent Cleaner installed successfully!"
Write-Output "Will run every 24 minutes automatically"
Write-Output "Log file location: $env:USERPROFILE\24-Silent-Log.txt"
Write-Output ""
Write-Output "To stop the cleaner, run:"
Write-Output "Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"