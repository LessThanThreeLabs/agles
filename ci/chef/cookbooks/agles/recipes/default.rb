#
# Cookbook Name:: agles
# Recipe:: default
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

case node[:platform]
when "ubuntu"
	execute "apt-get update" do
		ignore_failure true
	end
end

if node[:vagrant]
	node[:agles][:user] = "vagrant"
	node[:agles][:source_path][:internal] = "/home/vagrant/source"
	include_recipe "rvm::vagrant"
end
