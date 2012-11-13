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
	ignore_failure true
end

execute "Start verification server" do
	command "#{node[:agles][:source_path][:internal]}/ci/platform/bin/start_verification_server.py &"
	user node[:agles][:user]
end
