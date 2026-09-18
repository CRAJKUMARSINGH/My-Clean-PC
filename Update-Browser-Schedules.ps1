# Update Browser Update Tasks to Run Fortnightly (Every 14 Days)
# Run as Administrator

Write-Output "Updating browser update tasks to run fortnightly..."

# 1. Update Yandex Browser
try {
    $task = Get-ScheduledTask -TaskName "Update for Yandex Browser" -ErrorAction Stop
    $trigger = $task.Triggers[0]
    $trigger.DaysInterval = 14
    Set-ScheduledTask -TaskName "Update for Yandex Browser" -Trigger $trigger
    Write-Output "✓ Yandex Browser updated to run every 14 days"
} catch {
    Write-Output "✗ Failed to update Yandex Browser: $_"
}

# 2. Update Vivaldi
try {
    $task = Get-ScheduledTask -TaskName "VivaldiUpdateCheck-f2fd1c69139808cd" -ErrorAction Stop
    $trigger = $task.Triggers[0]
    $trigger.DaysInterval = 14
    Set-ScheduledTask -TaskName "VivaldiUpdateCheck-f2fd1c69139808cd" -Trigger $trigger
    Write-Output "✓ Vivaldi updated to run every 14 days"
} catch {
    Write-Output "✗ Failed to update Vivaldi: $_"
}

# 3. Update Firefox Background Update
try {
    $task = Get-ScheduledTask -TaskName "Firefox Background Update S-1-5-21-2098802215-1215162639-3818308279-1008 308046B0AF4A39CB" -ErrorAction Stop
    $trigger = $task.Triggers[0]
    $trigger.Repetition.Interval = "PT0H"
    $trigger.DaysInterval = 14
    Set-ScheduledTask -TaskName "Firefox Background Update S-1-5-21-2098802215-1215162639-3818308279-1008 308046B0AF4A39CB" -Trigger $trigger
    Write-Output "✓ Firefox Background Update updated to run every 14 days"
} catch {
    Write-Output "✗ Failed to update Firefox Background Update: $_"
}

# 4. Update Firefox Default Browser Agent
try {
    $task = Get-ScheduledTask -TaskName "Firefox Default Browser Agent 308046B0AF4A39CB" -ErrorAction Stop
    $trigger = $task.Triggers[0]
    $trigger.DaysInterval = 14
    Set-ScheduledTask -TaskName "Firefox Default Browser Agent 308046B0AF4A39CB" -Trigger $trigger
    Write-Output "✓ Firefox Default Browser Agent updated to run every 14 days"
} catch {
    Write-Output "✗ Failed to update Firefox Default Browser Agent: $_"
}

Write-Output ""
Write-Output "Browser update schedule update complete!"
Write-Output "All browser updates will now run every 14 days (fortnightly)"