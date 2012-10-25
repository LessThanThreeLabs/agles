#!/bin/bash

if [ "$(dirname $0)" != "." ]; then
	echo 'You must run this script from its directory'
elif [ -d 'js' ]; then
	mkdir -p logs/redis
	node --harmony js/index.js &
	redis-server sessionStoreRedis.conf &
	redis-server createAccountRedis.conf
else
	echo 'You must first compile coffeescript into javascript by running compile.sh'
fi
