@echo off
setlocal EnableExtensions
title My Clean PC - Windows Cache Cleaner
echo ============================================
echo   My Clean PC - Windows Cache Cleaner
echo   Designed for Priyanka
echo ============================================
echo.
echo  Passwords (Login Data) are NEVER touched.
echo  Downloads folder is NEVER touched.
echo.

:: ════════════════════════════════════════════
echo --- AI IDE App Caches ---
echo.

:: ── Antigravity / Antigravity IDE ─────────────────────────────────────
echo [1/9] Antigravity...
if exist "%APPDATA%\Antigravity"      rd /s /q "%APPDATA%\Antigravity" 2>nul
if exist "%LOCALAPPDATA%\Antigravity" rd /s /q "%LOCALAPPDATA%\Antigravity" 2>nul
echo   Done.

:: ── Cursor ────────────────────────────────────────────────────────────
echo [2/9] Cursor...
if exist "%APPDATA%\Cursor\Cache"       rd /s /q "%APPDATA%\Cursor\Cache" 2>nul
if exist "%APPDATA%\Cursor\CachedData"  rd /s /q "%APPDATA%\Cursor\CachedData" 2>nul
if exist "%APPDATA%\Cursor\logs"        rd /s /q "%APPDATA%\Cursor\logs" 2>nul
if exist "%LOCALAPPDATA%\cursor-updater" rd /s /q "%LOCALAPPDATA%\cursor-updater" 2>nul
echo   Done.

:: ── Qoder ─────────────────────────────────────────────────────────────
echo [3/9] Qoder...
if exist "%APPDATA%\Qoder"      rd /s /q "%APPDATA%\Qoder" 2>nul
if exist "%LOCALAPPDATA%\Qoder" rd /s /q "%LOCALAPPDATA%\Qoder" 2>nul
echo   Done.

:: ── Kiro ──────────────────────────────────────────────────────────────
echo [4/9] Kiro...
if exist "%APPDATA%\kiro\Cache"      rd /s /q "%APPDATA%\kiro\Cache" 2>nul
if exist "%APPDATA%\kiro\CachedData" rd /s /q "%APPDATA%\kiro\CachedData" 2>nul
if exist "%LOCALAPPDATA%\kiro"        rd /s /q "%LOCALAPPDATA%\kiro" 2>nul
echo   Done.

:: ── Trae AI ───────────────────────────────────────────────────────────
echo [5/9] Trae AI...
if exist "%APPDATA%\Trae"      rd /s /q "%APPDATA%\Trae" 2>nul
if exist "%APPDATA%\trae-ai"   rd /s /q "%APPDATA%\trae-ai" 2>nul
if exist "%LOCALAPPDATA%\Trae" rd /s /q "%LOCALAPPDATA%\Trae" 2>nul
echo   Done.

:: ── Windsurf ──────────────────────────────────────────────────────────
echo [6/9] Windsurf...
if exist "%APPDATA%\Windsurf\Cache"      rd /s /q "%APPDATA%\Windsurf\Cache" 2>nul
if exist "%APPDATA%\Windsurf\CachedData" rd /s /q "%APPDATA%\Windsurf\CachedData" 2>nul
if exist "%APPDATA%\Windsurf\logs"       rd /s /q "%APPDATA%\Windsurf\logs" 2>nul
if exist "%LOCALAPPDATA%\Windsurf"        rd /s /q "%LOCALAPPDATA%\Windsurf" 2>nul
echo   Done.

:: ── Devin ─────────────────────────────────────────────────────────────
echo [7/9] Devin...
if exist "%APPDATA%\Devin"      rd /s /q "%APPDATA%\Devin" 2>nul
if exist "%LOCALAPPDATA%\Devin" rd /s /q "%LOCALAPPDATA%\Devin" 2>nul
echo   Done.

:: ── Warp ──────────────────────────────────────────────────────────────
echo [8/9] Warp...
if exist "%APPDATA%\warp"             rd /s /q "%APPDATA%\warp" 2>nul
if exist "%LOCALAPPDATA%\Warp\data"  rd /s /q "%LOCALAPPDATA%\Warp\data" 2>nul
echo   Done.

