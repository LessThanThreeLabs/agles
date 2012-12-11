name "verification_server"
description "Koality verification server"
run_list(
	"recipe[rvm]",
	"recipe[koality::verification_server]"
)
override_attributes(
	:koality => {
		:source_path => {
			:internal => "/home/lt3/code/agles",
		},
		:verification => {
			:server_count => 3
		}
	}
)
