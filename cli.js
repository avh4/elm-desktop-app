#!/usr/bin/env node

const shell = require("shelljs");
const path = require("path");

switch (process.argv[2]) {
case "build":
  const TEMPLATE_DIR = __dirname;
  const PROJECT_DIR = path.resolve(process.argv[3] || process.cwd());
  const BUILD_DIR = path.join(PROJECT_DIR, "elm-stuff", "elm-desktop-app");

  shell.mkdir("-p", BUILD_DIR);

  shell.pushd(BUILD_DIR);
  if (!shell.test("-e", "package.json")) {
    shell.exec("npm init -y");
  }
  if (!shell.test("-e", "node_modules/electron")) {
    shell.exec("npm install --save-dev electron");
  }
  shell.popd();

  shell.pushd(PROJECT_DIR);
  const output = path.join(BUILD_DIR, "elm.js");
  shell.exec("elm make Main.elm --output " + output); // TODO: stop using shelljs to properly escape output here
  shell.popd();

  shell.cp(path.join(TEMPLATE_DIR, "template.js"), path.join(BUILD_DIR, "index.js"));
  shell.cp(path.join(TEMPLATE_DIR, "template.html"), path.join(BUILD_DIR, "index.html"));

  break;

case "init":
  shell.exec("yes | elm init");
  shell.exec("yes | elm install elm/json");
  break;

default:
  process.stdout.write("Usage:\n");
  process.stdout.write("    elm-desktop-app init [<directory>]\n");
  process.stdout.write("    elm-desktop-app build [<directory>]\n");
  process.stdout.write("\n");
  process.stdout.write("Options:\n");
  process.stdout.write("    directory: defaults to the current directory\n");
  break;
}

