const { Given, When, Then, Before, After } = require("cucumber");
const shell = require("shelljs");
const expect = require("expect");
const fs = require("fs");

Before(function() {
  shell.rm("-Rf", "_test");
  shell.mkdir("-p", "_test");
  shell.cd("_test");
});

After(function() {
  shell.cd("..");
});

After(function() {
  if (this.app) {
    this.app.stop();
  }
});

When('I create a new app', function () {
  const result = shell.exec("../init-app.sh");
  expect(result.code).toEqual(0);

  // hack the elm.json to use the unpublished packge in this project
  elmJson = JSON.parse(fs.readFileSync("elm.json"));
  elmJson['source-directories'].push("../src");
  fs.writeFileSync("elm.json", JSON.stringify(elmJson));
});

When('I make change my program\'s files to', function (docString) {
  this.Main.main.files = docString;
  this.writeMain();
});

When('I run the app', function () {
  const result = shell.exec("../build-app.sh");
  expect(result.code).toEqual(0);

  var Application = require('spectron').Application;
  var app = new Application({
    path: './_build/node_modules/.bin/electron',
    args: ['./_build']
  });

  this.app = app;

  return app.start();
});

Then('the JSON file {string} is', function (filename, docString) {
  const actual = JSON.parse(fs.readFileSync(filename));
  const expected = JSON.parse(docString);

  expect(actual).toEqual(expected);
});
