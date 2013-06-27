#!/bin/bash

function platform_configure () {
	if [ $(which apt-get) ]; then
		PACKAGE_MANAGER='apt-get'
	elif [ $(which yum) ]; then
		PACKAGE_MANAGER='yum'
		sudo yum install -y wget
		wget http://mirrors.servercentral.net/fedora/epel/6/i386/epel-release-6-8.noarch.rpm
		sudo yum install -y epel-release-6-8.noarch.rpm
		rm epel-release-6-8.noarch.rpm
	else
		echo "Unsupported platform"
		exit 1
	fi
	sudo sed -i.bak -r 's/^(.*Defaults\s+always_set_home.*)$/# \1/g' /etc/sudoers
	if [ $USER == 'root' ]; then
		sed -i.bak -r 's/^(.*Defaults\s+requiretty.*)$/# \1/g' /etc/sudoers
	fi
}

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
		if [ $PACKAGE_MANAGER == 'apt-get' ]; then
			sudo adduser "$1" --home "/home/$1" --shell /bin/bash --disabled-password --gecos ""
		elif [ $PACKAGE_MANAGER == 'yum' ]; then
			sudo adduser "$1" --home "/home/$1" --shell /bin/bash
		fi
		echo -e "$password\n$password" | sudo passwd "$1"
		echo "$1 ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers >/dev/null
	fi
}

