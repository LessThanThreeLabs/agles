name "verification_master"
description "Agles verification master"
run_list(
	"recipe[agles::verification_master]"
)
override_attributes(
	:agles => {
		:source_path => {
			:internal => "/home/lt3/code/agles",
		}
	}
)
