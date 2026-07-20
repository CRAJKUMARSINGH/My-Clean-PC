# My Clean PC

[![Latest Release](https://img.shields.io/github/v/release/CRAJKUMARSINGH/My-Clean-PC?label=download&style=for-the-badge&logo=github)](https://github.com/CRAJKUMARSINGH/My-Clean-PC/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/CRAJKUMARSINGH/My-Clean-PC/total?style=for-the-badge&logo=windows)](https://github.com/CRAJKUMARSINGH/My-Clean-PC/releases)
[![Chocolatey](https://img.shields.io/chocolatey/v/my-clean-pc?style=for-the-badge&logo=chocolatey)](https://community.chocolatey.org/packages/my-clean-pc)
[![Built with Replit](https://img.shields.io/badge/Built%20with-Replit%20AI-667EEA?style=for-the-badge&logo=replit&logoColor=white)](https://replit.com)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE)

Silent, prompt-free Windows cache cleaner — passwords, autofill, bookmarks, and Downloads are **never** touched.

---

## ⬇️ Download

### Option 1 — Installer (recommended)
Downloads the NSIS installer from the latest GitHub Release.  
Creates a Start Menu shortcut and a Desktop shortcut.

**[→ Download My Clean PC Setup](https://github.com/CRAJKUMARSINGH/My-Clean-PC/releases/latest)**

### Option 2 — Portable .exe (no install)
A single self-contained `.exe`. Drop it anywhere and run — nothing gets installed.

**[→ Download MyCleanPC-Portable.exe](https://github.com/CRAJKUMARSINGH/My-Clean-PC/releases/latest)**

### Option 3 — Chocolatey
```powershell
choco install my-clean-pc
```
Upgrade later with `choco upgrade my-clean-pc`.

### Option 4 — Script only (advanced)
```powershell
git clone https://github.com/CRAJKUMARSINGH/My-Clean-PC.git
cd My-Clean-PC\scripts
powershell -ExecutionPolicy Bypass -File my-clean-pc.ps1
```
Keep `clean-pc-core.ps1` and `my-clean-pc.ps1` in the same folder.

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

## Space-Freed Counter + Pre-Scan

Before cleaning starts, the app scans every target path and shows what it found:

```
-- PRE-SCAN: measuring junk (read-only, nothing deleted yet) --
  Estimated junk found:  4.18 GB across 23 locations
    Kiro (Roaming)              1.42 GB
    Chrome Cache                890.3 MB
    User Temp                   721.1 MB
    Cursor Cache                644.8 MB
    INetCache                   312.4 MB
```

At the end, it shows exactly how much was actually reclaimed — plus a fun comparison:

```
============================================
  Space freed this run:  3.42 GB
  That's like 878 MP3 songs
============================================
```

In the Electron GUI, the freed number **counts up from zero** with an animated glow.

---

## Building from Source

### Electron installer (NSIS .exe)
```powershell
cd electron
npm install
npm run build
# Output: dist-electron\My Clean PC Setup x64.exe
```

### Portable .exe (PS2EXE, no Electron)
```powershell
powershell -ExecutionPolicy Bypass -File build\Build-Exe.ps1
# Output: dist\MyCleanPC-Portable.exe
```

### Releasing a new version
Tag a commit — GitHub Actions builds both outputs and creates the release automatically:
```bash
git tag v1.0.1
git push origin v1.0.1
```

---

## Project Structure

```
My-Clean-PC/
├── scripts/
│   ├── clean-pc-core.ps1   ← single source of truth for all cleaning logic
│   └── my-clean-pc.ps1     ← console launcher (dot-sources core)
├── electron/               ← Electron GUI wrapper
│   ├── main.js
│   ├── preload.js
│   ├── renderer/
│   └── electron-builder.yml
├── build/
│   └── Build-Exe.ps1       ← PS2EXE portable-exe build script
├── choco/                  ← Chocolatey package
│   ├── my-clean-pc.nuspec
│   └── tools/
└── .github/workflows/
    └── release.yml         ← auto-build + release on version tag
```

---

## How to Push These Files to Your GitHub Repo

All the new files (Electron app, PS2EXE build script, Chocolatey package, GitHub Actions workflow, updated scripts) live here in Replit. Here are three ways to get them into **github.com/CRAJKUMARSINGH/My-Clean-PC**.

---

### Option A — From Replit (easiest, one-time setup)

1. In Replit, click **Version Control** (the branch icon in the left sidebar).
2. Click **Connect to GitHub** and authorise Replit to access your account.
3. Select the existing repo **CRAJKUMARSINGH/My-Clean-PC**.
4. Back in the Version Control panel, stage all files → write a commit message → **Push**.

Done. Everything lands in `main` on GitHub in one click from now on.

---

### Option B — From your Windows PC (git command line)

Open PowerShell or Git Bash in your existing local clone of the repo:

```powershell
cd path\to\My-Clean-PC        # your existing local clone

# 1. Pull the latest from GitHub first (avoids conflicts)
git pull origin main

# 2. Copy every new file from the Replit download into this folder.
#    (Download the Replit project as a ZIP: Replit → ⋮ menu → Download as ZIP,
#     then extract and copy these paths into your local clone.)
#
#    New / updated paths to copy:
#      scripts\clean-pc-core.ps1        (updated — dialog fix, pre-scan, counter)
#      scripts\my-clean-pc.ps1          (updated — coloured pre-scan output)
#      electron\                         (new — Electron GUI)
#      build\Build-Exe.ps1              (new — PS2EXE portable build)
#      choco\                            (new — Chocolatey package)
#      .github\workflows\release.yml    (new — auto-release on version tag)
#      README.md                         (updated)

# 3. Stage everything
git add .

# 4. Commit
git commit -m "Add Electron GUI, PS2EXE build, Chocolatey package, auto-release workflow"

# 5. Push
git push origin main
```

---

### Option C — GitHub web UI (no git needed, for small edits only)

For individual files (e.g. just updating `README.md` or `clean-pc-core.ps1`):

1. Open the file on GitHub → click the **pencil ✏️ edit** icon.
2. Paste the new content → scroll down → **Commit changes**.

Not practical for the whole `electron/` folder — use Option A or B for that.

---

### After pushing — create your first release

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions picks up the tag, builds the portable `.exe` and the NSIS installer, and publishes them as a GitHub Release automatically. The download badges in this README will go live as soon as the first release exists.

---

## Credits

### Designed and engineered with [Replit AI Agent](https://replit.com)

The entire architecture of this project — the three-stage silent deletion pipeline, the pre-scan estimate engine, the space-freed counter, the Electron GUI, the PS2EXE build system, the GitHub Actions release workflow, and the Chocolatey package — was conceived, written, debugged, and refined through conversation with **Replit AI Agent**.

> *"People should honestly certify — the README on GitHub is designed better  
>  by Replit AI than anything we've seen."*  
> — Rajkumar, author

Replit AI Agent wrote every line of PowerShell, every line of JavaScript, every CI workflow step, and this README. The human brought the idea, the real-world Windows pain points, and the vision. Replit brought the engineering.

**[→ Build your own app on Replit](https://replit.com)**

---

### Inspired by

[Kudu by AdventDevInc](https://github.com/AdventDevInc/kudu) — a polished Electron-based cross-platform cleaner that showed what a great UI for this category of tool could look like.

---

## License

MIT — see [LICENSE](LICENSE).