:: ── Genspark (app) ────────────────────────────────────────────────────
echo [9/9] Genspark (app)...
if exist "%APPDATA%\Genspark"      rd /s /q "%APPDATA%\Genspark" 2>nul
if exist "%LOCALAPPDATA%\Genspark" rd /s /q "%LOCALAPPDATA%\Genspark" 2>nul
echo   Done.

:: ════════════════════════════════════════════
echo.
echo --- All Installed Browsers (auto-detect, passwords kept safe) ---
echo.

if exist "%~dp0clean-pc-core.ps1" (
  echo [B] Scanning PC for ALL browsers — cache/cookies/history like Ctrl+Shift+Delete...
  powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "$ConfirmPreference='None'; $ErrorActionPreference='SilentlyContinue'; . '%~dp0clean-pc-core.ps1'; Clear-AllInstalledBrowsers -Log { param($m) Write-Host ('  '+$m) }"
  echo   Done. Passwords ^(Login Data / key4.db^) were NOT touched.
  goto :afterBrowsers
)

:: Fallback if clean-pc-core.ps1 is missing (legacy hardcoded list)
goto :afterfn
:ChromeClean
  for /d %%P in ("%~1\*") do (
    rd /s /q "%%P\Cache"                        2>nul
    rd /s /q "%%P\Code Cache"                   2>nul
    rd /s /q "%%P\GPUCache"                     2>nul
    rd /s /q "%%P\Media Cache"                  2>nul
    rd /s /q "%%P\blob_storage"                 2>nul
    rd /s /q "%%P\Service Worker\CacheStorage" 2>nul
    rd /s /q "%%P\Service Worker\ScriptCache"  2>nul
    rd /s /q "%%P\Local Storage"                2>nul
    rd /s /q "%%P\IndexedDB"                    2>nul
    rd /s /q "%%P\Session Storage"              2>nul
    rd /s /q "%%P\Application Cache"            2>nul
    rd /s /q "%%P\Network"                      2>nul
    rd /s /q "%%P\Extension State"              2>nul
    rd /s /q "%%P\Storage"                      2>nul
    del /f /q "%%P\Cookies"                     2>nul
    del /f /q "%%P\Cookies-journal"             2>nul
    del /f /q "%%P\History"                     2>nul
    del /f /q "%%P\History-journal"             2>nul
    del /f /q "%%P\Visited Links"               2>nul
    del /f /q "%%P\Top Sites"                   2>nul
    del /f /q "%%P\Top Sites-journal"           2>nul
    del /f /q "%%P\Shortcuts"                   2>nul
    del /f /q "%%P\Shortcuts-journal"           2>nul
    del /f /q "%%P\Network Action Predictor"    2>nul
    del /f /q "%%P\Favicons"                    2>nul
    del /f /q "%%P\Favicons-journal"            2>nul
    del /f /q "%%P\Current Session"             2>nul
    del /f /q "%%P\Last Session"                2>nul
    del /f /q "%%P\Current Tabs"                2>nul
    del /f /q "%%P\Last Tabs"                   2>nul
    del /f /q "%%P\Download Service\EntryDB"   2>nul
    del /f /q "%%P\Web Data"                    2>nul
    del /f /q "%%P\Web Data-journal"            2>nul
    del /f /q "%%P\Extension Cookies"           2>nul
    del /f /q "%%P\QuotaManager"                2>nul
    :: Login Data and Login Data For Account are intentionally SKIPPED
  )
  exit /b
:afterfn
echo   WARNING: clean-pc-core.ps1 not found — using limited browser list.
if exist "%LOCALAPPDATA%\Google\Chrome\User Data" call :ChromeClean "%LOCALAPPDATA%\Google\Chrome\User Data"
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data" call :ChromeClean "%LOCALAPPDATA%\Microsoft\Edge\User Data"
if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data" call :ChromeClean "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data"
if exist "%LOCALAPPDATA%\Vivaldi\User Data" call :ChromeClean "%LOCALAPPDATA%\Vivaldi\User Data"
if exist "%APPDATA%\Opera Software\Opera Stable" call :ChromeClean "%APPDATA%\Opera Software\Opera Stable"
if exist "%APPDATA%\Mozilla\Firefox\Profiles" (
  for /d %%P in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do (
    rd /s /q "%%P\cache2" 2>nul
    del /f /q "%%P\cookies.sqlite" 2>nul
    del /f /q "%%P\places.sqlite" 2>nul
  )
)
echo   Done.
:afterBrowsers

