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
	sudo su lt3 -c "$0 setup"
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
	wget http://www.rabbitmq.com/releases/rabbitmq-server/v2.8.7/rabbitmq-server_2.8.7-1_all.deb
	sudo dpkg -i rabbitmq-server_2.8.7-1_all.deb
	rm rabbitmq-server_2.8.7-1_all.deb
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

	sudo pip install pyyaml eventlet
}

function setup_ruby () {
	which rvm > /dev/null
	if [ $? -ne "0" ]; then
		curl -L https://get.rvm.io | bash -s head --ruby
	fi
}

function setup_nodejs () {
	makedir ~/nvm
	wget -P ~/nvm https://raw.github.com/creationix/nvm/master/nvm.sh
}

function provision () {
	read -p "Github username: " username
	read -s -p "Github password: " password
	git clone https://"$username":"$password"@github.com/Randominator/agles.git ~/source
	pushd ~/source/ci/platform
	sudo python setup.py install
	popd
	python -u -c "from provisioner.provisioner import Provisioner; Provisioner().provision(global_install=True)"
}

function main_setup () {
	check_sudo

	keygen

	# Install dependencies
	sudo apt-get install -y python-pip make postgresql mysql-server python-software-properties git
	setup_rabbitmq
	setup_redis
	setup_postgres

	setup_python
	setup_ruby
	setup_nodejs

	provision
}

function host_setup () {
	# Java
	if [ ! -d "/usr/lib/jvm/java-6-sun" ]; then
		mkdir /tmp/src
        cd /tmp/src
        git clone https://github.com/flexiondotorg/oab-java6.git
        cd /tmp/src/oab-java6
        sudo ./oab-java.sh
        sudo add-apt-repository ppa:flexiondotorg/java
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
		echo "chef chef/chef_server_url string" | sudo debconf-set-selections && sudo apt-get install chef -y
	fi

	mkdir ~/code
	mv ~/source ~/code/agles
	deactivate
	rvm use system
	sudo chef-solo -c ~/code/agles/ci/scripts/server_setup/solo.rb -j ~/code/agles/ci/scripts/server_setup/staging.json
}

case "$1" in
	setup )
		main_setup ;;
	host )
		host_setup ;;
	* )
		bootstrap ;;
esac
