require 'chef/mixin/shell_out'
require 'chef/mixin/language'
include Chef::Mixin::ShellOut

def load_current_resource
	@version = new_resource.version
end

def setup_nave
	bash "get nave.sh" do
		user node[:agles][:user]
		cwd "/home/#{node[:agles][:user]}"
		code <<-EOH
		if [ ! -f "nave.sh" ]
			then wget https://raw.github.com/isaacs/nave/master/nave.sh
			chmod +x nave.sh
		fi
		EOH
	end.run_action(:run)
end

def nodejs_installed?(node_version)
	exists = Chef::ShellOut.new("/home/#{node[:agles][:user]}/nave.sh ls | grep #{node_version}")
	exists.run_command
	return exists.exitstatus == 0 ? true : false
end

def install_nodejs(node_version)
	bash "install Nodejs[#{node_version}]" do
		user node[:agles][:user]
		cwd "/home/#{node[:agles][:user]}"
		code <<-EOH
		./nave.sh install #{node_version}
		EOH
	end.run_action(:run)
end

action :install do
	setup_nave
	if nodejs_installed?(@version)
		Chef::Log.debug("Nodejs[#{@version}] is already installed, so skipping")
	else
		if install_nodejs(@version)
			Chef::Log.info("Installation of Nodejs[#{@version}] was successful.")
		else
			Chef::Log.warn("Failed to install Nodejs[#{@version}].")
		end
	end
end
