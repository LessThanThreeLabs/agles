#
# Cookbook Name:: koality
# Recipe:: setup_config
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'koality'

require 'yaml'

def package_info(package)
	if package.instance_of? Hash
		package.first
	else
		[package, nil]
	end
end

def system(package_name, package_version)
	package package_name do
		version package_version if package_version
	end
end

def pip(package_name, package_version)
	python_pip package_name do
		virtualenv node[:koality][:languages][:python][:virtualenv].to_s
		version package_version if package_version
		action :install
	end
end

def gem(package_name, package_version)
	rvm_gem package_name do
		ruby_string node[:koality][:languages][:ruby][:ruby_string]
		version package_version if package_version
		action :install
	end
end

def npm(package_name, package_version)
	if package_name == "directory"
		execute "npm install" do
			cwd "#{node[:koality][:source_path][:internal]}/#{package_version}"
			environment({"HOME" => "/home/#{node[:koality][:user]}"})
		end
	else
		package_string = package_version ? "#{package_name}@#{package_version}" : package_name
		execute "npm install -g #{package_string}"
	end
end

def install_packages(package_bundle)
	package_bundle.each do |type, packages|
		packages.each do |p|
			send(type, *(package_info(p)))
		end
	end
end

def packages(package_bundles)
	package_bundles.each do |package_bundle|
		install_packages package_bundle
	end
end

def postgres(database_info)
	passwd = database_info["password"].to_s
	postgresql_database_user database_info["username"] do
		password passwd
		connection({:username => "postgres", :password => ""})
		action :create
	end
	postgresql_database database_info["name"] do
		connection({:username => "postgres", :password => ""})
		action :create
	end
	postgresql_database_user database_info["username"] do
		database_name database_info["name"]
		password passwd
		connection({:username => "postgres", :password => ""})
		action :grant
	end
end

def mysql(database_info)
	passwd = database_info["password"].to_s
	mysql_database_user database_info["username"] do
		password passwd
		connection({:username => "root", :password => ""})
		action :create
	end
	mysql_database database_info["name"] do
		connection({:username => "root", :password => ""})
		action :create
	end
	mysql_database_user database_info["username"] do
		password passwd
		connection({:username => "root", :password => ""})
		action :grant
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
	rvm_shell name do
		code name
		if node[:koality][:languages][:ruby][:ruby_string]
			ruby_string node[:koality][:languages][:ruby][:ruby_string]
		end
		if script_info["background"]
			code "#{name} &"
		end
		if not script_info["directory"].nil?
			cwd "#{node[:koality][:source_path][:internal]}/#{script_info["directory"]}"
		end
		timeout script_info["timeout"].nil? ? 600 : script_info["timeout"]
		environment({"HOME" => "/home/#{node[:koality][:user]}"})
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

config_path = "#{node[:koality][:source_path][:internal]}/#{node[:koality][:config_path]}"
if File.exist? config_path
	config = YAML::load(File.read(config_path))
	handle_config config
end
