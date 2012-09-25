#!/bin/bash
# Don't bother if already installed
[ -f "/usr/local/bin/node" ] && exit 0
# Fetch and unarchive package
wget http://nodejs.org/dist/v0.8.9/node-v0.8.9.tar.gz
tar xzf node-v0.8.9.tar.gz
rm node-v0.8.9.tar.gz
cd node-v0.8.9
# Do installation
./configure
make
make install
cd ..
rm -rf node-v0.8.9
