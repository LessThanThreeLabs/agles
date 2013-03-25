#!/bin/bash
sudo true
cd /tmp
wget https://koalitycode.com/versions/newest.tgz
tar xf newest.tgz
root_dir=$(cd newest && pwd)
cd $root_dir/ci/platform

sudo pip uninstall koality
python setup.py clean
python setup.py build
sudo python setup.py install

../web/back/compile.sh
../web/front/compile.sh
sudo supervisorctl restart all

rm -rf $root_dir
