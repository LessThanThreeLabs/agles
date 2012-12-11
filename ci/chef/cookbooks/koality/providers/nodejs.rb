require 'chef/mixin/shell_out'
require 'chef/mixin/language'
include Chef::Mixin::ShellOut

def load_current_resource
	@version = new_resource.version
end

def setup_nvm
	if not ::File.exists? "/home/#{node[:koality][:user]}/nvm.sh"
		bash "get nvm.sh" do
			user node[:koality][:user]
			cwd "/home/#{node[:koality][:user]}"
			code <<-EOH
			wget https://raw.github.com/creationix/nvm/master/nvm.sh
			chmod +x nvm.sh
			EOH
			action :nothing
		end.run_action(:run)
	end
end

def nodejs_installed?(node_version)
	exists = Chef::ShellOut.new("source /home/#{node[:koality][:user]}/nvm.sh; nvm ls | grep -c #{node_version}",
		:user => node[:koality][:user], :env => {"HOME" => "/home/#{node[:koality][:user]}"})
	exists.run_command
	return exists.exitstatus == 0 ? true : false
end

def install_nodejs(node_version)
	bash "install Nodejs[#{node_version}]" do
		user node[:koality][:user]
		code "source /home/#{node[:koality][:user]}/nvm.sh; nvm install #{node_version}"
		environment({"HOME" => "/home/#{node[:koality][:user]}"})
		action :nothing
	end.run_action(:run)
end

action :install do
	setup_nvm
	if nodejs_installed?(@version)
		Chef::Log.info("Nodejs[#{@version}] is already installed, so skipping")
	else
		if install_nodejs(@version)
			Chef::Log.info("Installation of Nodejs[#{@version}] was successful.")
		end
	end
end
