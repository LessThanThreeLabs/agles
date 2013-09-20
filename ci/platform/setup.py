from setuptools import setup, find_packages
from shared.constants import VERSION

setup(
	name="koality",
	version=VERSION,
	description="Production code for koality",
	packages=find_packages(exclude=[
		"bin",
		"tests",
	]),
	entry_points={
		'console_scripts': [
# SETUP
			'koality-schema = database.schema:main',
# SSH
			'koality-authorized-keys-script = scripts.ssh.authorized_keys_script:main',
			'koality-serve = scripts.ssh.serve:main',
# GIT
			'force-delete = scripts.repo.force_delete:main',
			'force-push = scripts.repo.force_push:main',
			'push-to-forwardurl = scripts.repo.push_to_forwardurl:main',
			'store-pending-and-trigger-build = scripts.repo.store_pending_and_trigger_build:main',
			'verify-repository-permissions = scripts.repo.verify_repository_permissions:main',
			'koality-ssh-with-private-key = scripts.repo.git_with_private_key:main',
# SERVERS
			'koality-start-filesystem-repo-server = scripts.server.start_filesystem_repo_server:main',
			'koality-start-model-server = scripts.server.start_model_server:main',
			'koality-start-verification-server = scripts.server.start_verification_server:main',
			'koality-snapshotter = scripts.server.snapshotter:main',
			'koality-upgrade = scripts.server.upgrader:main',
		],
	},
)
