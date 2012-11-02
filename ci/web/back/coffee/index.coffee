profiler = require 'nodetime'
configuration = require('./configuration')
environment = require('./environment')

CommandLineParser = require './commandLineParser'
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
	commandLineParser = CommandLineParser.create serverConfigurationParams

	httpPort = commandLineParser.getHttpPort() ? serverConfigurationParams.http.defaultPort
	redirectServer = RedirectServer.create httpPort
	redirectServer.start()

	httpsPort = commandLineParser.getHttpsPort() ? serverConfigurationParams.https.defaultPort
	server = Server.create serverConfigurationParams, modelConnection, httpsPort
	server.start()


startEverything()
