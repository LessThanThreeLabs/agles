#
# Cookbook Name:: agles
# Recipe:: verification_server
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

execute "Stop verification server" do
	command "killall -9 start_verification_server.py"
	returns [0, 1]
end

node[:agles][:verification][:server_count].to_i.times do |server_num|
	rvm_shell "Start verification server" do
		code "#{node[:agles][:source_path][:internal]}/ci/platform/bin/start_verification_server.py -v /tmp/verification/#{server_num} &"
		user node[:agles][:user]
	end
	execute "sleep 20"  # This is horrible
end
