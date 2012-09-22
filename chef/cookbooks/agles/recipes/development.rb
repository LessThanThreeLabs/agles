#
# Cookbook Name:: agles
# Recipe:: development_machine
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

require 'yaml'

config = YAML::load(File.read("/vagrant/general/dev_config.yml"))

packages = config["packages"]

packages["system"].each do |p|
	package p do
		action :install
	end
end

# install node.js
bash "install_node" do
	code <<-EOH
	wget http://nodejs.org/dist/v0.6.11/node-v0.6.11.tar.gz
	tar xzf node-v0.6.11.tar.gz
	cd node-v0.6.11
	./configure
	make
	sudo make install
	EOH
	not_if {File.exists?("/usr/local/bin/node")}
end

packages["pip"].each do |p|
	python_pip p do
		action :install
	end
end

packages["gem"].each do |p|
	gem_package p do
		action :install
	end
end

packages["npm"].each do |p|
	execute "npm install -g #{p}"
end

databases = config["databases"]

databases["postgres"].each do |db|
	postgresql_database db["name"] do
		c = db["connection-info"]
		connection ({:host => c["host"], :port => c["port"], :username => c["username"], :password => node['postgresql']['password']['postgres']})
		action :create
	end
end

scripts = config["scripts"]

scripts.each do |s|
	execute s["script"] do
		if s["background"]
			command "#{s["script"]} &"
		end
		if not s["directory"].nil?
			cwd s["directory"]
		end
		action :run
	end
end
