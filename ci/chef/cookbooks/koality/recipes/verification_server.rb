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

node[:koality][:verification][:server_count][:cloud].to_i.times do |server_num|
	server_path = "/verification/server/cloud/#{server_num}"
	rvm_shell "Start cloud verification server #{server_num}}" do
		user "verification"
		code <<-EOH
			mkdir -p #{server_path}
			cd #{server_path}
			#{node[:koality][:source_path][:internal]}/ci/platform/bin/start_verification_server.py -v #{server_path} -c >> #{server_path}/server.log 2>&1 &
			EOH
	end
end

node[:koality][:verification][:server_count][:local].to_i.times do |server_num|
	server_path = "/verification/server/local/#{server_num}"
	rvm_shell "Start local verification server #{server_num}}" do
		user "verification"
		code <<-EOH
			mkdir -p #{server_path}
			cd #{server_path}
			vagrant init precise64_verification
			if [ "`vagrant status | grep default | sed -e 's/default\\s\\+\\(.*\\)/\\1/'`" == 'running' ]
				then #{node[:koality][:source_path][:internal]}/ci/platform/bin/start_verification_server.py -v #{server_path} -f >> #{server_path}/server.log 2>&1 &
			else
				vagrant destroy -f
				#{node[:koality][:source_path][:internal]}/ci/platform/bin/start_verification_server.py -v #{server_path} >> #{server_path}/server.log 2>&1 &
				sleep 60  # deal with it
			fi
			EOH
	end
end
