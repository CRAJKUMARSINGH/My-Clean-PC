const { contextBridge, ipcRenderer } = require('electron')

contextBridge.exposeInMainWorld('api', {
  // Window controls
  minimize: () => ipcRenderer.send('win:minimize'),
  close:    () => ipcRenderer.send('win:close'),

  // Cleaning
  startClean: ()         => ipcRenderer.send('clean:start'),
  onLine:     (cb)       => ipcRenderer.on('clean:line', (_e, line) => cb(line)),
  onDone:     (cb)       => ipcRenderer.on('clean:done', (_e, info) => cb(info)),

  // Remove listeners when renderer navigates away
  removeAll: () => {
    ipcRenderer.removeAllListeners('clean:line')
    ipcRenderer.removeAllListeners('clean:done')
  }
})
