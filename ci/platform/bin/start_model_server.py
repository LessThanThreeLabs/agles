#!/usr/bin/env python
import settings.log

from model_server.model_server import ModelServer


def main():
	print "Starting Model Server ..."

	settings.log.configure()
	try:
		model_server = ModelServer().start()
	except:
		print "Failed to start Model Server"
		raise
	print "Successfully started Model Server"
	model_server.wait()


main()
