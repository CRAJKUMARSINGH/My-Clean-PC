# Chat Saved

User reported three cleaner shortcomings:

- Quick Access pinned tabs/items were being removed.
- `C:\Users\Rajkumar\AppData\Local\Temp` deletion showed repeated Windows prompts and required ticking "do this for all current items".
- Roaming AppData cleanup needed the same prompt-free behavior.

Requested fixes:

- Use prompt-free positive handling where Windows asks for delete confirmation, while skipping locked files automatically.
- Add `.ps1` download alongside `.bat` one-click cleaner.
- Clean all browser periods like Ctrl+Shift+Delete, but do not delete passwords or autofill.
- Run CleanMgr on `C:` while excluding Downloads.
- Clean app cache in Roaming for all apps.
- Add a README section explaining what the app does.
- Show a visible completion message: `THANKS CODEX FOR UR CLEAN PC`.
