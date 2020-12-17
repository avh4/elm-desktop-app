const { app, BrowserWindow, Menu, dialog } = require('electron');
const ipc = require('electron').ipcMain;
const fs = require('fs');
const path = require('path');

function getUserDataFilename() {
  return new Promise(function(resolve) {
    const config = JSON.parse(fs.readFileSync(path.join(__dirname, 'elm.json')));
    const userSuppliedFilename = process.argv[2];
    const useDataFileInCurrentDir = config['elm-desktop-app']['use-data-file-in-current-directory'];

    if (useDataFileInCurrentDir) {
      function resolvePathOrDir(f) {
        if (fs.lstatSync(f).isDirectory()) {
          // if the user gave a directory, use the default filename in that dir
          resolve(path.join(f, useDataFileInCurrentDir));
        } else {
          // the user gave a file, so use that file
          resolve(f);
        }
      }

      if (userSuppliedFilename) {
        resolvePathOrDir(userSuppliedFilename);
      } else {
        const launchedFromCli = process.env.ELM_DESKTOP_APP_LAUNCHED_FROM_CLI || false;
        if (launchedFromCli) {
          // user didn't request anything, so use the default filename in the current dir
          resolve(path.join(process.cwd(), useDataFileInCurrentDir));
        } else {
          // we need to prompt the user for a directory/file
          app.focus();
          dialog.showOpenDialog({
            message: `Choose a JSON file, or a directory for ${useDataFileInCurrentDir}`,
            filters: [
              { name: "JSON Files", extensions: ['json'] },
              { name: "All Files", extensions: ['*'] }
            ],
            properties: [
              "openFile",
              "openDirectory",
              "createDirectory",
              "promptToCreate"
            ],
          }, function(filePaths) {
            if (!filePaths) {
              // the user cancelled opening a file
              app.quit();
            } else {
              resolvePathOrDir(filePaths[0]);
            }
          });
        }
      }
    } else {
      if (userSuppliedFilename) {
        // the user gave a file, so use that file
        resolve(userSuppliedFilename);
      } else {
        // user didn't request anything, so make a file in the userData dir
        resolve(path.join(app.getPath("userData"), 'user-data.json'));
      }
    }
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

  ipc.on('set-menu', function(event, menubar) {
    switch (menubar) {
      case 'NoMenu':
        win.removeMenu();
        break;
      case 'DefaultMenu':
        win.setMenu(Menu.getApplicationMenu());
        break;
      default:
        console.log(menubar);
        var menu = Menu.buildFromTemplate(menubar);
        win.setMenu(menu);
        // TODO: set Applicaiton menu also
//        win.alert(menubar);
//        throw new Error("Internal error: Please report this to https://github.com/avh4/elm-desktop-app/issues Received unexpected set-menu event: " + JSON.stringify(menubar));
    }
  });
}

app.on('ready', function() {
  getUserDataFilename().then(function(filename) {
    console.log(`Using file: ${filename}`);
    createWindow(filename);
  });
});
