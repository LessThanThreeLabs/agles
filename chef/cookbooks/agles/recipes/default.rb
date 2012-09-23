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
