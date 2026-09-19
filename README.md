# My Clean PC

[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE)

Silent, prompt-free Windows cache cleaner — passwords, autofill, bookmarks, and Downloads are **never** touched.

---

## ⬇️ Installation

### Option 1 — Scheduled Task (recommended)
Sets up automatic cleaning every 6 hours with user warning before each run.

**⚠️ IMPORTANT: Run PowerShell as Administrator**

```powershell
git clone https://github.com/CRAJKUMARSINGH/My-Clean-PC.git
cd My-Clean-PC\scripts
powershell -ExecutionPolicy Bypass -File create-scheduled-task.ps1
```

This will:
- Copy the cleaning scripts to your local AppData
- Create a Windows Scheduled Task that runs every 6 hours
- Show a warning notification 30 seconds before each cleaning starts
- Run silently in the background

### Option 2 — Manual Run
Run the cleaning script manually anytime:

```powershell
git clone https://github.com/CRAJKUMARSINGH/My-Clean-PC.git
cd My-Clean-PC\scripts
powershell -ExecutionPolicy Bypass -File cleanup_task.ps1
```

### Option 3 — AI Cache Cleaner (24-minute cycle)
Cleans AI tool roaming cache and temp files every 24 minutes **without closing any running tools**:

**⚠️ IMPORTANT: Run PowerShell as Administrator**

```powershell
git clone https://github.com/CRAJKUMARSINGH/My-Clean-PC.git
cd My-Clean-PC\scripts
powershell -ExecutionPolicy Bypass -File create-ai-cache-task.ps1
```

This will:
- Create a Windows Scheduled Task that runs every 24 minutes
- Clean AI tool caches (Cursor, Windsurf, Trae, Devin, Antigravity, Kiro, etc.)
- **Never close running AI tools** - they continue uninterrupted
- Run silently in the background with no notifications

### Option 4 — 24-Silent Cleaner (24-minute cycle)
Cleans temp files and AI tool caches every 24 minutes **without closing any applications**:

**⚠️ IMPORTANT: Run PowerShell as Administrator**

```powershell
git clone https://github.com/CRAJKUMARSINGH/My-Clean-PC.git
cd My-Clean-PC
powershell -ExecutionPolicy Bypass -File Install-24Silent.ps1
```

This will:
- Create a Windows Scheduled Task named "24-Silent-Cleaner"
- Run every 24 minutes
- Clean temp files, AI tool caches, and recycle bin
- **Never close any applications, browsers, or AI tools**
- Run completely silently with no notifications

### Option 5 — GUI Interface
For users who prefer a graphical interface:

```powershell
git clone https://github.com/CRAJKUMARSINGH/My-Clean-PC.git
cd My-Clean-PC
powershell -ExecutionPolicy Bypass -File My-Clean-PC-GUI.ps1
```

### Alternative Scheduling Options
Different scheduling frequencies available in the root directory:
- `schedule-30min.ps1` - Every 30 minutes
- `schedule-1week.ps1` - Every Monday at 9:00 AM
- `schedule-15days.ps1` - Every 15 days at 9:00 AM
- `install-weekly.ps1` - Weekly with auto-elevation

---

## Features

- **Automatic Scheduled Cleaning**: Runs every 6 hours via Windows Task Scheduler
- **User Warning**: Shows notification 30 seconds before cleaning starts
- **Silent Operation**: No interactive prompts or dialogs
- **Safe Cleaning**: Never touches passwords, autofill, bookmarks, or Downloads
- **Comprehensive Coverage**: Cleans browser caches, AI tool caches, temp files, and Windows junk

---

## What It Cleans

| Area | Details |
|------|---------|
| Windows Temp | `%TEMP%`, `%LOCALAPPDATA%\Temp`, `C:\Windows\Temp` |
| AppData junk | Cache, Logs, CrashDumps, blob_storage and similar dirs across all apps |
| Browsers | Cache, cookies, history, service workers — Chrome, Edge, Firefox, Brave, Vivaldi, Opera and more |
| AI dev tools | Cursor, Windsurf, Kiro, Trae, Warp, Genspark, Antigravity caches |
| Windows | Recycle Bin, Disk Cleanup (`C:`), Windows Update download cache, DNS cache, Event Logs |

