const { app, BrowserWindow, ipcMain, shell } = require('electron')
const path  = require('path')
const { spawn } = require('child_process')

// Resolve the bundled scripts folder.
// In production:  process.resourcesPath/scripts/
// In development: ../scripts/ (sibling of the electron/ folder)
function scriptsDir () {
  return app.isPackaged
    ? path.join(process.resourcesPath, 'scripts')
    : path.join(__dirname, '..', 'scripts')
}

function createWindow () {
  const win = new BrowserWindow({
    width: 760,
    height: 600,
    resizable: false,
    frame: false,           // custom title bar in renderer
    backgroundColor: '#0f0f1a',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false
    },
    icon: path.join(__dirname, 'assets', 'icon.png')
  })

  win.loadFile(path.join(__dirname, 'renderer', 'index.html'))
}

app.whenReady().then(() => {
  createWindow()
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})

// ── IPC: window controls ─────────────────────────────────────────────────────
ipcMain.on('win:minimize', () => BrowserWindow.getFocusedWindow()?.minimize())
ipcMain.on('win:close',    () => BrowserWindow.getFocusedWindow()?.close())

// ── IPC: run the cleaner ─────────────────────────────────────────────────────
ipcMain.on('clean:start', (event) => {
  const script = path.join(scriptsDir(), 'my-clean-pc.ps1')
  const send   = (ch, data) => {
    if (!event.sender.isDestroyed()) event.sender.send(ch, data)
  }

  const ps = spawn('powershell.exe', [
    '-NoProfile',
    '-NonInteractive',
    '-ExecutionPolicy', 'Bypass',
    '-File', script
  ], {
    windowsHide: true,
    // Merge stderr into stdout so every line arrives in order
    stdio: ['ignore', 'pipe', 'pipe']
  })

  const onLine = (chunk) => {
    String(chunk).split(/\r?\n/).forEach(line => {
      if (line.trim()) send('clean:line', line)
    })
  }

  ps.stdout.on('data', onLine)
  ps.stderr.on('data', onLine)

  ps.on('close', (code) => {
    send('clean:done', { code })
  })
})
