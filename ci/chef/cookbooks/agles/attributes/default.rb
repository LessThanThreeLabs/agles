#
# Cookbook Name:: agles
# Attributes:: agles
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

default[:agles][:source_path][:external] = "/vagrant/source"
default[:agles][:source_path][:internal] = "/home/vagrant/source"
default[:agles][:config_path] = "agles_config.yml"
default[:agles][:user] = "lt3"
default[:agles][:languages] = {
	:python => {},
	:ruby => {
		:ruby_string => "default"
	},
	:node => {},
}

override['mysql']['server_root_password'] = ''
override['mysql']['server_repl_password'] = ''
override['mysql']['server_debian_password'] = ''