## What It Never Touches

- **Passwords** — `Login Data`, `key4.db` and all browser credential stores
- **Autofill / form data** — `Web Data`, `formhistory.sqlite`
- **Bookmarks**
- **Downloads folder**
- **Quick Access pins** and Recent folder
- **Open / locked files** — silently skipped; registered for deletion at next reboot if needed

---

## ⚠️ Common Installation Mistakes

### 1. Not Running as Administrator
**Problem**: "Access is denied" errors when running installation scripts.

**Solution**: You **MUST** run PowerShell as Administrator to create Windows Scheduled Tasks:
- Right-click PowerShell and select "Run as Administrator"
- Window title should show "Administrator: Windows PowerShell"
- Verify with: `([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")`

### 2. Wrong Directory
**Problem**: "The argument to the -File parameter does not exist."

**Solution**: Always navigate to the correct directory first:
```powershell
cd E:\Rajkumar\My-Clean-PC  # or your installation path
```

### 3. Running Scripts from Wrong Location
**Problem**: Scripts in `scripts/` folder need to be run from that directory.

**Solution**: Use correct paths:
```powershell
# For scripts in scripts/ folder
powershell -ExecutionPolicy Bypass -File scripts\create-scheduled-task.ps1

# For scripts in root directory
powershell -ExecutionPolicy Bypass -File Install-24Silent.ps1
```

### 4. Assuming Installation Worked Without Verification
**Problem**: Scripts copy files but fail to create scheduled tasks due to permission issues.

**Solution**: Always verify installation:
```powershell
Get-ScheduledTask -TaskName "MyCleanPC"
Get-ScheduledTask -TaskName "MyCleanPC-AI-Cache"
Get-ScheduledTask -TaskName "24-Silent-Cleaner"
```

### 5. Not Checking Task Status
**Problem**: Tasks exist but are disabled or not running.

**Solution**: Check task state and next run time:
```powershell
Get-ScheduledTaskInfo -TaskName "MyCleanPC"
```

### 6. Running Multiple Conflicting Tasks
**Problem**: Installing multiple cleaners with same task name or overlapping schedules.

**Solution**: Remove old tasks before installing new ones:
```powershell
Unregister-ScheduledTask -TaskName "MyCleanPC" -Confirm:$false
```

### 7. Ignoring Log Files
**Problem**: Installation or cleaning fails but no troubleshooting information.

**Solution**: Check log files in installation directory:
```powershell
notepad $env:LOCALAPPDATA\MyCleanPC\install_log.txt
notepad $env:LOCALAPPDATA\MyCleanPC\cleanup_log.txt
```

### 8. Not Understanding Schedule Intervals
**Problem**: Expecting immediate cleaning when tasks run on schedules.

**Solution**: Check next run time:
```powershell
Get-ScheduledTaskInfo -TaskName "MyCleanPC" | Select-Object NextRunTime
```

### 9. Forgetting About UAC Prompts
**Problem**: PowerShell closes immediately when UAC prompt appears.

**Solution**: Always click "Yes" on UAC prompts when running as Administrator.

### 10. Manual vs Automatic Confusion
**Problem**: Running manual cleanup scripts expecting scheduled behavior.

**Solution**: Understand the difference:
- Manual scripts (`cleanup_task.ps1`) run once when executed
- Installation scripts (`create-scheduled-task.ps1`) set up automatic scheduling

---

## How It Avoids Windows Dialogs

Every directory deletion uses a three-stage silent pipeline — the Explorer  
*"Do this for all current items / Skip"* prompt is **never shown**:

