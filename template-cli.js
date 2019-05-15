#!/usr/bin/env node

const electron = require('electron');
const proc = require('child_process');

const child = proc.spawn(electron, [__dirname], {stdio: 'inherit'})
child.on('close', function (code) {
  process.exit(code);
});
