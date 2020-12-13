const { Given, When, Then, Before, After, BeforeAll } = require("cucumber");
const shell = require("shelljs");
const expect = require("expect");
const fs = require("fs");
const path = require("path");

const packageVersion = JSON.parse(fs.readFileSync(path.join(__dirname, "..", "..", "package.json")))["version"];

BeforeAll(function() {
  shell.exec("npm pack");
});

Before(function() {
  // clean
  shell.rm("-Rf", "_test");

  // set up test sandbox
  shell.mkdir("-p", "_test");
  shell.cd("_test");
  this.exec("npm init --yes");
  this.exec(`npm install ../elm-desktop-app-${packageVersion}.tgz`);
});

After(function() {
  shell.cd("..");
});

After(function() {
  if (this.app) {
    const world = this;
    return this.app.client.getMainProcessLogs().then(function (logs) {
      world.attach(logs.join("\n"));
      return world.app.stop();
    });
  }
});

function initProject(world) {
  world.runElmDesktopApp(["init"]);
}

Given('an existing app', function () {
  initProject(this);
  this.Main.Msg = "type Msg = Loaded Int | Inc | NoOp";
  this.Main.main.init = "(0, Cmd.none)";
  this.Main.main.update = "\\msg model -> \n\
    case msg of\n\
        NoOp -> (model, Cmd.none)\n\
        Inc -> (model+1, Cmd.none)\n\
        Loaded i -> (i, Cmd.none)";
  this.Main.main.view = "\\model -> { title = \"\", menubar = DesktopApp.defaultMenu, body = [ Html.button [onClick Inc] [Html.text \"+\"] ] }";
  this.Main.main.persistence = "Just (JsonMapping.object Loaded |> JsonMapping.with \"count\" identity JsonMapping.int)";
  return this.writeMain();
});

When('I create a new app', function () {
  initProject(this);
});

When('I make change my program\'s persistence to', function (docString) {
  this.Main.main.persistence = docString;
  return this.writeMain();
});

When('I run the app with {string}', function (dataFilename) {
  this.runElmDesktopApp(["build"]);

  // workaround for https://github.com/electron-userland/spectron/issues/720#issuecomment-743950042
  const indexJs = fs.readFileSync('./elm-stuff/elm-desktop-app/app/index.js', 'utf8')
    .replace('nodeIntegration: true', 'nodeIntegration: true, enableRemoteModule: true');
  fs.writeFileSync('./elm-stuff/elm-desktop-app/app/index.js', indexJs, 'utf8');

  var Application = require('spectron').Application;
  var app = new Application({
    path: './elm-stuff/elm-desktop-app/app/node_modules/.bin/electron',
    args: [
      './elm-stuff/elm-desktop-app/app',
      dataFilename
    ]
  });

  this.app = app;

  return app.start();
});

Then('I can successfully build my app', function () {
  this.runElmDesktopApp(["build"]);
});

Then('my app has a unique id', function() {
  const elmJson = JSON.parse(fs.readFileSync('elm.json'));
  const appId = elmJson['elm-desktop-app']['app-id'];
  expect(appId).toBeDefined();
  expect(appId.length).toBeGreaterThan(5);
});

When('click {string}', function (label) {
  this.app.client.waitUntilTextExists("body", label);
  return this.app.client.$("button").then(function (button) {
    return button.click(); // TODO: find the exact button
  });
});

Given('a JSON file {string}', function (filename, docString) {
  fs.writeFileSync(`./${filename}`, docString);
});

Then('the JSON file {string} is', function (filename, docString) {
  const actual = JSON.parse(fs.readFileSync(filename));
  const expected = JSON.parse(docString);

  expect(actual).toEqual(expected);
});
