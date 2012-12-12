name "repostore"
description "Koality sets up sshd for a repostore"
run_list(
	"recipe[koality::gituser]",
	"recipe[koality::repostore_server_config]",
	"recipe[koality::filesystem_repo_server]"
)
override_attributes(
	:koality => {
		:source_path => {
			:internal => "/home/lt3/code/agles",
			:platform => "/home/lt3/code/agles/ci/platform",
			:authorized_keys_script => "/home/lt3/code/agles/ci/platform/bin/ssh/authorized_keys_script.py"
		},
		:repositories_path => "/git/repositories"
	}
)