:: ════════════════════════════════════════════
echo.
echo --- Windows Prefetch ---
echo.

echo [P1] Windows Prefetch (C:\Windows\Prefetch)...
del /f /q "C:\Windows\Prefetch\*.pf" 2>nul
echo   Done.

echo [P2] User prefetch / Recent Activity...
if exist "%APPDATA%\Microsoft\Windows\Recent" (
  del /f /q "%APPDATA%\Microsoft\Windows\Recent\*" 2>nul
)
if exist "%LOCALAPPDATA%\Microsoft\Windows\History" (
  rd /s /q "%LOCALAPPDATA%\Microsoft\Windows\History" 2>nul
)
echo   Done.

:: ════════════════════════════════════════════
echo.
echo --- Temp Files ---
echo.

echo [T1] User Temp (%%TEMP%%)...
if exist "%TEMP%" (
  del /f /s /q "%TEMP%\*" 2>nul
  for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" 2>nul
)
echo   Done.

echo [T2] Windows Temp (C:\Windows\Temp)...
if exist "C:\Windows\Temp" (
  del /f /s /q "C:\Windows\Temp\*" 2>nul
  for /d %%D in ("C:\Windows\Temp\*") do rd /s /q "%%D" 2>nul
)
echo   Done.

echo [T3] Local AppData Temp (%LOCALAPPDATA%\Temp)...
if exist "%LOCALAPPDATA%\Temp" (
  del /f /s /q "%LOCALAPPDATA%\Temp\*" 2>nul
  for /d %%D in ("%LOCALAPPDATA%\Temp\*") do rd /s /q "%%D" 2>nul
)
echo   Done.

echo [T4] Extra local temp (CrashDumps, D3DSCache, WebCache)...
if exist "%LOCALAPPDATA%\CrashDumps" rd /s /q "%LOCALAPPDATA%\CrashDumps" 2>nul
if exist "%LOCALAPPDATA%\D3DSCache" (
  del /f /s /q "%LOCALAPPDATA%\D3DSCache\*" 2>nul
  for /d %%D in ("%LOCALAPPDATA%\D3DSCache\*") do rd /s /q "%%D" 2>nul
)
if exist "%LOCALAPPDATA%\Microsoft\Windows\WebCache" rd /s /q "%LOCALAPPDATA%\Microsoft\Windows\WebCache" 2>nul
echo   Done.

echo [T5] Temp folders inside every Local app...
for /d %%A in ("%LOCALAPPDATA%\*") do (
  if exist "%%A\Temp" rd /s /q "%%A\Temp" 2>nul
  if exist "%%A\temp" rd /s /q "%%A\temp" 2>nul
  if exist "%%A\tmp"  rd /s /q "%%A\tmp"  2>nul
)
echo   Done.

:: ════════════════════════════════════════════
echo.
echo --- Rigorous AppData Sweep (all apps, max safe junk) ---
echo.

echo [L1] Local AppData - Cache/Logs/Temp in ALL apps...
for /d %%A in ("%LOCALAPPDATA%\*") do call :ClearAppJunk "%%A"
for /d %%A in ("%LOCALAPPDATA%\*") do (
  for /d %%B in ("%%A\*") do call :ClearAppJunk "%%B"
  for /d %%B in ("%%A\*") do (
    for /d %%C in ("%%B\*") do call :ClearAppJunk "%%C"
  )
)
echo   Done.

echo [L2] Roaming AppData - Cache/Logs/Temp in ALL apps...
for /d %%A in ("%APPDATA%\*") do call :ClearAppJunk "%%A"
for /d %%A in ("%APPDATA%\*") do (
  for /d %%B in ("%%A\*") do call :ClearAppJunk "%%B"
  for /d %%B in ("%%A\*") do (
    for /d %%C in ("%%B\*") do call :ClearAppJunk "%%C"
  )
)
echo   Done.

