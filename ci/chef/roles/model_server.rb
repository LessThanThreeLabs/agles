name "model_server"
description "Agles model server"
run_list(
	"recipe[agles::model_server]"
)
override_attributes(
	:agles => {
		:source_path => {
			:internal => "/home/lt3/code/agles",
		}
	}
)
