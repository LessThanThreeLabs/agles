#!/bin/bash

front/compile.sh
back/compile.sh

cd back
npm install
./runServer.sh