goto :afterjunk
:ClearAppJunk
  if exist "%~1\Cache" rd /s /q "%~1\Cache" 2>nul
  if exist "%~1\Caches" rd /s /q "%~1\Caches" 2>nul
  if exist "%~1\CachedData" rd /s /q "%~1\CachedData" 2>nul
  if exist "%~1\Code Cache" rd /s /q "%~1\Code Cache" 2>nul
  if exist "%~1\GPUCache" rd /s /q "%~1\GPUCache" 2>nul
  if exist "%~1\Media Cache" rd /s /q "%~1\Media Cache" 2>nul
  if exist "%~1\Temp" rd /s /q "%~1\Temp" 2>nul
  if exist "%~1\temp" rd /s /q "%~1\temp" 2>nul
  if exist "%~1\tmp" rd /s /q "%~1\tmp" 2>nul
  if exist "%~1\Logs" rd /s /q "%~1\Logs" 2>nul
  if exist "%~1\logs" rd /s /q "%~1\logs" 2>nul
  if exist "%~1\Log" rd /s /q "%~1\Log" 2>nul
  if exist "%~1\crashpad" rd /s /q "%~1\crashpad" 2>nul
  if exist "%~1\CrashDumps" rd /s /q "%~1\CrashDumps" 2>nul
  if exist "%~1\blob_storage" rd /s /q "%~1\blob_storage" 2>nul
  if exist "%~1\startupCache" rd /s /q "%~1\startupCache" 2>nul
  if exist "%~1\OfflineCache" rd /s /q "%~1\OfflineCache" 2>nul
  if exist "%~1\Application Cache" rd /s /q "%~1\Application Cache" 2>nul
  if exist "%~1\INetCache" rd /s /q "%~1\INetCache" 2>nul
  if exist "%~1\WebCache" rd /s /q "%~1\WebCache" 2>nul
  if exist "%~1\Updater" rd /s /q "%~1\Updater" 2>nul
  if exist "%~1\updater" rd /s /q "%~1\updater" 2>nul
  if exist "%~1\storage" rd /s /q "%~1\storage" 2>nul
  exit /b
:afterjunk

:: ════════════════════════════════════════════
echo.
echo --- Recycle Bin ---
echo.

echo [R1] Emptying Recycle Bin...
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Add-Type 'using System; using System.Runtime.InteropServices; public static class RB { [DllImport(\"Shell32.dll\")] public static extern int SHEmptyRecycleBin(IntPtr h, string r, uint f); }'; [RB]::SHEmptyRecycleBin([IntPtr]::Zero,$null,7)|Out-Null" 2>nul
echo   Done.

:: ════════════════════════════════════════════
echo.
echo --- Windows Update Cache ---
echo.

echo [W1] SoftwareDistributionDownload...
if exist "C:\Windows\SoftwareDistribution\Download" (
  del /f /s /q "C:\Windows\SoftwareDistribution\Download\*" 2>nul
  for /d %%D in ("C:\Windows\SoftwareDistribution\Download\*") do rd /s /q "%%D" 2>nul
)
echo   Done.

echo [W2] Windows Update logs...
if exist "C:\Windows\SoftwareDistribution\DataStore\Logs" (
  del /f /s /q "C:\Windows\SoftwareDistribution\DataStore\Logs\*" 2>nul
)
echo   Done.

:: ════════════════════════════════════════════
echo.
echo --- Thumbnail Cache ---
echo.

echo [N1] Explorer thumbnail cache...
if exist "%LOCALAPPDATA%\Microsoft\Windows\Explorer" (
  del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" 2>nul
  del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db"  2>nul
)
echo   Done.

echo [N2] WinINet / Internet cache...
if exist "%LOCALAPPDATA%\Microsoft\Windows\INetCache" rd /s /q "%LOCALAPPDATA%\Microsoft\Windows\INetCache" 2>nul
echo   Done.

:: ════════════════════════════════════════════
echo.
echo --- Windows Event Logs ---
echo.

echo [E1] Application log...
wevtutil cl Application 2>nul
echo   Done.

echo [E2] System log...
wevtutil cl System 2>nul
echo   Done.

echo [E3] Security log...
wevtutil cl Security 2>nul
echo   Done.

echo [E4] Setup log...
wevtutil cl Setup 2>nul
echo   Done.

:: ════════════════════════════════════════════
echo.
echo --- DNS Cache ---
echo.

echo [D1] Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
echo   Done.

echo.
echo ============================================
echo   All done!
echo   Rigorous temp + AppData sweep completed.
echo   Passwords (Login Data) were NOT touched.
echo   Downloads folder was NOT touched.
echo ============================================
