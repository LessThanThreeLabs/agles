name "staging"
description "Agles staging"

run_list(
	"recipe[git]",
	"recipe[python]",
	"recipe[postgresql::server]",
	"recipe[postgresql::client]",
	"recipe[database]",
	"recipe[rabbitmq]",
	"recipe[redisio::install]",
	"recipe[rvm::system]",
	"recipe[agles::dependencies]",
	"recipe[agles::language_config]",
	"recipe[agles::configure]"
)
default_attributes(
	:postgresql => {
		:password => {
			:postgres => "agles"
		}
	},
	:agles => {
		:source_path => {
			:internal => "/home/lt3/code/agles"
		},
		:config_path => "general/dev_config.yml"
	}
)
override_attributes()
