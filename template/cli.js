#!/usr/bin/env node

const electron = require('electron');
const proc = require('child_process');

const args = [__dirname].concat(process.argv.slice(2));
const child = proc.spawn(electron, args, {stdio: 'inherit'})
child.on('close', function (code) {
  process.exit(code);
});
