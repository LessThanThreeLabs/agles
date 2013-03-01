#
# Cookbook Name:: koality
# Recipe:: verification_master
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#
include_recipe "koality::setuppy_install"
include_recipe "koality::verification_user"


supervisor_service "verification_master" do
	action [:stop]
end

directory "/verification/master" do
	user "verification"
end

supervisor_service "verification_master" do
	action [:enable, :start]
	environment({"HOME" => "/home/verification"})
	directory "/verification/master"
	command "/etc/koality/python #{node[:koality][:source_path][:internal]}/ci/platform/bin/start_verification_master.py"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/verification_master_stdout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/verification_master_stderr.log"
	user "verification"
	priority 1
end
