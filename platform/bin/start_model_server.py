#!/usr/bin/python
import argparse

from model_server import ModelServer
from settings.model_server import model_server_rpc_address

DEFAULT_ADDRESS = model_server_rpc_address


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("-s", "--server_address", help="The address to bind this server to")
	parser.set_defaults(server_address=DEFAULT_ADDRESS)
	args = parser.parse_args()

	print "Starting Model Server on %s ..." % (
		args.server_address)

	ModelServer.start(args.server_address)


main()
