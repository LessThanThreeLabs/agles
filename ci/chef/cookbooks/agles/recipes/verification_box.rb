#
# Cookbook Name:: agles
# Recipe:: verification_box
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#
postgresql_database_user node[:agles][:user] do
	password ""
	connection({:username => "postgres", :password => ""})
	action :create
end

directory "/home/#{node[:agles][:user]}/scripts" do
	owner node[:agles][:user]
end

directory "/home/#{node[:agles][:user]}/scripts/build" do
	owner node[:agles][:user]
end

directory "/home/#{node[:agles][:user]}/scripts/test" do
	owner node[:agles][:user]
end

directory "/home/#{node[:agles][:user]}/scripts/language" do
	owner node[:agles][:user]
end

#validator.sh, currently unused
cookbook_file "/home/#{node[:agles][:user]}/scripts/validator.sh" do
	owner node[:agles][:user]
	mode "0755"
end

#setup.sh, to be sourced before running any build/test commands
template "/home/#{node[:agles][:user]}/scripts/setup.sh" do
	source "setup.erb"
	owner node[:agles][:user]
	mode "0755"
	variables(
		:user => node[:agles][:user]
	)
end
