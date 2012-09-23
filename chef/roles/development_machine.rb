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
