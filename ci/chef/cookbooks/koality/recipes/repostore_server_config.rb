#
# Cookbook Name:: koality
# Recipe:: repostore_server_config
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

if not File.exists? '/usr/local/bin/ssh'
	git "/tmp/openssh-for-git" do
		repository "git://github.com/LessThanThreeLabs/openssh-for-git.git"
		reference "master"
		action :sync
	end

	remote_file "/tmp/openssh-6.0p1.tar.gz" do
		source "http://openbsd.mirrors.pair.com/OpenSSH/portable/openssh-6.0p1.tar.gz"
		mode "0644"
	end

	bash "patch_install_openssh" do
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

	bash "setup_openssh_for_git" do
		user "root"
		cwd "/usr/local/etc"
		code <<-EOH
			# Check for AuthorizedKeysScript settings and add it if it doesn't exist
			grep "AuthorizedKeysScript" sshd_config
			if [ $? -ne 0 ]
				then chmod +x #{node[:koality][:source_path][:authorized_keys_script]}
				mv sshd_config sshd_config.bu
				sed '/AuthorizedKeysFile/d' sshd_config.bu > sshd_config

				# Setting the authorized_keys file to something that can't exist so it uses the script
				echo "AuthorizedKeysScript #{node[:koality][:source_path][:authorized_keys_script]}" >> sshd_config
				echo "AuthorizedKeysFile /dev/null/authorized_keys" >> sshd_config
			fi
		EOH
	end

	if false  # dulwich
		git "/tmp/dulwich-lt3" do
			repository "git://github.com/LessThanThreeLabs/dulwich.git"
			reference "master"
			action :sync
		end

		bash "install_dulwich_remove_gitbinaries" do
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
	else  # jgit
		git "/tmp/jgit-lt3" do
			repository "git://github.com/LessThanThreeLabs/jgit.git"
			reference "master"
			action :sync
		end

		bash "install_jgit_remove_gitbinaries" do
			cwd "/tmp/jgit-lt3"
			code <<-EOH
				mvn install
				cp org.eclipse.jgit.pgm/target/jgit /usr/bin/
				mkdir -p /usr/bin/gitbin
				mv /usr/bin/git-* /usr/bin/gitbin
				exit 0
			EOH
		end

		file "/usr/bin/git-receive-pack" do
			mode '0755'
			content <<-EOH
				#!/bin/bash
				jgit receive-pack $*
			EOH
		end

		file "/usr/bin/git-upload-pack" do
			mode '0755'
			content <<-EOH
				#!/bin/bash
				jgit upload-pack $*
			EOH
		end

		link "/usr/bin/store-pending-and-trigger-build" do
			to "#{node[:koality][:source_path][:platform]}/bin/store_pending_and_trigger_build.py"
		end

		link "/usr/bin/verify-repository-permissions" do
			to "#{node[:koality][:source_path][:platform]}/bin/verify_repository_permissions.py"
		end
	end

end

bash "setup_ssh_pushing_to_github" do
	user "root"
	cwd "/usr/local/etc/"
	code <<-EOH
		grep "github.com" ssh_config
		if [ $? -ne 0 ]
			then echo "\nHost *github.com" >> ssh_config
			echo "\tStrictHostKeyChecking no" >> ssh_config
			echo "\tUserKnownHostsFile /dev/null" >> ssh_config
		fi
	EOH
end

execute "install_agles" do
	cwd node[:koality][:source_path][:platform]
	user "root"
	command "python setup.py install"
end

bash "Move standard ssh daemon" do
	user "root"
	code <<-EOH
		service ssh stop
		/usr/sbin/sshd -p 2222
		echo MAKE SURE THE SSH DAEMON HAS STARTED SUCCESSFULLY BEFORE LOGGING OUT
	EOH
end

bash "Start modified ssh daemon" do
	user "root"
	code <<-EOH
		/usr/local/sbin/sshd -f /usr/local/etc/sshd_config
	EOH
end
