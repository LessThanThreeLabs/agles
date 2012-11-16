name "repostore"
description "Agles sets up sshd for a repostore"
run_list(
	"recipe[agles::repostore_server_config]",
	"recipe[agles::filesystem_repo_server]"
)
override_attributes(
	:agles => {
		:source_path => {
			:internal => "/home/lt3/code/agles",
			:platform => "/home/lt3/code/agles/ci/platform",
			:authorized_keys_script => "/home/lt3/code/agles/ci/platform/bin/ssh/authorized_keys_script.py"
		},
		:repositories_path => "/git/repositories"
	}
)
