name "staging"
description "Agles staging"

run_list(
	"recipe[git]",
	"recipe[python]",
	"recipe[postgresql::server]",
	"recipe[postgresql::client]",
	"recipe[database]",
	"recipe[agles::rabbitmq]",
	"recipe[redisio::install]",
	"recipe[rvm::system]",
	"recipe[agles::dependencies]",
	"recipe[agles::setup_config]"
)
default_attributes(
	:agles => {
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
