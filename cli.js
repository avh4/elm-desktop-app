#!/usr/bin/env node

const shell = require("shelljs");
const path = require("path");

const TEMPLATE_DIR = __dirname;
const PROJECT_DIR = path.resolve(process.argv[3] || process.cwd());
const BUILD_DIR = path.join(PROJECT_DIR, "elm-stuff", "elm-desktop-app");

function main(args) {
  switch (args[0]) {
  case "build":
    build();
    break;

  case "run":
    build();
    shell.exec(path.join(BUILD_DIR, "node_modules", ".bin", "electron") + " " + BUILD_DIR) // TODO: stop using shelljs to properly escape output here
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
}

function build() {
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
}

main(process.argv.slice(2));
