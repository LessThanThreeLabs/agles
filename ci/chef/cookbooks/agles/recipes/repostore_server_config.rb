#
# Cookbook Name:: agles
# Recipe:: verification_server
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

git "/tmp/openssh-for-git" do
	repository "git://github.com/LessThanThreeLabs/openssh-for-git.git"
	reference "master"
	action :sync
end

remote_file "/tmp/openssh-6.0p1.tar.gz" do
	source "http://openbsd.mirrors.pair.com/OpenSSH/portable/openssh-6.0p1.tar.gz"
	mode "0644"
end

script "patch_install_openssh" do
	interpreter "bash"
	user "root"
	cwd "/tmp"
	code <<-EOH
		tar -xf /tmp/openssh-6.0p1.tar.gz
		cd openssh-6.0p1
		patch -p1 < /tmp/openssh-for-git/openssh-6.0p1-authorized-keys-script.diff
		./configure
		make -j 4
		make install
	EOH
end

script "setup_openssh_for_git" do
	interpreter "bash"
	user "root"
	cwd "/usr/local/etc"
	code <<-EOH
		# Check for AuthorizedKeysScript settings and add it if it doesn't exist
		grep "AuthorizedKeysScript" sshd_config
		if [ $? -ne 0 ]
			then chmod +x #{node[:agles][:source_path][:authorized_keys_script]}
			mv sshd_config sshd_config.bu
			sed '/AuthorizedKeysFile/d' sshd_config.bu > sshd_config

			# Setting the authorized_keys file to something that can't exist so it uses the script
			echo "AuthorizedKeysScript #{node[:agles][:source_path][:authorized_keys_script]}" >> sshd_config
			echo "AuthorizedKeysFile /dev/null/authorized_keys" >> sshd_config
		fi
	EOH
end

execute "install_agles" do
	cwd "#{node[:agles][:source_path][:platform]}"
	user "root"
	command "python setup.py install"
end

git "/tmp/dulwich-lt3" do
	repository "git://github.com/LessThanThreeLabs/dulwich.git"
	reference "master"
	action :sync
end

script "install_dulwich_remove_gitbinaries" do
	interpreter "bash"
	user "root"
	cwd "/tmp/dulwich-lt3"
	code <<-EOH
		python setup.py install
		cp bin/* /usr/bin
		mkdir -p /usr/bin/gitbin
		mv /usr/bin/git-* /usr/bin/gitbin
		exit 0
	EOH
end

link "/usr/bin/git-receive-pack" do
	to "/usr/bin/dul-receive-pack"
end

link "/usr/bin/git-upload-pack" do
	to "/usr/bin/dul-upload-pack"
end
