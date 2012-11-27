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
		commands = config["script"]
		if not commands.is_a? Array
			commands = [commands]
		end
		validator_command = ""
		commands.each do |command|
			command = command.gsub("\n", "\\n")
			validator_command += "/home/#{node[:agles][:user]}/scripts/validator.sh \"#{command}\"\n"
		end
		create_compilescript(name, path, validator_command)
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
