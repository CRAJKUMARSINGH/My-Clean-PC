@echo off
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
echo --- Browser Cache + History (passwords kept safe) ---
echo.

:: helper: clear Chromium cache folders, NEVER Login Data
:: usage: call :ChromeClean "path\to\User Data"
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

:: ── Google Chrome ─────────────────────────────────────────────────────
echo [B1/8] Google Chrome...
if exist "%LOCALAPPDATA%\Google\Chrome\User Data" (
  call :ChromeClean "%LOCALAPPDATA%\Google\Chrome\User Data"
)
echo   Done.

:: ── Microsoft Edge ────────────────────────────────────────────────────
echo [B2/8] Microsoft Edge...
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data" (
  call :ChromeClean "%LOCALAPPDATA%\Microsoft\Edge\User Data"
)
echo   Done.

:: ── Brave ─────────────────────────────────────────────────────────────
echo [B3/8] Brave...
if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data" (
  call :ChromeClean "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data"
)
echo   Done.

:: ── Vivaldi ───────────────────────────────────────────────────────────
echo [B4/8] Vivaldi...
if exist "%LOCALAPPDATA%\Vivaldi\User Data" (
  call :ChromeClean "%LOCALAPPDATA%\Vivaldi\User Data"
)
echo   Done.

:: ── Opera ─────────────────────────────────────────────────────────────
echo [B5/8] Opera...
if exist "%APPDATA%\Opera Software\Opera Stable" (
  call :ChromeClean "%APPDATA%\Opera Software\Opera Stable"
)
echo   Done.

:: ── Genspark Browser ──────────────────────────────────────────────────
echo [B6/8] Genspark Browser...
if exist "%LOCALAPPDATA%\Genspark\User Data" (
  call :ChromeClean "%LOCALAPPDATA%\Genspark\User Data"
)
echo   Done.

:: ── Yandex Browser ────────────────────────────────────────────────────
echo [B7/8] Yandex Browser...
if exist "%LOCALAPPDATA%\Yandex\YandexBrowser\User Data" (
  call :ChromeClean "%LOCALAPPDATA%\Yandex\YandexBrowser\User Data"
)
echo   Done.

:: ── Firefox ───────────────────────────────────────────────────────────
echo [B8/8] Firefox...
if exist "%APPDATA%\Mozilla\Firefox\Profiles" (
  for /d %%P in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do (
    rd /s /q "%%P\cache2"          2>nul
    rd /s /q "%%P\startupCache"    2>nul
    rd /s /q "%%P\OfflineCache"    2>nul
    rd /s /q "%%P\thumbnails"      2>nul
    rd /s /q "%%P\storage"         2>nul
    del /f /q "%%P\cookies.sqlite"              2>nul
    del /f /q "%%P\cookies.sqlite-shm"          2>nul
    del /f /q "%%P\cookies.sqlite-wal"          2>nul
    del /f /q "%%P\places.sqlite"               2>nul
    del /f /q "%%P\places.sqlite-shm"           2>nul
    del /f /q "%%P\places.sqlite-wal"           2>nul
    del /f /q "%%P\formhistory.sqlite"          2>nul
    del /f /q "%%P\formhistory.sqlite-shm"      2>nul
    del /f /q "%%P\formhistory.sqlite-wal"      2>nul
    del /f /q "%%P\downloads.sqlite"            2>nul
    del /f /q "%%P\favicons.sqlite"             2>nul
    del /f /q "%%P\favicons.sqlite-shm"         2>nul
    del /f /q "%%P\favicons.sqlite-wal"         2>nul
    del /f /q "%%P\webappsstore.sqlite"         2>nul
    del /f /q "%%P\content-prefs.sqlite"        2>nul
    del /f /q "%%P\permissions.sqlite"          2>nul
    del /f /q "%%P\sessionstore.jsonlz4"        2>nul
    del /f /q "%%P\sessionCheckpoints.json"     2>nul
    del /f /q "%%P\previous.jsonlz4"            2>nul
    del /f /q "%%P\recovery.jsonlz4"            2>nul
    del /f /q "%%P\recovery.baklz4"             2>nul
    :: key4.db (saved passwords) intentionally SKIPPED
  )
)
echo   Done.

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

:: ════════════════════════════════════════════
echo.
echo --- Recycle Bin ---
echo.

echo [R1] Emptying Recycle Bin...
for /d %%R in ("%SystemDrive%$Recycle.Bin*") do rd /s /q "%%R" 2>nul
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
echo   Passwords (Login Data) were NOT touched.
echo   Downloads folder was NOT touched.
echo ============================================
pause
