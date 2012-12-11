include_recipe "koality"

def create_compilescript(name, path, validated_commands, timeout)
	template "/home/#{node[:koality][:user]}/scripts/compile/#{name}.sh" do
		source "shell_command.erb"
		owner node[:koality][:user]
		mode "0755"
		variables(
			:name => name,
			:user => node[:koality][:user],
			:path => path,
			:validated_commands => validated_commands,
			:timeout => timeout
		)
	end
end

def handle_compiles(compiles)
	compiles.each do |compile|
		name = compile.keys.first
		config = compile.values.first
		path = config["path"]
		timeout = (config["timeout"] or 120)
		commands = config["script"]
		if not commands.is_a? Array
			commands = [commands]
		end
		commands = commands.map do |command|
			command.gsub("\n", "\\n").gsub("\"", "\\\"")
		end
		create_compilescript(name, path, commands, timeout)
	end
end

def handle_config(config)
	handle_compiles(config["compile"]) if config.has_key? "compile"
end

config_path = "#{node[:koality][:source_path][:internal]}/#{node[:koality][:config_path]}"
if File.exist? config_path
	config = YAML::load(File.read(config_path))
	handle_config config
end
