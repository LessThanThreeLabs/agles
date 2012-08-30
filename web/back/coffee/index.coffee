profiler = require('nodetime').profile
	accountKey: 'e32c83cafbf931d5e47aca4c66f34bc7b36701f3'
	appName: 'Less Than Three'

os = require 'os'
cluster = require 'cluster'
environment = require './environment'
server = require './server/server'

Configuration = require './configuration'
ModelConnection = require './modelConnection'


startEverything = () ->
	configuration = Configuration.create './config.json'
	environment.setupEnvironment configuration.getMode()
	modelConnection = ModelConnection.create configuration.getModelConfiguration()

	if configuration.getServerConfiguration().cluster
		createMultipleServers configuration.getServerConfiguration(), modelConnection
	else
		server.start configuration.getServerConfiguration(), modelConnection


createMultipleServers = (serverConfiguration, modelConnection) ->
	if cluster.isMaster
		numCpus = os.cpus().length
		cluster.fork() for num in [0...numCpus]
	else
		server.start serverConfiguration, modelConnection


startEverything()