function bootstrap () {
	check_sudo
	platform_configure
	add_user lt3
	this_script=$(readlink -f $0)
	sudo -E su lt3 -c "cd; $this_script _$1_setup"
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

function setup_path () {
	cat ~/.bash_profile | grep "/usr/local/bin" > /dev/null
	if [ $? -ne "0" ]; then
		echo "PATH=/usr/local/bin:\$PATH" >> ~/.bash_profile
	fi

	cat ~/.bashrc | grep "/usr/local/bin" > /dev/null
	if [ $? -ne "0" ]; then
		echo "PATH=/usr/local/bin:\$PATH" >> ~/.bashrc
	fi

	source ~/.bashrc
}

function setup_rabbitmq () {
	if [ ! $(which rabbitmq-plugins) ]; then
		if [ $PACKAGE_MANAGER == 'apt-get' ]; then
			sudo $PACKAGE_MANAGER install -y rabbitmq-server
			wget http://www.rabbitmq.com/releases/rabbitmq-server/v3.1.2/rabbitmq-server_3.1.2-1_all.deb
			sudo dpkg -i rabbitmq-server_3.1.2-1_all.deb
			rm rabbitmq-server_3.1.2-1_all.deb
		elif [ $PACKAGE_MANAGER == 'yum' ]; then
			sudo yum install -y erlang
			wget http://www.rabbitmq.com/releases/rabbitmq-server/v3.1.2/rabbitmq-server-3.1.2-1.noarch.rpm
			sudo rpm -i rabbitmq-server-3.1.2-1.noarch.rpm
			rm rabbitmq-server-3.1.2-1.noarch.rpm
		fi
	fi
	sudo mkdir /etc/rabbitmq/rabbitmq.conf.d
	sudo rabbitmq-plugins enable rabbitmq_management
	sudo service rabbitmq-server restart
	wget --http-user=guest --http-password=guest localhost:55672/cli/rabbitmqadmin
	chmod +x rabbitmqadmin
	sudo mv rabbitmqadmin /usr/local/bin/rabbitmqadmin
}

function setup_redis () {
	if [ ! $(which redis-server) ]; then
		wget http://redis.googlecode.com/files/redis-2.6.10.tar.gz
		tar xzf redis-2.6.10.tar.gz
		pushd redis-2.6.10
		make
		sudo make install
		popd
		rm -rf redis-2.6.10.tar.gz redis-2.6.10
	fi
}

function setup_postgres () {
	if [ $PACKAGE_MANAGER == 'apt-get' ]; then
		postgresql_root=/etc/postgresql/9.1/main
		postgresql_service=postgresql
	elif [ $PACKAGE_MANAGER == 'yum' ]; then
		postgresql_root=/var/lib/pgsql/9.1/data
		postgresql_service=postgresql-9.1
		sudo service $postgresql_service initdb
	fi
	# Trust postgresql logins
	sudo sed -i.bak -r 's/^(\w+(\s+\S+){2,3}\s+)\w+$/\1trust/g' $postgresql_root/pg_hba.conf
	# Turn off fsync on postgresql
	sudo sed -i.bak -r 's/^.*fsync .*$/fsync off/g' $postgresql_root/postgresql.conf
	sudo service $postgresql_service restart
}

function setup_python () {
	makedir ~/virtualenvs
	if [ ! $(which pythonz) ]; then
		curl -kL https://raw.github.com/saghul/pythonz/master/pythonz-install | sudo bash
		source ~/.bashrc
		source /etc/profile
	fi
	for p in 2.5.6 2.6.8 2.7.5 3.2.5 3.3.2; do
		if [ ! -f "$PYTHONZ_ROOT/pythons/*$p*/python" ]; then
			sudo-pythonz install $p
			if [ ! $? ]; then
				sudo-pythonz install $p -f
			fi
		fi
		major_version=${p%.*}
		if [ ! -e "$HOME/virtualenvs/${major_version}" ]; then
			virtualenv "$HOME/virtualenvs/${major_version}" -p ${PYTHONZ_ROOT}/pythons/*${p}*/bin/python${major_version}
		fi
	done
}

function setup_ruby () {
	which rvm > /dev/null
	if [ $? -ne "0" ]; then
		curl -L https://get.rvm.io | bash -s stable
		source .bash_profile
	fi
	rvm get stable
	rvm install 1.9.3
	rvm --default use 1.9.3
	cat ~/.bash_profile | grep "export rvmsudo_secure_path=1" > /dev/null
	if [ $? -ne "0" ]; then
		echo "export rvmsudo_secure_path=1" >> ~/.bash_profile
	fi
	cat ~/.bashrc | grep "export rvmsudo_secure_path=1" > /dev/null
	if [ $? -ne "0" ]; then
		echo "export rvmsudo_secure_path=1" >> ~/.bashrc
	fi
}

function setup_nodejs () {
	makedir ~/nvm
	wget -P ~/nvm https://raw.github.com/creationix/nvm/master/nvm.sh
	cat ~/.bash_profile | grep "source ~/nvm/nvm.sh" > /dev/null
	if [ $? -ne "0" ]; then
		echo "source ~/nvm/nvm.sh" >> ~/.bash_profile
	fi
}

function setup_java () {
	if [ ! -d /usr/lib/jvm/java-6-sun ]; then
		wget --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F" http://download.oracle.com/otn-pub/java/jdk/6u45-b06/jdk-6u45-linux-x64.bin
		chmod u+x jdk-6u45-linux-x64.bin
		./jdk-6u45-linux-x64.bin
		rm jdk-6u45-linux-x64.bin
		mkdir -p /usr/lib/jvm
		mv jdk1.6.0_45 /usr/lib/jvm/java-6-sun
	fi
	if [ ! -d /usr/lib/jvm/java-1.5.0-sun ]; then
		wget --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F" http://download.oracle.com/otn-pub/java/jdk/1.5.0_22/jdk-1_5_0_22-linux-amd64.bin
		chmod u+x jdk-1_5_0_22-linux-amd64.bin
		sed -i.bak 's/more <<"EOF"/true <<"EOF"/g' jdk-1_5_0_22-linux-amd64.bin
		echo yes | ./jdk-1_5_0_22-linux-amd64.bin
		rm jdk-1_5_0_22-linux-amd64.bin*
		mkdir -p /usr/lib/jvm
		mv jdk1.5.0_22 /usr/lib/jvm/java-1.5.0-sun
	fi
}

function prompt_github_credentials () {
	if [ -f ~/.gh ]; then
		{ read gh_username; read gh_password; } < ~/.gh
		# Use environment variable or fall back on file
		GITHUB_USERNAME=$(([ $GITHUB_USERNAME ] && echo $GITHUB_USERNAME) || ([ $gh_username ] && echo $gh_username))
		GITHUB_PASSWORD=$(([ $GITHUB_PASSWORD ] && echo $GITHUB_PASSWORD) || ([ $gh_password ] && echo $gh_password))
	fi
	if [ -z $GITHUB_USERNAME ]; then
		read -p "Github username: " GITHUB_USERNAME
	fi
	if [ -z $GITHUB_PASSWORD ]; then
		read -s -p "Github password: " GITHUB_PASSWORD
	fi
	echo -e "$GITHUB_USERNAME\n$GITHUB_PASSWORD" > ~/.gh
}

function remove_github_credentials () {
	rm ~/.gh
}

function clone () {
	prompt_github_credentials
	git clone https://"$GITHUB_USERNAME":"$GITHUB_PASSWORD"@"$1" $2
	pushd $2
	git remote set-url origin https://"$1"
	popd
}

function vm_setup () {
	check_sudo

	platform_configure

	setup_path

	keygen

	prompt_github_credentials
	# Install dependencies
	sudo $PACKAGE_MANAGER update -y
	sudo $PACKAGE_MANAGER install -y python-pip make postgresql python-software-properties git build-essential curl libyaml-dev

	if [ $PACKAGE_MANAGER == 'yum' ]; then
		sudo $PACKAGE_MANAGER groupinstall -y "Development Tools"
		rpm -Uh http://yum.pgrpms.org/9.1/redhat/rhel-6-x86_64/pgdg-centos91-9.1-4.noarch.rpm
		sudo $PACKAGE_MANAGER install -y postgresql91-server bzip2-devel
		sudo ln -s /usr/bin/python-pip /usr/bin/pip
	fi

	setup_rabbitmq
	setup_redis

	setup_ruby
	setup_nodejs

	sudo $PACKAGE_MANAGER install -y python-dev python-devel
	sudo pip install virtualenv

	# mysql must be explicitly installed noninteractively
	sudo DEBIAN_FRONTEND=noninteractive $PACKAGE_MANAGER install -y mysql-server
	if [ $PACKAGE_MANAGER == 'yum' ]; then
		# auto-start mysql server daemon
		sudo /sbin/chkconfig --level 2345 mysqld on
		sudo service mysqld start
	fi

	setup_postgres

	setup_python

	setup_java

	# TODO: make this use our custom python
	source ~/virtualenvs/2.7/bin/activate

	clone github.com/LessThanThreeLabs/koality-streaming-executor.git koality-streaming-executor
	pushd koality-streaming-executor
	pip install -r requirements.txt
	python setup.py install
	popd
	rm -rf koality-streaming-executor

	clone github.com/LessThanThreeLabs/koality-provisioner.git koality-provisioner
	pushd koality-provisioner
	pip install -r requirements.txt
	python setup.py install
	sudo rm -f /usr/bin/koality-provision
	sudo ln -s $(which koality-provision) /usr/bin/koality-provision
	popd
	rm -rf koality-provisioner

	clone github.com/LessThanThreeLabs/exporter.git exporter
	pushd exporter
	pip install -r requirements.txt
	python setup.py install
	sudo rm -f /usr/bin/koality-export
	sudo ln -s $(which koality-export) /usr/bin/koality-export
	popd
	rm -rf exporter

	sudo mkdir -m 777 -p /koality

	remove_github_credentials
}

function build_vm_image () {
	read -p 'Please construct a VM image named "precise64_box_1", then press enter to continue this script'
}


case "$1" in
	_vm_setup )
		vm_setup ;;
	* )
		bootstrap vm ;;
esac
