name "verification_server"
description "Agles verification server"
run_list(
	"recipe[agles::verification_server]"
)
override_attributes(
	:agles => {
		:source_path => {
			:internal => "/home/lt3/code/agles",
		}
	}
)
