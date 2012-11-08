include_recipe "agles"

def create_buildscript(name, path, command)
	template "/home/#{node[:agles][:user]}/scripts/build/#{name}.sh" do
		source "shell_command.erb"
		owner node[:agles][:user]
		mode "0755"
		variables(
			:user => node[:agles][:user],
			:path => path,
			:command => command
		)
	end
end

def handle_builds(builds)
	builds.each do |name, config|
		path = config["path"]
		command = config["script"]
		create_buildscript(name, path, command)
	end
end

def handle_config(config)
	handle_builds(config["build"]) if config.has_key? "build"
end

config_path = "#{node[:agles][:source_path][:internal]}/#{node[:agles][:config_path]}"
if File.exist? config_path
	config = YAML::load(File.read(config_path))
	handle_config config
end
