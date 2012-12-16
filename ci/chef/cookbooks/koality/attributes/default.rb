#
# Cookbook Name:: koality
# Attributes:: koality
#
# Copyright 2012, Less Than Three Labs
#
# All rights reserved - Do Not Redistribute
#

default[:koality][:source_path][:external] = ""
default[:koality][:source_path][:internal] = "/home/lt3/source"
default[:koality][:config_path] = "koality.yml"
default[:koality][:user] = "lt3"
default[:koality][:languages] = {
	:python => {},
	:ruby => {
		:ruby_string => "default"
	},
	:node => {},
}

override['mysql']['server_root_password'] = ''
override['mysql']['server_repl_password'] = ''
override['mysql']['server_debian_password'] = ''
