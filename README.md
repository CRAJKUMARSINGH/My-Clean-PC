# My Clean PC

[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE)

Silent, prompt-free Windows cache, cookie, and AI tool cleaner — passwords, autofill, bookmarks, and Downloads are **never** touched.

---

## 📥 How to Download and Install

### Step 1: Download the Repository

Choose **Method A** or **Method B**:

#### Method A — Using Git (Recommended)
Open PowerShell or Command Prompt and run:
```powershell
git clone https://github.com/CRAJKUMARSINGH/My-Clean-PC.git
cd My-Clean-PC
```

#### Method B — Direct ZIP Download (Without Git)
1. Click the green **Code** button on GitHub and select **Download ZIP** (or download from the repository page).
2. Extract the ZIP archive to a folder on your computer (e.g., `E:\My-Clean-PC` or `C:\My-Clean-PC`).
3. Open PowerShell or Command Prompt in that extracted folder.

---

### Step 2: Choose Installation Option

**⚠️ IMPORTANT: Must be run with Administrator Privileges**

You can install **Both Cleaners**, the **7-Minute Cleaner ONLY**, the **24-Minute Cleaner ONLY**, or the **Weekly Cleaner ONLY**:

| Desired Setup | 1-Click Batch File | PowerShell Command (Run as Admin) |
|---|---|---|
| **Install BOTH Cleaners** | Double-click `Launch-Install-Both.bat` | `powershell -ExecutionPolicy Bypass -File Install-Cleaners-Admin.ps1 -Task Both` |
| **Install 7-Min Cleaner ONLY** | Double-click `Launch-Install-7Min-Only.bat` | `powershell -ExecutionPolicy Bypass -File Install-Cleaners-Admin.ps1 -Task 7Min` |
| **Install 24-Min Cleaner ONLY** | Double-click `Launch-Install-24Min-Only.bat` | `powershell -ExecutionPolicy Bypass -File Install-Cleaners-Admin.ps1 -Task 24Min` |
| **Install Weekly Cleaner ONLY** | Double-click `Launch-Install-Weekly-Only.bat` | `powershell -ExecutionPolicy Bypass -File Install-Cleaners-Admin.ps1 -Task Weekly` |

---

## ⚙️ Installed Cleaner Sets

- **`MyCleanPC-7Min`**
  - **Interval**: Repeats automatically **every 7 minutes** when PC is ON.
  - **Behavior**: Runs completely hidden, cleaning caches & temp files without closing any running browsers or AI tools.
- **`MyCleanPC-24Min`**
  - **Interval**: Repeats automatically **every 24 minutes** when PC is ON.
  - **Behavior**: Runs completely hidden without closing any running browsers or AI tools.
- **`MyCleanPC-Weekly`**
  - **Interval**: Repeats automatically **every Week (Monday at 9:00 AM)** when PC is ON.
  - **Behavior**: Runs background cleanup using the exact same shared engine.

---

## 📋 Cleaner Log Files

| Log File | Script / Source | Description |
|---|---|---|
| **`ai_cleaner_log.txt`** | `scripts/ai-cache-cleaner.ps1` | Logs AI tools & browser cache cleaning runs (runs on 7-min / 24-min schedule). |
| **`temp_cleaner_log.txt`** | `scripts/clean-pc-core.ps1` | Logs deep temporary files, AppData junk sweeps, Prefetch, Recycle Bin, and Disk Cleanup operations. |
| **`cleanup_log.txt`** | `scripts/cleanup_task.ps1` | Logs weekly scheduled full cleanup operations. |

