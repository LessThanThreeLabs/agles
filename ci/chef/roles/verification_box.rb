name "verification_box"
description "Koality verification virtual box"
run_list(
	"recipe[python]",
	"recipe[postgresql::server]",
	"recipe[postgresql::client]",
	"recipe[mysql::server]",
	"recipe[mysql::client]",
	"recipe[mysql::ruby]",
	"recipe[database]",
	"recipe[koality::rabbitmq]",
	"recipe[koality::copy_source]",
	"recipe[redisio::install]",
	"recipe[rvm::system]",
	"recipe[koality::dependencies]",
	"recipe[koality::verification_box]"
)

default_attributes(
	:rvm => {
		:default_ruby => "ruby-1.9.3-p286"
	}
)
