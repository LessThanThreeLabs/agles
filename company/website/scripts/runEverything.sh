#!/bin/bash

cd ..
front/compile.sh
back/compile.sh

cd back
npm install

killall -v node
nohup ./runServer.sh &
