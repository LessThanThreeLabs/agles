name "staging"
description "Agles staging"
run_list(
	"recipe[git]",
	"recipe[python]",
	"recipe[postgresql::server]",
	"recipe[postgresql::client]",
	"recipe[database]",
	"recipe[rabbitmq]",
	"recipe[agles::configure]"
)
default_attributes(
	:postgresql => {
		:password => {
			:postgres => "agles"
		}
	}
)
override_attributes(
	:agles => {
		:source_path => {
			:internal => "/home/lt3/code/agles"
		},
		:config_path => "general/dev_config.yml"
	},
	:python => {
		:install_method => "source",
		:version => "2.7.3"
	}
)
