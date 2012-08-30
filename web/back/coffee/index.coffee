profiler = require('nodetime').profile
	accountKey: 'e32c83cafbf931d5e47aca4c66f34bc7b36701f3'
	appName: 'Less Than Three'

os = require 'os'
cluster = require 'cluster'
context = require './context'
modelConnection = require './modelConnection'
environment = require './environment'
server = require './server/server'


startEverything = () ->
	environment.setup context
	serverConfiguration = context.config.server

	if context.config.server.cluster
		createMultipleServers serverConfiguration, modelConnection
	else
		server.start serverConfiguration, modelConnection


createMultipleServers = (serverConfiguration, modelConnection) ->
	if cluster.isMaster
		numCpus = os.cpus().length
		cluster.fork() for num in [0...numCpus]
	else
		server.start serverConfiguration, modelConnection


startEverything()