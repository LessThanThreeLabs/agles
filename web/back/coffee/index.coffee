profiler = require('nodetime').profile
	accountKey: 'e32c83cafbf931d5e47aca4c66f34bc7b36701f3'
	appName: 'Less Than Three'

os = require 'os'
cluster = require 'cluster'
configuration = require './configuration'
modelConnection = require './modelConnection'
environment = require './environment'
server = require './server/server'


startEverything = () ->
	for key in configuration
		console.log key

	environment.setup configuration
	serverConfiguration = configuration.server

	if serverConfiguration.cluster
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