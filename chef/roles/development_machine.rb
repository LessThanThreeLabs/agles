name "development_machine"
description "Agles development virtual machine"
run_list(
	"recipe[git]",
	"recipe[python]",
	"recipe[database]",
	"recipe[rabbitmq]",
	"recipe[redis]",
	"recipe[agles::development]"
)
