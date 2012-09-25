#
# Cookbook Name:: agles
# Recipe:: copy_source
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

require 'fileutils'

# Clone all of the code from the shared directory into the VM
# Runs at recipe compile time
FileUtils.rmtree(node[:agles][:source_path][:internal])
FileUtils.cp_r(node[:agles][:source_path][:external], node[:agles][:source_path][:internal])
FileUtils.chown_R('vagrant', 'vagrant', node[:agles][:source_path][:internal])
