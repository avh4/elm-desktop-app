#!/bin/bash

set -euxo pipefail

TEMPLATE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT_DIR=$(realpath "${1:-.}")
BUILD_DIR=$(realpath .)/_build


mkdir -p "$BUILD_DIR"

pushd "$BUILD_DIR"
if [ ! -e package.json ]; then
    npm init -y
    npm install --save-dev electron
fi
popd

pushd "$PROJECT_DIR"
elm make Main.elm --output "$BUILD_DIR"/elm.js
popd

cp "$TEMPLATE_DIR"/template.js "$BUILD_DIR"/index.js
cp "$TEMPLATE_DIR"/template.html "$BUILD_DIR"/index.html