| Stage | Method |
|-------|--------|
| 1 | `cmd /c del /f /s /q` — force-kills all unlocked files |
| 2 | `robocopy /MIR` from an empty folder — wipes remaining structure |
| 3 | `MoveFileEx DELAY_UNTIL_REBOOT` — registers any still-locked files for next-boot deletion |

---

## Project Structure

```
My-Clean-PC/
├── scripts/
│   ├── clean-pc-core.ps1      ← single source of truth for all cleaning logic
│   ├── cleanup_task.ps1       ← scheduled task runner with user warning
│   ├── create-scheduled-task.ps1  ← installer for Windows Scheduled Task
│   ├── ai-cache-cleaner.ps1   ← AI tool cache cleaner (24-minute cycle)
│   └── create-ai-cache-task.ps1  ← installer for AI cache scheduled task
├── utilities/
│   ├── test-appfolders.ps1    ← test script for app folder cleaning
│   ├── test-temp-deletion.ps1 ← test script for temp file deletion
│   ├── appfolder-cleaner.ps1   ← app folder specific cleaner
│   └── AppFolderCleanupScript.ps1 ← comprehensive app folder cleanup
├── Install-24Silent.ps1       ← installer for 24-minute silent cleaner
├── My-Clean-PC-GUI.ps1        ← graphical user interface
├── schedule-30min.ps1         ← alternative: 30-minute schedule
├── schedule-1week.ps1         ← alternative: weekly schedule
├── schedule-15days.ps1        ← alternative: 15-day schedule
├── install-weekly.ps1         ← alternative: weekly with auto-elevation
├── uninstall.ps1              ← uninstallation script
├── uninstall.bat              ← uninstallation batch file
├── my-clean-pc-standalone.ps1 ← standalone cleaner script
├── test-clean-run.ps1         ← test script for cleaning
├── run-clean-all.ps1          ← run all cleaning operations
├── APPS_FOLDER_CLEANUP_COMPLETE.ps1 ← app folder cleanup utility
├── Launch-Clean-PC.bat        ← batch file launcher
├── my-clean-pc.bat            ← batch file for manual cleaning
├── Bitwarden-Setup-Guide.ps1  ← password manager setup guide
├── Password-Manager-Setup.ps1 ← general password manager setup
├── Update-Browser-Schedules.ps1 ← browser update schedule optimizer
├── Update-GoogleUserPEH-Monthly.ps1 ← Google service schedule optimizer
├── 24-Silent-README.md        ← documentation for 24-silent cleaner
├── logbook.md                 ← daily log and maintenance records
└── README.md                  ← this file
```

---

## Managing the Scheduled Task

### View Task Status
```powershell
Get-ScheduledTask -TaskName "MyCleanPC"
```

### Remove Scheduled Task
```powershell
Unregister-ScheduledTask -TaskName "MyCleanPC" -Confirm:$false
```

### Change Schedule
Edit the `IntervalHrs` variable in `create-scheduled-task.ps1` and re-run the script.

---

## Managing the AI Cache Task

### View AI Cache Task Status
```powershell
Get-ScheduledTask -TaskName "MyCleanPC-AI-Cache"
```

### Remove AI Cache Task
```powershell
Unregister-ScheduledTask -TaskName "MyCleanPC-AI-Cache" -Confirm:$false
```

### Change AI Cache Schedule
Edit the `IntervalMin` variable in `create-ai-cache-task.ps1` and re-run the script.

---

## Managing the 24-Silent Cleaner Task

### View 24-Silent Task Status
```powershell
Get-ScheduledTask -TaskName "24-Silent-Cleaner"
```

### Remove 24-Silent Task
```powershell
Unregister-ScheduledTask -TaskName "24-Silent-Cleaner" -Confirm:$false
```

### View 24-Silent Logs
```powershell
notepad $env:USERPROFILE\24-Silent-Log.txt
```

### Change 24-Silent Schedule
Edit the `IntervalMin` variable in `Install-24Silent.ps1` and re-run the script.

---

## License

MIT — see [LICENSE](LICENSE).
