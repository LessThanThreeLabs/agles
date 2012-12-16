#
# Cookbook Name:: koality
# Recipe:: default
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'rvm'

case node[:platform]
when "ubuntu"
	execute "apt-get update" do
		ignore_failure true
	end
end

if node[:vagrant]
	node.set[:koality][:user] = "vagrant"
	node.set[:koality][:source_path][:external] = "/vagrant/source"
	node.set[:koality][:source_path][:internal] = "/home/vagrant/source"
	include_recipe "rvm::vagrant"
end
