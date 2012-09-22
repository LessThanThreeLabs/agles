#
# Cookbook Name:: agles
# Recipe:: verification_server
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

pip_packages = ["pika", "msgpack", "pyyaml", "zerorpc", "beautifulsoup4"]

pip_packages.each do |p|
	python_pip p do
		action :install
	end
end

execute "python /vagrant/platform/bin/start_verification_server.py &"
