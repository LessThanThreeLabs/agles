#
# Cookbook Name:: verification
# Recipe:: default
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

require 'yaml'

directory "/opt/mysource" do
	recursive true
	action :delete
end

directory "/opt/mysource" do
	owner "root"
	group "root"
	mode "0755"
	action :create
end

if File.exists?("/vagrant/repo_config.yml")
	repo_config = YAML::load_file(
			"/vagrant/repo_config.yml")
end

execute "apt-get update"

python_pip "pylint" do
	action :install
end

ruby_block "package_config" do
	block do
		package_config = YAML::load_file(
				"/opt/mysource/agles_config.yml")
		
		package_config["package"].each do |pkg|
			run_context = Chef::RunContext.new(node, {})
			p = Chef::Resource::Package.new(pkg["name"], run_context)
			if not pkg["version"].nil?
				p.version(p["version"])
			end
			p.run_action(:install)
		end

		package_config["pip"].each do |pkg|
			run_context = Chef::RunContext.new(node, {})
			p = Chef::Resource::PythonPip.new(pkg["name"], run_context)
			if not pkg["version"].nil?
				p.version(p["version"])
			end
			p.run_action(:install)
		end
	end
	action :nothing
	only_if do File.exists?("/opt/mysource/agles_config.yml") end
end

if not repo_config.nil?
	git "/opt/mysource" do
		repository "#{repo_config["repo_address"]}"
		revision "#{repo_config["sha_hash"]}"
		action :sync
		notifies :create, resources(:ruby_block => "package_config"), :immediately
	end
end
