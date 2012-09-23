#
# Cookbook Name:: agles
# Recipe:: configure
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

require 'yaml'

def system(package_name)
	package package_name
end

def pip(package_name)
	python_pip package_name do
		action :install
	end
end

def gem(package_name)
	gem_package package_name do
		action :install
	end
end

def npm(package_name)
	execute "npm install -g #{package_name}"
end

def install_packages(package_bundle)
	package_bundle.each do |type, packages|
		packages.each do |p|
			send(type, p)
		end
	end
end

def packages(package_bundles)
	package_bundles.each do |package_bundle|
		install_packages package_bundle
	end
end

def postgres(database_info)
	postgresql_database database_info["name"] do
		c = database_info["connection-info"]
		connection ({:host => c["host"], :port => c["port"], :username => c["username"], :password => node['postgresql']['password']['postgres']})
		action :create
	end
end

def databases(database_bundles)
	database_bundles.each do |type, databases|
		databases.each do |database|
			send(type, database)
		end
	end
end

def execute_script(script_info)
	name = script_info["script"]
	execute name do
		if script_info["background"]
			command "#{name} &"
		end
		if not script_info["directory"].nil?
			cwd script_info["directory"]
		end
		timeout script_info["timeout"].nil? ? 120 : script_info["timeout"]
		action :run
	end
end

def scripts(script_infos)
	script_infos.each do |script_info|
		execute_script script_info
	end
end

def handle_config(config_bundles)
	config_bundles.each do |config_bundle|
		config_bundle.each do |type, bundle|
			send(type, bundle)
		end
	end
end

if File.exist? node[:agles][:configpath]
	config = YAML::load(File.read(node[:agles][:configpath]))
	handle_config(config)
end
