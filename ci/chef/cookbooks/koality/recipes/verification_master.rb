#
# Cookbook Name:: koality
# Recipe:: verification_master
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

execute "Stop verification master" do
	command "killall -9 start_verification_master.py"
	returns [0, 1]
end

execute "Start verification master" do
	command "#{node[:koality][:source_path][:internal]}/ci/platform/bin/start_verification_master.py >> /tmp/verification/master.log 2>&1 &"
	user node[:koality][:user]
end
