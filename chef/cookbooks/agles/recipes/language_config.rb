include_recipe "agles"

def get_default_languages()
	return {:python => nil, :ruby => nil}
end

def bashrc_configure(to_remove, to_add)
	bash_command = bash "configure bashrc" do
		user node[:agles][:user]
		cwd "/home/#{node[:agles][:user]}"
		code <<-EOH
		sed '/#{to_remove}/d' .bashrc > .bashrc
		echo #{to_add} >> .bashrc
		EOH
	bash_command.run_action(:run)
end

def virtualenv_configure(new_virtualenv)
	node[:agles][:languages][:python][:virtualenv] = "/home/#{node[:agles][:user]}/#{new_virtualenv}"
	bashrc_configure("source .*\\/bin\\/activate", "source #{new_virtualenv}/bin/activate")
end

def rvm_configure(new_ruby)
	node[:agles][:languages][:ruby][:ruby_string] = version
	bashrc_configure("rvm use", "rvm use #{new_ruby}")
end

def setup_language(language, version)
	language = language.to_sym
	node[:agles][:languages][language] = {:version => version}
	case language
	when :python
		virtualenv_configure(version)
	when :ruby
		rvm_configure(version)
	end
end

def handle_languages(languages)
	puts languages
	node[:agles][:languages] = get_default_languages
	languages.each do |language, config|
		version = config["version"]
		setup_language(language, version)
	end
end

def handle_config(config)
	handle_languages(config["build"]) if config.has_key? "build"
end

config_path = "#{node[:agles][:source_path][:internal]}/#{node[:agles][:config_path]}"
if File.exist? config_path
	config = YAML::load(File.read(config_path))
	handle_config(config)
end
