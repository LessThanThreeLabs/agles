#!/bin/bash
mkdir -p css/src

iced --compile --watch --lint --output js/src/ src/ &
node less-watch-compiler.js src css/src && fg
