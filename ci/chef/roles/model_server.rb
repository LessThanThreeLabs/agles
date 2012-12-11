name "model_server"
description "Koality model server"
run_list(
	"recipe[koality::model_server]"
)
override_attributes(
	:koality => {
		:source_path => {
			:internal => "/home/lt3/code/agles",
		}
	}
)
