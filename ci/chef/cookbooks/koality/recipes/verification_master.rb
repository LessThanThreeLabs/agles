#
# Cookbook Name:: koality
# Recipe:: verification_master
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#
include_recipe "koality::verification_user"

execute "Stop verification master" do
	command "killall -9 start_verification_master.py"
	returns [0, 1]
end

directory "/verification/master" do
	user "verification"
end

execute "Start verification master" do
	cwd "/verification/master"
	environment({"HOME" => "/home/verification"})
	command "#{node[:koality][:source_path][:internal]}/ci/platform/bin/start_verification_master.py >> /verification/master/master.log 2>&1 &"
	user "verification"
end
