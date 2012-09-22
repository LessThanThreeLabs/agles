#!/bin/bash
# Don't bother if already installed
[ -f "/usr/local/bin/node" ] && exit 0
# Fetch and unarchive package
wget http://nodejs.org/dist/v0.6.11/node-v0.6.11.tar.gz
tar xzf node-v0.6.11.tar.gz
rm node-v0.6.11.tar.gz
cd node-v0.6.11
# Do installation
./configure
make
sudo make install
cd ..
rm -rf node-0.6.11
