os = require 'os'
cluster = require 'cluster'
profiler = require 'nodetime'
configuration = require('./configuration')
environment = require('./environment')

ModelConnection = require './modelConnection/modelConnection'
Server = require './server/server'
RedirectServer = require './server/redirectServer'


startEverything = () ->
	configurationParams = configuration.getConfigurationParams './config.json'
	environment.setEnvironmentMode configurationParams.mode
	startProfiler configurationParams

	modelConnection = ModelConnection.create configurationParams.server

	if configurationParams.server.cluster
		createMultipleServers configurationParams.server, modelConnection
	else
		createServers configurationParams.server, modelConnection


startProfiler = (configurationParams) ->
	profiler.profile
		appName: configurationParams.applicationName
		accountKey: configurationParams.accountKey


createMultipleServers = (serverConfigurationParams, modelConnection) ->
	if cluster.isMaster
		numCpus = os.cpus().length
		cluster.fork() for num in [0...numCpus]
	else
		createServers serverConfigurationParams, modelConnection


createServers = (serverConfigurationParams, modelConnection) ->
	redirectServer = RedirectServer.create serverConfigurationParams
	redirectServer.start()

	server = Server.create serverConfigurationParams, modelConnection
	server.start()


startEverything()
