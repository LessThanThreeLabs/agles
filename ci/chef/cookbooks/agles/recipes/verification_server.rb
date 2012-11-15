#
# Cookbook Name:: agles
# Recipe:: verification_server
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

execute "Stop verification servers" do
	command "killall -9 start_verification_server.py"
	returns [0, 1]
end

node[:agles][:verification][:server_count].to_i.times do |server_num|
	rvm_shell "Start verification server #{server_num}}" do
		code <<-EOH
		cd /tmp/verification/#{server_num}
		vagrant destroy -f
		vagrant init precise64_verification
		vagrant up --no-provision
		vagrant ssh -c "sleep 2"
		vagrant sandbox on
		#{node[:agles][:source_path][:internal]}/ci/platform/bin/start_verification_server.py -v /tmp/verification/#{server_num} -f &
		EOH
		user node[:agles][:user]
	end
end
