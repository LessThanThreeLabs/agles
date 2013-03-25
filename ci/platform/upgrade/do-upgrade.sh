#!/bin/bash
sudo true
cd /tmp
wget https://getkoality.com/versions/newest
tar xf newest
cd newest/ci/platform
sudo pip uninstall koality
sudo python setup.py install
cd ../web/back
./compile.sh
cd front
timeout 3 ./continuousCompile.sh
sudo supervisorctl restart all

