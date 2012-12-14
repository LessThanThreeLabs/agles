name "development_machine"
description "Koality development virtual machine"
run_list(
	"recipe[git]",
	"recipe[python]",
	"recipe[postgresql::server]",
	"recipe[postgresql::client]",
	"recipe[database]",
	"recipe[rabbitmq]",
	"recipe[koality::setup_config]"
)
default_attributes(
	:koality => {
		:source_path => {
			:external => "/vagrant"
		},
		:config_path => "ci/general/dev_config.yml"
	}
)
