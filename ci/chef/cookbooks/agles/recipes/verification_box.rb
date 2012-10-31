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
