#
# Cookbook Name:: agles
# Recipe:: verification_box
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

python_pip "pylint" do
	action :install
end

ruby_block "configure_packages" do
	block do
		agles_config = YAML::load_file(
				"/opt/mysource/agles_config.yml")

		machine_config = agles_config["machine"]

		machine_config["package"].each do |pkg|
			run_context = Chef::RunContext.new(node, {}, events)
			p = Chef::Resource::Package.new(pkg["name"], run_context)
			if not pkg["version"].nil?
				p.version(p["version"])
			end
			p.run_action(:install)
		end

		machine_config["pip"].each do |pkg|
			run_context = Chef::RunContext.new(node, {}, events)
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

ruby_block "configure_scripts" do
	block do
		agles_config = YAML::load_fie(
				"/opt/mysource/agles_config.yml")

		agles_config["config-script"].each do |script|
			run_context = Chef::RunContext.new(node, {}, events)
			s = Chef::Resource::Execute.new(script["script"])
			timeout = script["timeout"].nil? ? 120 : script["timeout"]
			s.timeout(script["timeout"])
			s.run_action(:install)
		end
	end
	action :nothing
	only_if do File.exists?("/opt/mysource/agles_config.yml") end
end

ruby_block "copy_agles_config" do
	block do
		run_context = Chef::RunContext.new(node, {}, events)
		f = Chef::Resource::File.new("/vagrant/agles_config.yml", run_context)
		f.content(IO.read("/opt/mysource/agles_config.yml"))
		f.run_action(:create)
	end
	action :nothing
	only_if do File.exists?("/opt/mysource/agles_config.yml") end
end

if not repo_config.nil?
	git "/opt/mysource" do
		repository "#{repo_config["repo_address"]}"
		revision "#{repo_config["sha_hash"]}"
		action :sync
		notifies :create, resources(:ruby_block => "configure_packages"), :immediately
		notifies :create, resources(:ruby_block => "configure_scripts"), :immediately
		notifies :create, resources(:ruby_block => "copy_agles_config"), :immediately
	end
end
