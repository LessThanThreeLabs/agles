#!/bin/bash
sudo true
cd ~/code/agles/ci/platform
git pull
sudo python setup.py clean
sudo python setup.py install
cd ~/code/agles/submodules/dulwich
git pull
sudo python setup.py install
cd ~/code/agles/ci/web/back
./compile.sh
cd ~/code/agles/ci/web/front
timeout 3 ./continuousCompile.sh
cd
sudo rabbitmqctl stop_app
sudo rabbitmqctl reset
sudo rabbitmqctl start_app
sudo chef-solo -c solo.rb -j staging.json
