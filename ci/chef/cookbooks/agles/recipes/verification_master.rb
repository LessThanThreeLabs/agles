#
# Cookbook Name:: agles
# Recipe:: verification_master
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

execute "Stop verification master" do
	command "killall -9 start_verification_master.py"
	ignore_failure true
end

execute "Start verification master" do
	command "#{node[:agles][:source_path][:internal]}/ci/platform/bin/start_verification_master.py &"
	user node[:agles][:user]
end
