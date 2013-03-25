#!/bin/bash
cd $(dirname $0)

cd ..
rm -rf front/js/src
rm -rf front/css/src
rm -rf back/js
rm -rf back/node_modules

front/compile.sh
back/compile.sh

scp -r front web@166.78.156.186:front
scp -r back web@166.78.156.186:back
