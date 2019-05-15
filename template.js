const { app, BrowserWindow } = require('electron');
const ipc = require('electron').ipcMain;
const fs = require('fs');
const path = require('path');

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
const userData = process.argv[2] ? path.dirname(path.resolve(process.argv[2])) : app.getPath("userData");
console.log("userData", userData);

ipc.on('write-user-data', function (event, content) {
  const filename = path.join(userData, 'user-data.json');
  console.log(`Writing ${filename}: ${content.length} characters`);
  fs.writeFile(filename, content, 'utf-8', function(err) {
  });
});

ipc.on('load-user-data', function(event, _unit) {
  const filepath = path.join(userData, 'user-data.json');
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

app.on('ready', createWindow);
