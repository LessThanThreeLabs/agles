name "webserver"
description "Koality webserver"
run_list(
	"recipe[koality::webserver]"
)
default_attributes(
	:koality => {
		:source_path => {
			:internal => "/home/lt3/code/agles",
		}
	}
)