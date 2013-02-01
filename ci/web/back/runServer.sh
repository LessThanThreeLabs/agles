#!/bin/bash

if [ "$(dirname $0)" != "." ]; then
	echo 'You must run this script from its directory'
elif [ -d 'js' ]; then
	./compile.sh
	cd front; ./compile.sh; cd ..

	mkdir -p logs/redis
	redis-server conf/redis/sessionStoreRedis.conf &
	redis-server conf/redis/createAccountRedis.conf &
	node --harmony js/index.js --httpPort 9001 --httpsPort 10443
else
	echo 'You must first compile coffeescript into javascript by running compile.sh'
fi