*Note: Log files are automatically generated and saved in `%LOCALAPPDATA%\MyCleanPC\` (when installed) as well as the script folder.*

---

## 📂 Repository Script Breakdown & Functions

| File / Script Path | Type | Function & Description |
|---|---|---|
| **[`Install-Cleaners-Admin.ps1`](Install-Cleaners-Admin.ps1)** | PowerShell Universal Installer | **Universal Installer**: Auto-elevates to Administrator and registers `Both` tasks (7Min + Weekly), `7Min` task only, `24Min` task only, or `Weekly` task only based on `-Task` parameter. |
| **[`Install-Both-Cleaners-Admin.ps1`](Install-Both-Cleaners-Admin.ps1)** | PowerShell Wrapper | **Both Task Installer Wrapper**: Backward-compatible script executing `Install-Cleaners-Admin.ps1 -Task Both`. |
| **[`Launch-Install-Both.bat`](Launch-Install-Both.bat)** | Batch Launcher | **1-Click Launcher (Both)**: Triggers UAC elevation and installs both `MyCleanPC-7Min` and `MyCleanPC-Weekly`. |
| **[`Launch-Install-7Min-Only.bat`](Launch-Install-7Min-Only.bat)** | Batch Launcher | **1-Click Launcher (7Min Only)**: Triggers UAC elevation and installs only `MyCleanPC-7Min`. |
| **[`Launch-Install-24Min-Only.bat`](Launch-Install-24Min-Only.bat)** | Batch Launcher | **1-Click Launcher (24Min Only)**: Triggers UAC elevation and installs only `MyCleanPC-24Min`. |
| **[`Launch-Install-Weekly-Only.bat`](Launch-Install-Weekly-Only.bat)** | Batch Launcher | **1-Click Launcher (Weekly Only)**: Triggers UAC elevation and installs only `MyCleanPC-Weekly`. |
| **[`scripts/ai-cache-cleaner.ps1`](scripts/ai-cache-cleaner.ps1)** | PowerShell Cleaner Engine | **Primary Cleaner Engine**: Executes targeted cleanup of browser caches, cookies, history, storage, AI tool caches, AppData Roaming folders, temp files, and deletes registry `MachineGuid`. |
| **[`scripts/clean-pc-core.ps1`](scripts/clean-pc-core.ps1)** | PowerShell Shared Core | **Shared Functions & Core Utilities**: Provides helper functions, directory size calculation, disk cleanup integration, and integrates `ai-cache-cleaner.ps1`. |
| **[`scripts/cleanup_task.ps1`](scripts/cleanup_task.ps1)** | PowerShell Task Runner | **Weekly Task Runner**: Invoked by the weekly scheduled task to execute full cleaning operations. |
| **[`uninstall.ps1`](uninstall.ps1)** | PowerShell Uninstaller | **Uninstaller Script**: Unregisters all `MyCleanPC` scheduled tasks and removes installation directories from `%LOCALAPPDATA%\MyCleanPC`. |
| **[`uninstall.bat`](uninstall.bat)** | Batch Uninstaller | **1-Click Batch Uninstaller**: Launches `uninstall.ps1` with Administrator privileges. |

---

## 🧹 What It Cleans

| Target Area | Scope & Details |
|---|---|
| **Browsers (Ctrl+Shift+Delete)** | Chrome, Edge, Brave, Vivaldi, Firefox, Opera, Yandex, Genspark<br>• Cache, Code Cache, GPUCache<br>• Cookies & Network Persistent State<br>• Browsing & Visited History<br>• Local Storage, Session Storage, IndexedDB, Service Worker Cache |
| **AI Tools & App Roaming** | Antigravity IDE, Cursor, DEVIN, KIRO, TRAE, foobar2000-v2, Windsurf AppData Local & Roaming caches/logs |
| **Windows Junk** | `%TEMP%`, `%LOCALAPPDATA%\Temp`, older temp files |
| **Registry Entry** | Deletes `HKLM:\SOFTWARE\Microsoft\Cryptography` -> `MachineGuid` |

---

## 🛡️ What It Never Touches (Safeguards)

- **Passwords** — `Login Data`, `key4.db`, `logins.json`, credential stores
- **Autofill / Form Data** — `formhistory.sqlite`, `Autofill`
- **Bookmarks** — `Bookmarks`, `bookmarks.html`
- **Downloads Folder** — `Downloads`
- **Explorer Pins / Quick Access**

---

## 🗑️ How to Uninstall

To remove scheduled tasks and delete installed files:

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

*Or double-click `uninstall.bat` as Administrator.*

---

## 📄 License

MIT — see [LICENSE](LICENSE).
