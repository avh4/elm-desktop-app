const { app, BrowserWindow } = require('electron');
const ipc = require('electron').ipcMain;
const fs = require('fs');
const path = require('path');

function getUserDataFilename() {
  return new Promise(function(resolve) {
    const filename = process.argv[2] || path.join(app.getPath("userData"), 'user-data.json');
    resolve(filename);
  });
}

function createWindow(userDataFilename) {
  let win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true
    }
  });

  win.loadFile('index.html');

  ipc.on('write-user-data', function (event, content) {
    const filename = userDataFilename;
    console.log(`Writing ${filename}: ${content.length} characters`);
    fs.writeFile(filename, content, 'utf-8', function(err) {
    });
  });

  ipc.on('load-user-data', function(event, _unit) {
    const filepath = userDataFilename;
    fs.readFile(filepath, 'utf-8', (err, content) => {
      if (err) {
        if (err.code === 'ENOENT') {
          event.reply('user-data-loaded', null);
        } else {
          throw err;
        }
      } else {
        event.reply('user-data-loaded', content);
      }
    });
  });
}

app.on('ready', function() {
  getUserDataFilename().then(function(filename) {
    console.log(`Using file: ${filename}`);
    createWindow(filename);
  });
});
