name "verification_box"
description "Agles verification virtual box"
run_list(
	"recipe[python]",
	"recipe[postgresql::server]",
	"recipe[postgresql::client]",
	"recipe[mysql::server]",
	"recipe[mysql::client]",
	"recipe[database]",
	"recipe[agles::rabbitmq]",
	"recipe[agles::copy_source]",
	"recipe[redisio::install]",
	"recipe[rvm::system]",
	"recipe[agles::dependencies]",
	"recipe[agles::verification_box]"
)

default_attributes(
	:rvm => {
		:default_ruby => "ruby-1.9.3-p286"
	}
)
