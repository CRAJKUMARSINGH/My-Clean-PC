# Update GoogleUserPEH Tasks to Run Monthly
# Run as Administrator

Write-Output "Updating GoogleUserPEH tasks to run monthly..."

# 1. Update RunPlatformExperienceHelper_Daily
try {
    $task = Get-ScheduledTask -TaskName "RunPlatformExperienceHelper_Daily" -ErrorAction Stop
    $trigger = $task.Triggers[0]
    
    # Change from daily to monthly (runs on the 1st of each month)
    $trigger.DaysInterval = $null
    $trigger.MonthsOfYear = 1,2,3,4,5,6,7,8,9,10,11,12  # All months
    $trigger.DaysOfMonth = 1  # 1st day of each month
    
    Set-ScheduledTask -TaskName "RunPlatformExperienceHelper_Daily" -Trigger $trigger
    Write-Output "✓ RunPlatformExperienceHelper_Daily updated to run monthly (1st of each month)"
} catch {
    Write-Output "✗ Failed to update RunPlatformExperienceHelper_Daily: $_"
}

# 2. Update RunPlatformExperienceHelper_Metrics
try {
    $task = Get-ScheduledTask -TaskName "RunPlatformExperienceHelper_Metrics" -ErrorAction Stop
    $trigger = $task.Triggers[0]
    
    # Change to monthly schedule
    $trigger.MonthsOfYear = 1,2,3,4,5,6,7,8,9,10,11,12  # All months
    $trigger.DaysOfMonth = 1  # 1st day of each month
    
    Set-ScheduledTask -TaskName "RunPlatformExperienceHelper_Metrics" -Trigger $trigger
    Write-Output "✓ RunPlatformExperienceHelper_Metrics updated to run monthly (1st of each month)"
} catch {
    Write-Output "✗ Failed to update RunPlatformExperienceHelper_Metrics: $_"
}

Write-Output ""
Write-Output "GoogleUserPEH schedule update complete!"
Write-Output "Both tasks will now run monthly on the 1st of each month"