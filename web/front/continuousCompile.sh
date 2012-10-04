#!/bin/bash 
iced --compile --watch --lint --output js/src/ coffee/ &
node less-watch-compiler.js less css/src
