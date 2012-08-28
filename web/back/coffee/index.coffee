profiler = require('nodetime').profile
	accountKey: 'e32c83cafbf931d5e47aca4c66f34bc7b36701f3'
	appName: 'Less Than Three'

os = require 'os'
cluster = require 'cluster'
context = require './context'
environment = require './environment'
server = require './server/server'


createMultipleServers = () ->
	if cluster.isMaster
		numCpus = os.cpus().length
		cluster.fork() for num in [0...numCpus]
	else
		server.start context

environment.setup context

if context.config.server.cluster
	createMultipleServers()
else
	server.start context