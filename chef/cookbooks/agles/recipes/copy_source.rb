#
# Cookbook Name:: agles
# Recipe:: copy_source
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

target_source_dir = "/home/vagrant/source"

# Clone all of the code from the shared directory into the VM
# Runs at recipe compile time
system "rm -rf #{target_source_dir}"
system "cp -r #{node[:agles][:source_path]} #{target_source_dir}"
