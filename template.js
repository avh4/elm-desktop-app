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

ipc.on('write-out', function (event, files) {
  files.forEach(function(file) {
    const filename = file[0];
    const content = file[1];
    console.log(`Writing ${filename}: ${content.length} characters`);
    fs.writeFile(filename, content, 'utf-8', function(err) {
    });
  });
});

app.on('ready', createWindow);
