name "model_server"
description "Koality model server"
run_list(
	"recipe[koality::model_server]"
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
