# My Clean PC

One-click Windows cleaner downloads are available as both `.bat` and `.ps1` files. Keep `clean-pc-core.ps1` in the same folder as the launcher you run.

## What Action The App Does

- Clears Windows temp folders, including `C:\Users\<user>\AppData\Local\Temp`, with prompt-free deletion and locked-file auto-skip.
- Sweeps Local AppData and Roaming AppData cache/junk folders for installed apps.
- Cleans browser cache, cookies, history/site data where safe, service worker cache, and similar Ctrl+Shift+Delete-style data for all detected browsers.
- Keeps browser passwords, autofill/form data, bookmarks, Downloads, personal files, current tabs/session restore files, and Quick Access pins untouched.
- Firefox note: `places.sqlite` is not deleted because it stores bookmarks together with history. Deleting it would violate the "bookmarks safe" promise.
- Runs Windows Disk Cleanup for the `C:` drive with download-related categories excluded.
- Empties Recycle Bin, clears Windows Update cache where permissions allow, flushes DNS cache, and clears selected event logs.
- Shows progress while cleaning and prints `THANKS CODEX FOR UR CLEAN PC` on completion.

Locked or in-use files cannot be deleted until the owning app is closed or Windows releases the handle. The cleaner skips those files without asking the user and may register them for deletion on reboot.
