#
# Cookbook Name:: koality
# Recipe:: verification_server
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute

include_recipe "koality::setuppy_install"
include_recipe "koality::verification_user"


supervisor_service "verification_server" do
	action [:stop]
end

directory "/verification/server" do
	user "verification"
end

supervisor_service "verification_server" do
	action [:enable, :start]
	environment "HOME" => "/home/verification"
	directory "/verification/server"
	command "/etc/koality/python #{node[:koality][:source_path][:internal]}/ci/platform/bin/start_verification_server.py --type #{node[:koality][:verification][:server_type].to_s} --cleanup"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/verification_server_stdout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/verification_server_stderr.log"
	user "verification"
	priority 1
end

supervisor_service "ec2_snapshotter" do
	action [:enable, :start]
	environment "HOME" => "/home/verification"
	directory "/verification/snapshotter"
	command "/etc/koality/python #{node[:koality][:source_path][:internal]}/ci/platform/bin/ec2_snapshotter.py --daemon"
	stdout_logfile "#{node[:koality][:supervisor][:logdir]}/ec2_snapshotter_stdout.log"
	stderr_logfile "#{node[:koality][:supervisor][:logdir]}/ec2_snapshotter_stderr.log"
	user "verification"
	priority 1
end
