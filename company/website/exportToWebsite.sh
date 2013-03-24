#!/bin/bash

rm -rf front/js/src
rm -rf front/css/src
rm -rf back/js
front/compile.sh
back/compile.sh
rm -rf back/node_modules
scp -r front web@166.78.156.186:front
scp -r back web@166.78.156.186:back
