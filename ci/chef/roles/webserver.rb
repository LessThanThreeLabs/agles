name "webserver"
description "Koality webserver"
run_list(
	"recipe[koality::webserver]"
)
default_attributes(
	:koality => {
		:source_path => {
			:internal => "/home/lt3/code/agles",
		},
		:supervisor => {
			:logdir => "/home/lt3/code/agles/ci/production/logs/supervisor",
		}
	}
)
