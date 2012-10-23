include_recipe "agles"

def get_default_languages()
	return {:python => nil, :ruby => nil}
end

def setup_language(language, version)
	language = language.to_sym
	node[:agles][:languages][language] = {:version => version}
	case language
	when :python
		node[:agles][:languages][:python][:virtualenv] = "/home/#{node[:agles][:user]}/#{version}"
	when :ruby
		rvm_default_ruby version
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
