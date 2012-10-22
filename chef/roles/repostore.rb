name "repostore"
description "Agles sets up sshd for a repostore"
run_list(
	"recipe[agles::repostore_server_config]"
)
override_attributes(
	:agles => {
		:source_path => {
			:internal => "/home/lt3/code/agles"
		},
	}
)
