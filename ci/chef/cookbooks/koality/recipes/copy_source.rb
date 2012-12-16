#
# Cookbook Name:: koality
# Recipe:: copy_source
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

include_recipe "koality"

require 'fileutils'

# Clone all of the code from the shared directory into the VM
# Runs at recipe compile time
if File.exists? node[:koality][:source_path][:external]
	FileUtils.rmtree(node[:koality][:source_path][:internal])
	FileUtils.cp_r(node[:koality][:source_path][:external], node[:koality][:source_path][:internal])
	FileUtils.chown_R(node[:koality][:user], node[:koality][:user], node[:koality][:source_path][:internal])
end
