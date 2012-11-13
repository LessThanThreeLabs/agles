name "verification_server"
description "Agles verification server"
run_list(
	"recipe[rvm]",
	"recipe[agles::verification_server]"
)
override_attributes(
	:agles => {
		:source_path => {
			:internal => "/home/lt3/code/agles",
		},
		:verification => {
			:server_count => 3
		}
	}
)
