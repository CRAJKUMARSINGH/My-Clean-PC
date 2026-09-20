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

### Step 2: Install Both Cleaner Sets

**⚠️ IMPORTANT: Must be run with Administrator Privileges**

Run the PowerShell command below in an **Administrator PowerShell** window:

```powershell
powershell -ExecutionPolicy Bypass -File Install-Both-Cleaners-Admin.ps1
```

*OR*

Double-click **`Launch-Install-Both.bat`** in File Explorer and click **Yes** when the Windows Administrator prompt (UAC) appears.

---

## ⚙️ Installed Cleaner Sets

The master installer sets up two Windows Scheduled Tasks that run silently in the background whenever your PC is on:

1. **`MyCleanPC-24Min`**
   - **Interval**: Repeats automatically **every 24 minutes**.
   - **Behavior**: Runs completely hidden without closing any running browsers or AI tools.
2. **`MyCleanPC-Weekly`**
   - **Interval**: Repeats automatically **every Week (Monday at 9:00 AM)**.
   - **Behavior**: Runs background cleanup using the exact same shared engine.

---

## 📂 Repository Script Breakdown & Functions

| File / Script Path | Type | Function & Description |
|---|---|---|
| **[`Install-Both-Cleaners-Admin.ps1`](Install-Both-Cleaners-Admin.ps1)** | PowerShell Installer | **Master Installer Script**: Auto-elevates to Administrator, copies core scripts to `%LOCALAPPDATA%\MyCleanPC`, and registers both `MyCleanPC-24Min` and `MyCleanPC-Weekly` tasks in Windows Task Scheduler. |
| **[`Launch-Install-Both.bat`](Launch-Install-Both.bat)** | Batch Launcher | **1-Click Launcher**: Triggers UAC elevation and executes `Install-Both-Cleaners-Admin.ps1` with a single click. |
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

To remove both scheduled tasks and delete installed files:

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

*Or double-click `uninstall.bat` as Administrator.*

---

## 📄 License

MIT — see [LICENSE](LICENSE).
