#
# Cookbook Name:: agles
# Recipe:: verification_box
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#
python_pip "pylint" do
	if node[:agles][:languages][:python] and node[:agles][:languages][:virtualenv]
		virtualenv node[:agles][:languages][:python][:virtualenv]
	end
	action :install
end

postgresql_database_user node[:agles][:user] do
	password ""
	connection({:username => "postgres", :password => ""})
	action :create
end

file "/home/#{node[:agles][:user]}/.validator.sh" do
	user node[:agles][:user]
	mode "0755"
	content <<-EOH
		#!/bin/bash
		for command in "$@"
			do echo \\$$command
			sudo $command
			r=$?
			if [ $r -ne 0 ]
				then echo "$command failed with return code: $r"
				exit $r
			fi
		done
		EOH
	action :create
end
