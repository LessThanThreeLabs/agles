profiler = require 'nodetime'
configuration = require('./configuration')
environment = require('./environment')

ModelConnection = require './modelConnection/modelConnection'
Server = require './server/server'
RedirectServer = require './server/redirectServer'


startEverything = () ->
	configurationParams = configuration.getConfigurationParams './config.json'
	environment.setEnvironmentMode configurationParams.mode
	startProfiler configurationParams.profiler

	modelConnection = ModelConnection.create configurationParams.modelConnection
	modelConnection.connect (error) ->
		throw error if error?
		createServers configurationParams.server, modelConnection


startProfiler = (profilerConfigurationParams) ->
	profiler.profile
		appName: profilerConfigurationParams.applicationName
		accountKey: profilerConfigurationParams.accountKey
		silent: profilerConfigurationParams.silent


createServers = (serverConfigurationParams, modelConnection) ->
	redirectServer = RedirectServer.create serverConfigurationParams.http.defaultPort
	redirectServer.start()

	server = Server.create serverConfigurationParams, modelConnection, serverConfigurationParams.https.defaultPort
	server.start()


startEverything()
