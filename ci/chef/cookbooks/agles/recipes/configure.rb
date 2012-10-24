#
# Cookbook Name:: agles
# Recipe:: configure
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

include_recipe "agles"

require 'yaml'

def system(package_name)
	package package_name
end

def pip(package_name)
	python_pip package_name do
		virtualenv node[:agles][:languages][:python][:virtualenv]
		action :install
	end
end

def gem(package_name)
	rvm_gem package_name do
		ruby_string node[:agles][:languages][:ruby][:ruby_string]
		action :install
	end
end

def npm(package_name)
	execute "npm install #{package_name}" do
		cwd node[:agles][:source_path][:internal]
		environment({"HOME" => "/home/#{node[:agles][:user]}"})
	end
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
		connection({:host => c["host"], :port => c["port"], :username => c["username"], :password => node['postgresql']['password']['postgres']})
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
			cwd "#{node[:agles][:source_path][:internal]}/#{script_info["directory"]}"
		end
		timeout script_info["timeout"].nil? ? 600 : script_info["timeout"]
		environment({"HOME" => "/home/#{node[:agles][:user]}"})
		action :run
	end
end

def scripts(script_infos)
	script_infos.each do |script_info|
		execute_script script_info
	end
end

def handle_setup(setup_bundles)
	setup_bundles.each do |setup_bundle|
		setup_bundle.each do |type, bundle|
			send(type, bundle)
		end
	end
end

def handle_config(config)
	handle_setup(config["setup"]) if config.has_key? "setup"
end

config_path = "#{node[:agles][:source_path][:internal]}/#{node[:agles][:config_path]}"
if File.exist? config_path
	config = YAML::load(File.read(config_path))
	handle_config config
end
