#!/usr/bin/python
import argparse
import os
import uuid

from bunnyrpc.server import Server
from repo.store import RepositoryStore, FileSystemRepositoryStore
from settings import store

DEFAULT_ROOT_DIR = "/repositories"


def count_repositories(root_dir):
	count = 0
	for root, dirs, files in os.walk(root_dir):
		if root.endswith('.git') and not root.endswith('/.git'):
			count += 1
	return count


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("-e", "--exchange_name", help="The exchange to bind this server to")
	parser.add_argument("-r", "--root_dir", help="The root directory to add repositories to")
	parser.set_defaults(exchange_name=store.rpc_exchange_name, root_dir=DEFAULT_ROOT_DIR)
	args = parser.parse_args()

	root_dir = os.path.realpath(args.root_dir)
	try:
		config = RepositoryStore.parse_config(root_dir)
		num_repos = count_repositories(root_dir)
		RepositoryStore.update_store(config["id"], root_dir, num_repos)
	except IOError:
		repostore_id = RepositoryStore.initialize_store(root_dir)
		config = RepositoryStore.create_config(repostore_id, root_dir)


	print "Starting FileSystem Repository Server '%s' on exchange '%s' with root directory '%s' ..." % (
		config["id"], args.exchange_name, root_dir)

	fs_repo_server = Server(FileSystemRepositoryStore(root_dir))
	fs_repo_server.bind(args.exchange_name, [str(config["id"])], auto_delete=True)
	fs_repo_server.run()


if __name__ == "__main__":
	main()
