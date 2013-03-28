#!/usr/bin/env python
import settings.log

from model_server.model_server import ModelServer


def main():
	print "Starting Model Server ..."

	settings.log.configure()
	ModelServer().start().wait()


main()
