# My Clean PC

[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE)

Silent, prompt-free Windows cache cleaner — passwords, autofill, bookmarks, and Downloads are **never** touched.

---

## ⬇️ Installation

### Option 1 — Scheduled Task (recommended)
Sets up automatic cleaning every 6 hours with user warning before each run.

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
│   └── create-scheduled-task.ps1  ← installer for Windows Scheduled Task
└── README.md
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

## License

MIT — see [LICENSE](LICENSE).
