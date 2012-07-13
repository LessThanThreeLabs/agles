#!/bin/bash
if [ -d 'js' ]; then
	node js/index.js
else
	echo 'You must first compile coffeescript into javascript by running compile.sh'
fi