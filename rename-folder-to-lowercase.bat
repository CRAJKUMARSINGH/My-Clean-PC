@echo off
title Rename Folder to lowercase my-clean-pc
cd /d "%~dp0.."

echo Attempting to rename folder to lowercase 'my-clean-pc'...
ren "My-Clean-PC" "my-clean-pc-tmp" 2>nul
ren "my-clean-pc-tmp" "my-clean-pc" 2>nul

if exist "e:\Rajkumar\my-clean-pc" (
    echo.
    echo ============================================================
    echo   SUCCESS: Folder renamed to: e:\Rajkumar\my-clean-pc
    echo ============================================================
) else (
    echo.
    echo [NOTE] Windows has locked the folder because your IDE/editor is currently open.
    echo To finish the rename:
    echo   1. Close this IDE/editor window.
    echo   2. Double-click this batch file.
    echo   3. Reopen the folder in your editor.
)
echo.
pause
