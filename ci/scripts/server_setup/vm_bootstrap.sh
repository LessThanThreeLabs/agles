#!/bin/bash

set -o nounset
set -o errexit

function platform_configure () {
	if [ $(which apt-get) ]; then
		# THIS STUFF IS VERY VERY DANGEROUS
		# PACKAGE_MANAGER='apt-get'
		# sudo locale-gen en_US.UTF-8
		# sudo update-locale LANG=en_US.UTF-8
		# sudo su -c "echo 127.0.0.1 localhost $(hostname) >> /etc/hosts"
		# if [ -f /sbin/initctl ]; then
		# 	sudo rm /sbin/initctl
		# fi
		# sudo dpkg-divert --local --rename --add /sbin/initctl
		# sudo ln -s /bin/true /sbin/initctl
		# END DANGEROUS STUFF
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
	sudo true || {
		echo "Failed to get root permissions"
		exit 1
	}
}

function add_user () {
	username=$1
	cat /etc/passwd | grep $username > /dev/null || {
		echo "Creating user $username"
		read -s -p "Enter password for user $username: " password
		if [ $PACKAGE_MANAGER == 'apt-get' ]; then
			sudo adduser "$username" --home "/home/$username" --shell /bin/bash --disabled-password --gecos ""
		elif [ $PACKAGE_MANAGER == 'yum' ]; then
			sudo adduser "$username" --home "/home/$username" --shell /bin/bash
		fi
		echo -e "$password\n$password" | sudo passwd "$username"
		echo "$username ALL=(ALL) NOPASSWD: ALL" > koality.sudo
		chmod 0440 koality.sudo
		sudo chown 0:0 koality.sudo
		sudo mv koality.sudo /etc/sudoers.d/koality-$username
	}
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
	set +o errexit
	cat ~/.bash_profile | grep "/usr/local/bin" > /dev/null || {
		echo "PATH=/usr/local/bin:\$PATH" >> ~/.bash_profile
	}

	cat ~/.bashrc | grep "/usr/local/bin" > /dev/null || {
		echo "PATH=/usr/local/bin:\$PATH" >> ~/.bashrc
	}
	set -o errexit

	set +o nounset
	source ~/.bashrc
	set -o nounset
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
	sudo mkdir -p /etc/rabbitmq/rabbitmq.conf.d
	sudo rabbitmq-plugins enable rabbitmq_management
	sudo service rabbitmq-server restart
	if [ ! $(which rabbitmqadmin) ]; then
		wget --http-user=guest --http-password=guest localhost:55672/cli/rabbitmqadmin
		chmod +x rabbitmqadmin
		sudo mv rabbitmqadmin /usr/local/bin/rabbitmqadmin
	fi
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
		set +o nounset
		source ~/.bashrc
		source /etc/profile
		set -o nounset
	fi
	for p in 2.6.8 2.7.5 3.2.5 3.3.2; do
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
	set +o nounset
	which rvm > /dev/null || {
		curl -L https://get.rvm.io | bash -s stable
		source .bash_profile
	}
	rvm get stable
	rvm install 1.9.3
	rvm --default use 1.9.3
	cat ~/.bash_profile | grep "export rvmsudo_secure_path=1" > /dev/null || {
		echo "export rvmsudo_secure_path=1" >> ~/.bash_profile
	}
	cat ~/.bashrc | grep "export rvmsudo_secure_path=1" > /dev/null || {
		echo "export rvmsudo_secure_path=1" >> ~/.bashrc
	}
	set -o nounset
}

function setup_nodejs () {
	if [ ! -f ~/nvm/nvm.sh ]; then
		makedir ~/nvm
		wget -P ~/nvm https://raw.github.com/creationix/nvm/master/nvm.sh
	fi
	cat ~/.bash_profile | grep "source ~/nvm/nvm.sh" > /dev/null || {
		echo "source ~/nvm/nvm.sh" >> ~/.bash_profile
	}
}

