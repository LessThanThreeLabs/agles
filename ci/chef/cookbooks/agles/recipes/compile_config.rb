include_recipe "agles"

def create_compilescript(name, path, command)
	template "/home/#{node[:agles][:user]}/scripts/compile/#{name}.sh" do
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

def handle_compiles(compiles)
	compiles.each do |compile|
		name = compile.keys.first
		config = compile.values.first
		path = config["path"]
		command = config["script"]
		create_compilescript(name, path, command)
	end
end

def handle_config(config)
	handle_compiles(config["compile"]) if config.has_key? "compile"
end

config_path = "#{node[:agles][:source_path][:internal]}/#{node[:agles][:config_path]}"
if File.exist? config_path
	config = YAML::load(File.read(config_path))
	handle_config config
end
