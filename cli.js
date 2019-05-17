#!/usr/bin/env node

const shell = require("shelljs");
const path = require("path");
const fs = require("fs");

const DESKTOP_APP_DIR = __dirname;
const TEMPLATE_DIR = path.join(DESKTOP_APP_DIR, "template");
const PROJECT_DIR = path.resolve(process.argv[3] || process.cwd());
const GEN_DIR = path.join(PROJECT_DIR, "elm-stuff", "elm-desktop-app", "gen");
const BUILD_DIR = path.join(PROJECT_DIR, "elm-stuff", "elm-desktop-app", "app");

function main(args) {
  switch (args[0]) {
  case "build":
    build();
    break;

  case "run":
    build();
    const runArgs = [path.join(BUILD_DIR, "cli.js")].concat(process.argv.slice(4)) ;
    shell.exec(runArgs.join(" ")); // TODO: stop using shelljs to properly escape output here
    break;

  case "init":
    const mngen = require("mngen");

    shell.exec("yes | elm init");
    shell.exec("yes | elm install elm/json");
    const elmJson = JSON.parse(fs.readFileSync(path.join(PROJECT_DIR, "elm.json")));
    elmJson['elm-desktop-app'] = {
      "app-id": args[2] || `net.avh4.elm-desktop-app.replace-this-with-your-own-app-id.${mngen.word(3)}`
    };
    fs.writeFileSync(path.join(PROJECT_DIR, "elm.json"), JSON.stringify(elmJson, null, 4));

    shell.cp(path.join(TEMPLATE_DIR, "src", "Main.elm"), path.join(PROJECT_DIR, "src", "Main.elm"));
    break;

  case "package":
    build();

    shell.pushd(BUILD_DIR);
    if (!shell.test("-e", "node_modules/electron-builder")) {
      shell.exec("npm install --save-dev electron-builder");
    }
    shell.exec(path.join(BUILD_DIR, "node_modules", ".bin", "electron-builder") + " --linux --windows --mac");
    shell.popd();

    break;

  default:
    process.stdout.write("Usage:\n");
    process.stdout.write("    elm-desktop-app init <directory> <app-id>\n");
    process.stdout.write("    elm-desktop-app build [<directory>]\n");
    process.stdout.write("    elm-desktop-app run [<directory>]\n");
    process.stdout.write("    elm-desktop-app package [<directory>]\n");
    process.stdout.write("\n");
    process.stdout.write("Options:\n");
    process.stdout.write("    directory: defaults to the current directory\n");
    break;
  }
}

function build() {
  shell.mkdir("-p", GEN_DIR);
  shell.mkdir("-p", BUILD_DIR);

  shell.pushd(BUILD_DIR);
  if (!shell.test("-e", "package.json")) {
    shell.exec("npm init -y");
  }
  if (!shell.test("-e", "node_modules/electron")) {
    shell.exec("npm install --save-dev electron");
  }
  shell.popd();

  shell.rm("-Rf", path.join(GEN_DIR, "src"));
  shell.cp("-R", path.join(DESKTOP_APP_DIR, "src"), path.join(GEN_DIR, "src"));
  shell.cp(path.join(DESKTOP_APP_DIR, "src", "DesktopApp", "RealPorts.elm"), path.join(GEN_DIR, "src", "DesktopApp", "Ports.elm"));

  // TODO: validate elm.json schema

  // Update elm.json
  const elmJson = JSON.parse(fs.readFileSync(path.join(PROJECT_DIR, "elm.json")));
  // TODO: error if it's not an "application" project
  elmJson['source-directories'] = elmJson['source-directories'].map(function(srcDir) {
    return path.resolve(path.join(PROJECT_DIR, srcDir));
  });
  elmJson['source-directories'].push(path.join(GEN_DIR, "src"));
  // TODO: error if it's not the latest version
  delete elmJson['dependencies']['direct']['avh4/elm-desktop-app'];
  fs.writeFileSync(path.join(GEN_DIR, "elm.json"), JSON.stringify(elmJson));

  // Update package.json
  const packageJson = JSON.parse(fs.readFileSync(path.join(BUILD_DIR, "package.json")));
  const appId = elmJson['elm-desktop-app']['app-id'];
  packageJson['name'] = appId;
  packageJson['build'] = {
    appId: appId
  };
  fs.writeFileSync(path.join(BUILD_DIR, "package.json"), JSON.stringify(packageJson));

  // Compile Elm code
  shell.pushd(GEN_DIR);
  const input = path.join(PROJECT_DIR, "src", "Main.elm");
  const output = path.join(BUILD_DIR, "elm.js");
  const result = shell.exec("elm make " + input + " --output " + output); // TODO: stop using shelljs to properly escape output here
  shell.popd();

  if (result.code != 0) {
    throw "Failed to compile Elm";
  }

  // Copy nodejs files
  shell.cp(path.join(TEMPLATE_DIR, "index.js"), path.join(BUILD_DIR, "index.js"));
  shell.cp(path.join(TEMPLATE_DIR, "index.html"), path.join(BUILD_DIR, "index.html"));
  shell.cp(path.join(TEMPLATE_DIR, "cli.js"), path.join(BUILD_DIR, "cli.js"));
  shell.cp(path.join(PROJECT_DIR, "elm.json"), path.join(BUILD_DIR, "elm.json"));
}

main(process.argv.slice(2));
