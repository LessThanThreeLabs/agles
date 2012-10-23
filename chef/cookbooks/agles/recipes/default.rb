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
	execute "apt-get update"
end

node[:agles][:user] = "vagrant" if node[:vagrant]
include_recipe "rvm::vagrant" if node[:vagrant]