function setup_java () {
	if [ ! -d /usr/lib/jvm/java-6-sun ]; then
		wget --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F" --no-check-certificate -O jdk-6u45-linux-x64.bin http://download.oracle.com/otn-pub/java/jdk/6u45-b06/jdk-6u45-linux-x64.bin
		chmod u+x jdk-6u45-linux-x64.bin
		./jdk-6u45-linux-x64.bin
		rm jdk-6u45-linux-x64.bin
		sudo mkdir -p /usr/lib/jvm
		sudo mv jdk1.6.0_45 /usr/lib/jvm/java-6-sun
	fi
	if [ ! -d /usr/lib/jvm/java-1.5.0-sun ]; then
		wget --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F" --no-check-certificate -O jdk-1_5_0_22-linux-amd64.bin http://download.oracle.com/otn-pub/java/jdk/1.5.0_22/jdk-1_5_0_22-linux-amd64.bin
		chmod u+x jdk-1_5_0_22-linux-amd64.bin
		sed -i.bak 's/more <<"EOF"/true <<"EOF"/g' jdk-1_5_0_22-linux-amd64.bin
		echo yes | ./jdk-1_5_0_22-linux-amd64.bin
		rm jdk-1_5_0_22-linux-amd64.bin*
		sudo mkdir -p /usr/lib/jvm
		sudo mv jdk1.5.0_22 /usr/lib/jvm/java-1.5.0-sun
	fi
	if [ ! $(which sbt) ]; then
		if [ $PACKAGE_MANAGER == 'apt-get' ]; then
			wget http://scalasbt.artifactoryonline.com/scalasbt/sbt-native-packages/org/scala-sbt/sbt/0.12.4/sbt.deb
			sudo dpkg -i sbt.deb || sudo apt-get install -f -y
			rm sbt.deb
		elif [ $PACKAGE_MANAGER == 'yum' ]; then
			wget http://scalasbt.artifactoryonline.com/scalasbt/sbt-native-packages/org/scala-sbt/sbt/0.12.4/sbt.rpm
			sudo yum install -y sbt.rpm
			rm sbt.rpm
		fi
	fi
	if [ ! $(which mvn) ]; then
		if [ $PACKAGE_MANAGER == 'apt-get' ]; then
			sudo apt-get install -y maven
		elif [ $PACKAGE_MANAGER == 'yum' ]; then
			wget http://mirror.cogentco.com/pub/apache/maven/maven-3/3.0.5/binaries/apache-maven-3.0.5-bin.tar.gz
			tar xzf apache-maven-3.0.5-bin.tar.gz
			rm apache-maven-3.0.5-bin.tar.gz
			sudo mv apache-maven-3.0.5 /usr/local/maven
			cat > maven.sh <<-'EOF'
				export M2_HOME=/usr/local/maven
				export PATH=$M2_HOME/bin:$PATH
			EOF
			chmod 0644 maven.sh
			sudo chown root:root maven.sh
			sudo mv maven.sh /etc/profile.d/maven.sh
		fi
	fi
}

function prompt_github_credentials () {
	if [ -f ~/.gh ]; then
		{ read gh_username; read gh_password; } < ~/.gh
		# Use environment variable or fall back on file
		GITHUB_USERNAME=$(([ $GITHUB_USERNAME ] && echo $GITHUB_USERNAME) || ([ $gh_username ] && echo $gh_username))
		GITHUB_PASSWORD=$(([ $GITHUB_PASSWORD ] && echo $GITHUB_PASSWORD) || ([ $gh_password ] && echo $gh_password))
	fi
	if [ -z ${GITHUB_USERNAME:-} ]; then
		read -p "Github username: " GITHUB_USERNAME
	fi
	if [ -z ${GITHUB_PASSWORD:-} ]; then
		read -s -p "Github password: " GITHUB_PASSWORD
	fi
	echo -e "$GITHUB_USERNAME\n$GITHUB_PASSWORD" > ~/.gh
}

function remove_github_credentials () {
	rm ~/.gh
}

function clone () {
	prompt_github_credentials
	url=$1
	name=$2
	shift
	shift
	git clone https://"$GITHUB_USERNAME":"$GITHUB_PASSWORD"@"$url" $name $*
	pushd $name
	git remote set-url origin https://"$url"
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
	sudo $PACKAGE_MANAGER install -y python-pip make postgresql python-software-properties git mercurial build-essential curl libyaml-dev

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

	if [ $PACKAGE_MANAGER == 'apt-get' ]; then
		sudo apt-get install -y python-dev
	elif [ $PACKAGE_MANAGER == 'yum' ]; then
		sudo yum install -y python-devel
	fi
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
	set +o nounset
	source ~/virtualenvs/2.7/bin/activate
	set -o nounset

	clone github.com/LessThanThreeLabs/koality-streaming-executor.git koality-streaming-executor -b 0.3
	pushd koality-streaming-executor
	pip install -r requirements.txt
	python setup.py install
	popd
	rm -rf koality-streaming-executor

	clone github.com/LessThanThreeLabs/koality-provisioner.git koality-provisioner -b 0.3
	pushd koality-provisioner
	pip install -r requirements.txt
	python setup.py install
	sudo rm -f /usr/local/bin/koality-provision
	sudo ln -s $(which koality-provision) /usr/local/bin/koality-provision
	popd
	rm -rf koality-provisioner

	clone github.com/LessThanThreeLabs/libcloud.git libcloud
	pushd libcloud
	python setup.py install
	popd
	rm -rf libcloud

	clone github.com/LessThanThreeLabs/exporter.git exporter -b 0.3
	pushd exporter
	pip install -r requirements.txt
	python setup.py install
	sudo rm -f /usr/local/bin/koality-export
	sudo ln -s $(which koality-export) /usr/local/bin/koality-export
	popd
	rm -rf exporter

	sudo mkdir -m 777 -p /koality

	remove_github_credentials
}

function build_vm_image () {
	read -p 'Please construct a VM image named "precise64_box_1", then press enter to continue this script'
}

ARG1=${1:-}
case "$ARG1" in
	_vm_setup )
		vm_setup ;;
	* )
		bootstrap vm ;;
esac
