require 'chef/mixin/shell_out'
require 'chef/mixin/language'
include Chef::Mixin::ShellOut

def load_current_resource
	@version = new_resource.version
end

def setup_nave
	if not ::File.exists? "/home/#{node[:agles][:user]}/nave.sh"
		bash "get nave.sh" do
			user node[:agles][:user]
			cwd "/home/#{node[:agles][:user]}"
			code <<-EOH
			wget https://raw.github.com/isaacs/nave/master/nave.sh
			chmod +x nave.sh
			EOH
			action :nothing
		end.run_action(:run)
	end
end

def nodejs_installed?(node_version)
	exists = Chef::ShellOut.new("/home/#{node[:agles][:user]}/nave.sh ls | grep -c #{node_version} | grep ^2$",
		:user => node[:agles][:user], :env => {"HOME" => "/home/#{node[:agles][:user]}"})
	exists.run_command
	return exists.exitstatus == 0 ? true : false
end

def install_nodejs(node_version)
	bash "install Nodejs[#{node_version}]" do
		user node[:agles][:user]
		code "/home/#{node[:agles][:user]}/nave.sh install #{node_version}"
		environment({"HOME" => "/home/#{node[:agles][:user]}"})
		action :nothing
	end.run_action(:run)
end

action :install do
	setup_nave
	if nodejs_installed?(@version)
		Chef::Log.info("Nodejs[#{@version}] is already installed, so skipping")
	else
		if install_nodejs(@version)
			Chef::Log.info("Installation of Nodejs[#{@version}] was successful.")
		end
	end
end
