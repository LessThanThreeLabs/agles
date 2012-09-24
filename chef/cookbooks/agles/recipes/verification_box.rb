#
# Cookbook Name:: agles
# Recipe:: verification_box
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

python_pip "pylint" do
	action :install
end

target_source_dir = "/home/vagrant/source"

directory target_source_dir do
	recursive true
	action :delete
end

# Clone all of the code from the shared directory into the VM
execute "copy source" do
	command "cp -r #{node[:agles][:source_path]} #{target_source_dir}"
	creates target_source_dir
	action :run
	only_if {File.exists? node[:agles][:source_path]}
end
