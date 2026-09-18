# 24 Silent - Automated Cleaning Script

A safe, silent cleaning script that runs every 24 minutes without closing any applications, browsers, or development tools.

## What It Cleans

1. **Temp Files** (Windows Temp, Local AppData Temp, Prefetch)
2. **Roaming AppData** for AI tools: Windsurf, Kiro, Devin, Antigravity, Trae
3. **Disk Cleanup** (cleanmgr) - runs silently
4. **Recycle Bin** - emptied safely

## Key Features

- ✅ **NO APPLICATION CLOSING** - Never stops browsers, IDEs, or tools
- ✅ **Silent Operation** - Runs completely in background
- ✅ **Safe Deletion** - Skips locked files instead of killing processes
- ✅ **Logging** - All actions logged to `24-Silent-Log.txt`
- ✅ **24-Minute Interval** - Automatic recurring cleanup

## Installation

### Option 1: Windows Scheduled Task (Recommended)

Run as Administrator in PowerShell:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "E:\Rajkumar\My-Clean-PC\Install-24Silent.ps1"
```

This will:
- Create a Windows Scheduled Task named "24-Silent-Cleaner"
- Run automatically every 24 minutes
- Start with Windows
- Run with highest privileges

### Option 2: Manual Runner (For Testing)

Double-click `24-Silent-Runner.bat` to run the cleaner manually in a loop.
- Press Ctrl+C to stop
- Window must remain open

## Files Created

- `24-Silent.ps1` - Main cleaning script
- `24-Silent-Runner.bat` - Manual runner (optional)
- `Install-24Silent.ps1` - Scheduled task installer
- `24-Silent-Log.txt` - Activity log (created in user profile)

## Stopping the Cleaner

If using Scheduled Task:

```powershell
Unregister-ScheduledTask -TaskName "24-Silent-Cleaner" -Confirm:$false
```

If using Manual Runner: Press Ctrl+C in the command window

## Viewing Logs

```powershell
notepad $env:USERPROFILE\24-Silent-Log.txt
```

## Safety Features

1. **ErrorActionPreference = SilentlyContinue** - Script continues even if individual operations fail
2. **Try-Catch Blocks** - Each folder wrapped in error handling
3. **Locked File Handling** - Skips files in use instead of killing processes
4. **No Force Process Kill** - Never terminates running applications
5. **Hidden Window** - PowerShell runs with -WindowStyle Hidden

## Differences from Previous Script

- ❌ NO task termination of any kind
- ❌ NO browser closing
- ❌ NO IDE/tool stopping
- ❌ NO user prompts or confirmations
- ✅ Safe skip of locked files
- ✅ Silent background operation
- ✅ Proper error handling

## Troubleshooting

If cleaner isn't running:
1. Check Task Scheduler for "24-Silent-Cleaner" task
2. Verify script path is correct: `E:\Rajkumar\My-Clean-PC\24-Silent.ps1`
3. Check log file for errors
4. Ensure running as Administrator for installation

To manually test the cleaner:
```powershell
powershell.exe -ExecutionPolicy Bypass -File "E:\Rajkumar\My-Clean-PC\24-Silent.ps1"
```

## Notes

- The cleaner only deletes files that are not currently in use
- Browser cache is NOT cleaned if it requires closing the browser
- All AI tool caches are cleaned safely without closing the tools
- The script is designed to be completely non-intrusive
