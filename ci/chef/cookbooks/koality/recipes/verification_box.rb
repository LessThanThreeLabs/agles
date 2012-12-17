#
# Cookbook Name:: koality
# Recipe:: verification_box
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#
postgresql_database_user node[:koality][:user] do
	password ""
	connection({:username => "postgres", :password => ""})
	action :create
end

directory "/home/#{node[:koality][:user]}/.ssh" do
	owner node[:koality][:user]
end

execute "ssh-keygen -t rsa -N \"\" -f /home/#{node[:koality][:user]}/.ssh/id_rsa" do
	user node[:koality][:user]
	not_if {File.exists?("/home/#{node[:koality][:user]}/.ssh/id_rsa")}
end

directory "/home/#{node[:koality][:user]}/scripts" do
	owner node[:koality][:user]
end

directory "/home/#{node[:koality][:user]}/scripts/compile" do
	owner node[:koality][:user]
end

directory "/home/#{node[:koality][:user]}/scripts/test" do
	owner node[:koality][:user]
end

directory "/home/#{node[:koality][:user]}/scripts/language" do
	owner node[:koality][:user]
end

#validator.sh, currently unused
cookbook_file "/home/#{node[:koality][:user]}/scripts/validator.sh" do
	owner node[:koality][:user]
	mode "0755"
end

#setup.sh, to be sourced before running any compile/test commands
template "/home/#{node[:koality][:user]}/scripts/setup.sh" do
	source "setup.erb"
	owner node[:koality][:user]
	mode "0755"
	variables(
		:user => node[:koality][:user]
	)
end
