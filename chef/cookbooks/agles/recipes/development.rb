#
# Cookbook Name:: agles
# Recipe:: development_machine
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

require 'yaml'

config = YAML::load(File.read("general/dev_config.yml"))

packages = config["packages"]

for packages["system"].each do |p|
	package p do
		action :install
	end
end

# install node.js
script "install_node" do
	code <<-EOH
	wget http://nodejs.org/dist/v0.6.11/node-v0.6.11.tar.gz
	tar xzf node-v0.6.11.tar.gz
	cd node-v0.6.11
	./configure
	make
	sudo make install
	EOH
end

for packages["pip"].each do |p|
	python_pip p do
		action :install
	end
end

for packages["npm"].each do |p|
	execute "npm install -g #{p}"
end

databases = config["databases"]

for databases["postgres"].each do |db|
	postgresql_database db["name"] do
		connection ({:host => db["host"], :port => db["port"], :username => db["username"]})
		action :create
	end
end

for scripts.each do |s|
	execute s["script"] do
		if script["background"]
			command "#{s["script"]} &"
		end
		if not s["directory"].nil?
			cwd s["directory"]
		end
		action :create
	end
end
