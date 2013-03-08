#
# Cookbook Name:: koality
# Recipe:: verification_server
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute

include_recipe "koality::setuppy_install"
include_recipe "koality::verification_user"

bash "Stop verification servers" do
	code "pgrep -f start_verification_server.py | while read p; do kill -9 $p; done"
end

node[:koality][:verification][:server_count].to_i.times do |server_num|
	server_path = "/verification/server/#{server_num}"
	bash "Start #{node[:koality][:verification][:server_type].to_s} verification server #{server_num}}" do
		user "verification"
		environment({"HOME" => "/home/verification"})
		code <<-EOH
			mkdir -p #{server_path}
			cd #{server_path}
			/etc/koality/python #{node[:koality][:source_path][:internal]}/ci/platform/bin/start_verification_server.py -v #{server_path} --#{node[:koality][:verification][:server_type].to_s} >> #{server_path}/server.log 2>&1 &
			EOH
	end
end
