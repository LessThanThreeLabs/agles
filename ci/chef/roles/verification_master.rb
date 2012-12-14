name "verification_master"
description "Koality verification master"
run_list(
	"recipe[koality::verification_master]"
)
default_attributes(
	:koality => {
		:source_path => {
			:internal => "/home/lt3/code/agles",
		}
	}
)
