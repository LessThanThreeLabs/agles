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
	bash "Start verification server #{server_num}}" do
		user "verification"
		code <<-EOH
			mkdir -p #{vagrant_path}
			cd #{vagrant_path}
			vagrant init precise64_verification
			while [ "`vagrant status | grep default | sed -e 's/default\\s\\+\\(.*\\)/\\1/'`" != 'running' ]
				do vagrant destroy -f
				vagrant up --no-provision
			done
			vagrant sandbox on
			#{node[:koality][:source_path][:internal]}/ci/platform/bin/start_verification_server.py -v #{vagrant_path} -f >> #{vagrant_path}/server.log 2>&1 &
			EOH
	end
end
