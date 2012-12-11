name "staging_config"
description "Koality staging configuration"

run_list(
	"recipe[git]",
	"recipe[python]",
	"recipe[postgresql::server]",
	"recipe[postgresql::client]",
	"recipe[database]",
	"recipe[koality::rabbitmq]",
	"recipe[redisio::install]",
	"recipe[rvm::system]",
	"recipe[koality::dependencies]",
	"recipe[koality::setup_config]"
)
default_attributes(
	:koality => {
		:source_path => {
			:internal => "/home/lt3/code/agles"
		},
		:config_path => "general/staging.yml"
	},
	:rvm => {
		:default_ruby => "ruby-1.9.3-p286"
	}
)
override_attributes()
