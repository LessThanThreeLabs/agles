#!/usr/bin/python
import argparse

from verification_master import VerificationMaster

from settings.model_server import model_server_rpc_address

DEFAULT_MODEL_SERVER_ADDRESS = model_server_rpc_address


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("-s", "--model_server_address",
			help="The model server address to connect this server to")
	parser.set_defaults(model_server_address=DEFAULT_MODEL_SERVER_ADDRESS)
	args = parser.parse_args()

	print "Starting Verification Master on %s ..." % (
			args.model_server_address)

	master = VerificationMaster(args.model_server_address)
	master.run()


main()
