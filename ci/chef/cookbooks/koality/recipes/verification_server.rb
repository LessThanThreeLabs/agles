#
# Cookbook Name:: koality
# Recipe:: verification_server
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#
include_recipe "koality::verification_user"

execute "Stop verification servers" do
	command "killall -9 start_verification_server.py"
	returns [0, 1]
end

node[:koality][:verification][:server_count].to_i.times do |server_num|
	vagrant_path = "/verification/server/#{server_num}"
	rvm_shell "Start verification server #{server_num}}" do
		user "verification"
		code <<-EOH
			mkdir -p #{vagrant_path}
			cd #{vagrant_path}
			vagrant init precise64_verification
			if [ "`vagrant status | grep default | sed -e 's/default\\s\\+\\(.*\\)/\\1/'`" == 'running' ]
				then #{node[:koality][:source_path][:internal]}/ci/platform/bin/start_verification_server.py -v #{vagrant_path} -f >> #{vagrant_path}/server.log 2>&1 &
			else
				vagrant destroy -f
				#{node[:koality][:source_path][:internal]}/ci/platform/bin/start_verification_server.py -v #{vagrant_path} >> #{vagrant_path}/server.log 2>&1 &
				sleep 60  # deal with it
			fi
			EOH
	end
end
