const { Given, When, Then, Before, After } = require("cucumber");
const shell = require("shelljs");
const expect = require("expect");
const fs = require("fs");
const path = require("path");

Before(function() {
  shell.rm("-Rf", "_test");
  shell.mkdir("-p", "_test");
  shell.cd("_test");
  this.exec("npm install ../");
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
  world.runElmDesktopApp(["init", ".", world.appId]);
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
  this.Main.main.view = "\\model -> Html.button [onClick Inc] [Html.text \"+\"]";
  this.Main.main.files = "App.jsonFile Loaded (App.jsonMapping identity |> App.withInt \"count\" identity)";
  this.Main.main.noOp = "NoOp";
  return this.writeMain();
});

When('I create a new app', function () {
  initProject(this);
});

When('I make change my program\'s files to', function (docString) {
  this.Main.main.files = docString;
  return this.writeMain();
});

When('I run the app with {string}', function (dataFilename) {
  this.runElmDesktopApp(["build"]);

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

When('click {string}', function (label) {
  this.app.client.waitUntilTextExists("body", label);
  return this.app.client.element("button").click(); // TODO: find the exact button
});

Given('a JSON file {string}', function (filename, docString) {
  fs.writeFileSync(`./${filename}`, docString);
});

Then('the JSON file {string} is', function (filename, docString) {
  const actual = JSON.parse(fs.readFileSync(filename));
  const expected = JSON.parse(docString);

  expect(actual).toEqual(expected);
});
