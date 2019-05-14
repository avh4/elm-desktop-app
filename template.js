const { app, BrowserWindow } = require('electron');
const ipc = require('electron').ipcMain;
const fs = require('fs');

function createWindow () {
  let win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true
    }
  });

  win.loadFile('index.html');
}

ipc.on('write-out', function (event, file) {
  const filename = file[0];
  const content = file[1];
  console.log(`Writing ${filename}: ${content.length} characters`);
  fs.writeFile(filename, content, 'utf-8', function(err) {
  });
});

ipc.on('load-file', function(event, filename) {
  fs.readFile(filename, 'utf-8', (err, content) => {
    if (err) {
      if (err.code === 'ENOENT') {
        event.reply('file-loaded', [filename, null]);
      } else {
        throw err;
      }
    } else {
      event.reply('file-loaded', [filename, content]);
    }
  });
});

app.on('ready', createWindow);
