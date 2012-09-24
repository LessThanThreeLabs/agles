name "development_machine"
description "Agles development virtual machine"
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
		:source_path => "/vagrant",
		:config_path => "general/dev_config.yml"
	}
)
