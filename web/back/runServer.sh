#!/bin/bash

if [ "$(dirname $0)" != "." ]; then
	echo 'You must run this script from its directory'
elif [ -d 'js' ]; then
	node js/index.js
else
	echo 'You must first compile coffeescript into javascript by running compile.sh'
fi