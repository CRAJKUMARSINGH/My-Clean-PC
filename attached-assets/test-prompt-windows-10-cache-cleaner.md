# Windows 10 Cache-Cleaning Scripts Test Prompt & Requirements

Source prompt received:
```text
Review, test, and repair the Windows 10 cache-cleaning scripts in the root of my repository.

The current scripts claim to perform a 24-minute cleanup of Windows temporary files, AI/application cache, and browser cache, but I doubt they clean as effectively as the built-in Command Prompt utility cleanmgr.exe.

Please inspect the repository before changing anything. Identify every cleanup script, explain what each one actually removes, and compare its behavior with:

cleanmgr /sageset:1
cleanmgr /sagerun:1

Create a safe, evidence-based cleanup process for Windows 10 that:

Cleans user temporary files such as %TEMP%.

Cleans the Windows temporary directory only where safe.

Cleans relevant Windows and application caches.

Cleans browser cache for installed browsers, including Chrome, Edge, and Firefox where present.

Preserves the entire Downloads folder and does not delete, move, or modify files inside it.

Preserves saved browser passwords, cookies, bookmarks, profiles, extensions, autofill data, and browsing history unless explicitly requested.

Does not delete browser databases or entire browser profiles.

Does not remove Windows Update rollback files, restore points, personal files, installed applications, or system-critical files without explicit confirmation.

Handles files currently in use without reporting false success.

Uses dry-run, confirmation, logging, error handling, and accurate before/after disk-space measurements.

Requires browsers and selected applications to be closed before cleaning their cache.

Uses only documented Windows 10 commands and safe PowerShell or batch operations.

Testing requirements:

Inspect the repository structure and identify the current entry point.

Run a non-destructive audit or dry-run first.

Record each target directory, file count, total size, skipped files, locked files, and permission failures.

Verify that Downloads and browser password/profile databases remain unchanged.

Compare the script’s results with cleanmgr.exe; do not assume that deleting more files means cleaning more effectively.

Test with Chrome, Microsoft Edge, and Firefox if installed.

Check that browser cache directories are recreated correctly after cleaning.

Run the repaired script twice and confirm that the second run does not repeatedly delete important data or report misleading results.

Add automated tests or validation checks for path safety, especially to prevent accidental deletion outside approved cache directories.

Provide a clear report containing the problems found, files changed, commands tested, remaining limitations, and exact instructions for running the cleanup safely.

Important safety rule: Never use a broad recursive deletion such as Remove-Item C:\Users\...\*, never delete the contents of Downloads, and never delete complete browser profiles. If a target is ambiguous or potentially destructive, stop and request confirmation instead of guessing.
```
