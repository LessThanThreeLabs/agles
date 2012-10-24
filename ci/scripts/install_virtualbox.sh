#!/bin/bash
# Don't bother if already installed
[ -f "/usr/bin/virtualbox" ] && exit 0
# Add deb/key to repo
echo "deb http://download.virtualbox.org/virtualbox/debian `lsb_release -cs` contrib non-free" >> /etc/apt/sources.list
wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -
# Update/install, including kernel modules (dkms)
apt-get update
apt-get install -y virtualbox-4.2
apt-get install -y dkms
# Download kernel source
apt-get install -y linux-headers-`uname -r`
# Configure kernel modules
/etc/init.d/vboxdrv setup
