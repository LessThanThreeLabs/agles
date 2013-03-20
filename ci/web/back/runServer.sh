#!/bin/bash

if [ "$(dirname $0)" != "." ]; then
	echo 'You must run this script from its directory'
else
	./compile.sh
	front/compile.sh

	mkdir -p logs/redis
	redis-server conf/redis/sessionStoreRedis.conf &
	redis-server conf/redis/createAccountRedis.conf &
	redis-server conf/redis/createRepositoryRedis.conf &
	node --harmony js/index.js --httpsPort 10443
fi
