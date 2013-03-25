#!/bin/bash
cd $(dirname $0)

cd ..
front/compile.sh
back/compile.sh

cd back
npm install

killall -v node
nohup ./runServer.sh &
