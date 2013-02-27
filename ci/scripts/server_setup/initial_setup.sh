#!/bin/bash

function check_sudo () {
	sudo true
	if [ $? -ne "0" ]; then
		echo "Failed to get root permissions"
		exit 1
	fi
}

function add_user () {
	cat /etc/passwd | grep $1 > /dev/null
	if [ $? -ne "0" ]; then
		echo "Creating user $1"
		read -s -p "Enter password for user $1: " password
		sudo adduser "$1" --home "/home/$1" --shell /bin/bash --disabled-password --gecos ""
		echo -e "$password\n$password" | sudo passwd "$1"
		echo "$1 ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers >/dev/null
	fi
}

function bootstrap () {
	check_sudo
	add_user lt3
	this_script=$(pwd)/$0
	sudo su lt3 -c "cd; $this_script _$1_setup"
}

function makedir () {
	if [ ! -d $1 ]; then
		mkdir -p $1
	fi
}

function keygen () {
	if [ ! -f ~/.ssh/id_rsa ]; then
		ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
	fi
}

function setup_rabbitmq () {
	sudo apt-get install -y rabbitmq-server
	wget http://www.rabbitmq.com/releases/rabbitmq-server/v2.8.7/rabbitmq-server_2.8.7-1_all.deb
	sudo dpkg -i rabbitmq-server_2.8.7-1_all.deb
	rm rabbitmq-server_2.8.7-1_all.deb
	sudo mkdir /etc/rabbitmq/rabbitmq.conf.d
	sudo rabbitmq-plugins enable rabbitmq_management
	sudo service rabbitmq-server restart
	wget --http-user=guest --http-password=guest localhost:55672/cli/rabbitmqadmin
	chmod +x rabbitmqadmin
	sudo mv rabbitmqadmin /usr/local/bin/rabbitmqadmin
}

function setup_redis () {
	wget http://redis.googlecode.com/files/redis-2.6.10.tar.gz
	tar xzf redis-2.6.10.tar.gz
	pushd redis-2.6.10
	make
	sudo make install
	popd
	rm -rf redis-2.6.10.tar.gz redis-2.6.10
}

function setup_postgres () {
	# Trust postgresql logins
	sudo sed -i.bak -r 's/^(\w+(\s+\S+){2,3}\s+)\w+$/\1trust/g' /etc/postgresql/9.1/main/pg_hba.conf
	# Turn off fsync on postgresql
	sudo sed -i.bak -r 's/^.*fsync .*$/fsync off/g' /etc/postgresql/9.1/main/postgresql.conf
	sudo service postgresql restart
}

function setup_python () {
	makedir ~/virtualenvs
	sudo add-apt-repository http://ppa.launchpad.net/fkrull/deadsnakes/ubuntu
	sudo apt-get update
	sudo pip install virtualenv
	for p in 2.5 2.6 2.7 3.2 3.3; do
		sudo apt-get install -y "python$p-dev"
		virtualenv "$HOME/virtualenvs/$p" -p "python$p"
	done
}

function setup_ruby () {
	which rvm > /dev/null
	if [ $? -ne "0" ]; then
		curl -L https://get.rvm.io | bash -s stable
		source .bash_profile
	fi
	rvm install 1.9.3
	rvm --default use 1.9.3
	cat ~/.bash_profile | grep "export rvmsudo_secure_path=1" > /dev/null
	if [ $? -ne "0" ]; then
		echo "export rvmsudo_secure_path=1" >> ~/.bash_profile
	fi
}

function setup_nodejs () {
	makedir ~/nvm
	wget -P ~/nvm https://raw.github.com/creationix/nvm/master/nvm.sh
}

function clone () {
	if [ -z $GITHUB_USERNAME ]; then
		read -p "Github username: " GITHUB_USERNAME
	fi
	if [ -z $GITHUB_PASSWORD ]; then
		read -s -p "Github password: " GITHUB_PASSWORD
	fi
	git clone https://"$GITHUB_USERNAME":"$GITHUB_PASSWORD"@github.com/Randominator/agles.git source
}

function provision () {
	clone
	pushd ~/source/ci/platform
	sudo python setup.py install
	popd
	python -u -c "from provisioner.provisioner import Provisioner; Provisioner(scripts=False, databases=False).provision(global_install=True)"
}

function setup_openstack () {
	git clone https://github.com/Randominator/openstackgeek.git
	pushd openstackgeek/essex
	sudo ./openstack.sh
	popd
}

function shared_setup () {
	# Install dependencies
	sudo apt-get install -y python-pip make postgresql python-software-properties git build-essential
	setup_rabbitmq
	setup_redis

	setup_ruby
	setup_nodejs

	sudo apt-get install -y python-dev
	sudo pip install pyyaml eventlet

	provision
}

function vm_setup () {
	check_sudo

	keygen

	shared_setup

	# mysql must be explicitly installed noninteractively
	sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
	setup_postgres

	setup_python

	rm -rf source
}

function host_setup () {
	check_sudo

	shared_setup

	mkdir ~/code
	mv ~/source ~/code/agles

	# Java
	if [ ! -d "/usr/lib/jvm/java-6-sun" ]; then
		mkdir /tmp/src
        cd /tmp/src
        git clone https://github.com/flexiondotorg/oab-java6.git
        cd /tmp/src/oab-java6
        sudo ./oab-java.sh
        sudo add-apt-repository -y ppa:flexiondotorg/java
        sudo apt-get update
        sudo apt-get install -y sun-java6-jdk maven
    fi

    #Chef
    if [ ! -f "/usr/bin/chef-solo" ]; then
	    echo "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main" | sudo tee /etc/apt/sources.list.d/opscode.list
	    sudo mkdir -p /etc/apt/trusted.gpg.d
		gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
		gpg --export packages@opscode.com | sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
		sudo apt-get update
		sudo apt-get install -y opscode-keyring
		echo "chef chef/chef_server_url string" | sudo debconf-set-selections && sudo apt-get install -y chef
	fi

	rvm use system

	setup_openstack

	psql -U postgres -c 'create user lt3'
	psql -U lt3 -c 'create database koality'
	python ~/code/agles/ci/platform/database/schema.py
	sudo chef-solo -c ~/code/agles/ci/scripts/server_setup/solo.rb -j ~/code/agles/ci/scripts/server_setup/staging.json
}

case "$1" in
	_vm_setup )
		vm_setup ;;
	_host_setup )
		host_setup ;;
	vm )
		bootstrap vm ;;
	host )
		bootstrap host ;;
	* )
		echo 'Must be run with either "vm" or "host" as the first argument'
		exit 1
esac
