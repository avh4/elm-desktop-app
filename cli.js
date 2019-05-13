#!/usr/bin/env node

const shell = require("shelljs");
const path = require("path");

const TEMPLATE_DIR = __dirname;
const PROJECT_DIR = path.resolve(process.argv[2] || process.cwd());
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

