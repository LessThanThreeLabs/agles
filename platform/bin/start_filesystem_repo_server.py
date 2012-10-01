#!/usr/bin/python
import argparse
import os

from bunnyrpc.server import Server
from repo.store import FileSystemRepositoryStore
from settings import store

DEFAULT_ROOT_DIR = "/repositories"


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("-e", "--exchange_name", help="The exchange to bind this server to")
	parser.add_argument("-r", "--root_dir", help="The root directory to add repositories to")
	parser.add_argument("-s", "--store_name", help="The store name of his filesystem repo server. All store names should be unique.", required=True)
	parser.set_defaults(exchange_name=store.rpc_exchange_name, root_dir=DEFAULT_ROOT_DIR)
	args = parser.parse_args()

	assert args.store_name in store.filesystem_repository_servers

	root_dir = os.path.realpath(args.root_dir)
	print "Starting FileSystem Repository Server '%s' on exchange '%s' with root directory '%s' ..." % (
		args.store_name, args.exchange_name, root_dir)

	fs_repo_server = Server(FileSystemRepositoryStore(root_dir))
	fs_repo_server.bind(args.exchange_name, [args.store_name])
	fs_repo_server.run()


main()
