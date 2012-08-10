#!/usr/bin/python
import argparse
import os

import zerorpc

from repo_store import FileSystemRepoStore

DEFAULT_ADDRESS = "tcp://0.0.0.0:4242"
DEFAULT_ROOT_DIR = "/repositories"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--server_address", help="The address to bind this server to")
    parser.add_argument("-r", "--root_dir", help="The root directory to add repositories to")
    parser.set_defaults(server_address=DEFAULT_ADDRESS, root_dir=DEFAULT_ROOT_DIR)
    args = parser.parse_args()

    root_dir = os.path.realpath(args.root_dir)
    print "Starting FileSystem Repository Server on %s with root directory %s ..." % (
        args.server_address, root_dir)

    fs_repo_server = zerorpc.Server(FileSystemRepoStore(root_dir))
    fs_repo_server.bind(args.server_address)
    fs_repo_server.run()


main()
