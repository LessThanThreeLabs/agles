name "verification_box"
description "Agles verification virtual box"
run_list(
	"recipe[python]",
	"recipe[postgresql::server]",
	"recipe[postgresql::client]",
	"recipe[database]",
	"recipe[agles::copy_source]",
	"recipe[rvm::system]",
	"recipe[agles::dependencies]",
	"recipe[agles::language_config]",
	"recipe[agles::configure]",
	"recipe[agles::verification_box]"
)
