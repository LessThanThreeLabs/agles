#!/bin/bash

if [ "$(dirname $0)" != "." ]; then
	echo 'You must run this script from its directory'
else
	./compile.sh
	front/compile.sh
	node js/index.js
fi
