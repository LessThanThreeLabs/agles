#
# Cookbook Name:: koality
# Recipe:: verification_server
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute

include_recipe "koality::setuppy_install"
include_recipe "koality::verification_user"

execute "Stop verification servers" do
	command "killall -9 start_verification_server.py"
	returns [0, 1]
end

node[:koality][:verification][:server_count].to_i.times do |server_num|
	server_path = "/verification/server/#{server_num}"
	bash "Start cloud verification server #{server_num}}" do
		user "verification"
		environment({"HOME" => "/home/verification"})
		code <<-EOH
			mkdir -p #{server_path}
			cd #{server_path}
			source /etc/koality/koalityrc
			python #{node[:koality][:source_path][:internal]}/ci/platform/bin/start_verification_server.py -v #{server_path} -c >> #{server_path}/server.log 2>&1 &
			EOH
	end
end
