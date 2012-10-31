include_recipe "agles"

def language_configure(language, command)
	file "/home/#{node[:agles][:user]}/.#{language}.sh" do
		owner node[:agles][:user]
		content command
	end
end

def virtualenv_configure(new_virtualenv)
	node[:agles][:languages][:python][:virtualenv] = "/home/#{node[:agles][:user]}/#{new_virtualenv}"
	language_configure("python", "source #{new_virtualenv}/bin/activate")
end

def rvm_configure(new_ruby)
	node[:agles][:languages][:ruby][:ruby_string] = new_ruby
	language_configure("ruby", "rvm use #{new_ruby}")
end

def nave_configure(new_node)
	node[:agles][:languages][:node][:node_version] = new_node
	execute "./nave.sh usemain #{new_node}" do
		cwd "/home/#{node[:agles][:user]}"
	end
	language_configure("node", "./nave.sh use #{new_node}")
end

def setup_language(language, version)
	language = language.to_sym
	node[:agles][:languages][language] = {:version => version}
	case language
	when :python
		virtualenv_configure version
	when :ruby
		rvm_configure version
	when :node
		nave_configure version
	end
end

def handle_languages(languages)
	languages.each do |language, config|
		version = config["version"]
		setup_language(language, version)
	end
end

def handle_config(config)
	handle_languages(config["languages"]) if config.has_key? "languages"
end

config_path = "#{node[:agles][:source_path][:internal]}/#{node[:agles][:config_path]}"
if File.exist? config_path
	config = YAML::load(File.read(config_path))
	handle_config config
end
