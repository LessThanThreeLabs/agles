name "verification_server"
description "Koality verification server"
run_list(
	"recipe[koality::verification_server]"
)
default_attributes(
	:koality => {
		:source_path => {
			:internal => "/home/lt3/code/agles",
		},
		:verification => {
			:server_count => 3
		}
	}
)
