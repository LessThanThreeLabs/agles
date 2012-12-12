include_recipe "koality"

directory "/home/#{node[:koality][:user]}/scripts" do
	owner node[:koality][:user]
end

directory "/home/#{node[:koality][:user]}/scripts/language" do
	owner node[:koality][:user]
end

def language_configure(language, command)
	file "/home/#{node[:koality][:user]}/scripts/language/#{language}.sh" do
		owner node[:koality][:user]
		content command
	end
end

def virtualenv_configure(new_virtualenv)
	node[:koality][:languages][:python][:virtualenv] = "/home/#{node[:koality][:user]}/virtualenvs/#{new_virtualenv}"
	language_configure("python", "source virtualenvs/#{new_virtualenv}/bin/activate")
end

def rvm_configure(new_ruby)
	node[:koality][:languages][:ruby][:ruby_string] = new_ruby
	language_configure("ruby", "rvm use #{new_ruby}")
end

def nvm_configure(new_node)
	new_node = "v#{new_node}" if not new_node.start_with? "v"
	node[:koality][:languages][:node][:node_version] = new_node
	link "/usr/local/bin/node" do
		to "/home/#{node[:koality][:user]}/#{new_node}/bin/node"
	end
	link "/usr/local/bin/npm" do
		to "/home/#{node[:koality][:user]}/#{new_node}/bin/npm"
	end
	language_configure("nodejs", "source ./nvm.sh\nnvm use #{new_node}")
end

def setup_language(language, version)
	language = language.to_sym
	node[:koality][:languages][language] = {:version => version}
	case language
	when :python
		virtualenv_configure version
	when :ruby
		rvm_configure version
	when :nodejs
		nvm_configure version
	end
end

def handle_languages(languages)
	languages.each do |language, version|
		setup_language(language, version)
	end
end

def handle_config(config)
	handle_languages(config["languages"]) if config.has_key? "languages"
end

config_path = "#{node[:koality][:source_path][:internal]}/#{node[:koality][:config_path]}"
if File.exist? config_path
	config = YAML::load(File.read(config_path))
	handle_config config
end
