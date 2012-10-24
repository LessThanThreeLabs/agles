include_recipe "agles"

def get_default_languages()
	return {:python => {},
			:ruby => {
				:ruby_string => "default"
			},
			:node => {},
		}
end

def bashrc_configure(to_remove, to_add)
	bash "configure bashrc" do
		user node[:agles][:user]
		cwd "/home/#{node[:agles][:user]}"
		code <<-EOH
		sed '/#{to_remove}/d' .bashrc > .tmpbashrc
		mv .tmpbashrc .bashrc
		echo #{to_add} >> .bashrc
		EOH
	end.run_action(:run)
end

def virtualenv_configure(new_virtualenv)
	node[:agles][:languages][:python][:virtualenv] = "/home/#{node[:agles][:user]}/#{new_virtualenv}"
	bashrc_configure("source .*\\/bin\\/activate", "source #{new_virtualenv}/bin/activate")
end

def rvm_configure(new_ruby)
	node[:agles][:languages][:ruby][:ruby_string] = new_ruby
	bashrc_configure("rvm use", "rvm use #{new_ruby}")
end

def nave_configure(new_node)
	execute "./nave.sh usemain #{new_node}" do
		cwd "/home/#{node[:agles][:user]}"
	end
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
	handle_languages(config["build"]) if config.has_key? "build"
end

node[:agles][:languages] = get_default_languages
config_path = "#{node[:agles][:source_path][:internal]}/#{node[:agles][:config_path]}"
if File.exist? config_path
	config = YAML::load(File.read(config_path))
	handle_config config
end
