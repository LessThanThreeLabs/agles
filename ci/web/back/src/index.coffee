fs = require 'fs'
colors = require 'colors'
Logger = require 'koality-logger'

environment = require './environment'

CommandLineParser = require './commandLineParser'
Mailer = require './mailer/mailer'
ModelConnection = require './modelConnection/modelConnection'
Server = require './server/server'


startEverything = () ->
	process.title = 'webserver'

	commandLineParser = CommandLineParser.create()

	configurationParams = getConfiguration commandLineParser.getConfigFile(),
		commandLineParser.getMode(), commandLineParser.getHttpsPort()

	environment.setEnvironmentMode configurationParams.mode

	modelConnection = ModelConnection.create configurationParams.modelConnection
	modelConnection.connect (error) =>
		throw error if error?
		mailer = Mailer.create configurationParams.mailer, modelConnection.rpcConnection
		logger = Logger.create mailer.logger, 'warn'
		createServer configurationParams.server, modelConnection, mailer, logger

		if process.env.NODE_ENV is 'production'
			process.on 'uncaughtException', (error) =>
				logger.error error


getConfiguration = (configFileLocation = './config.json', mode, httpsPort) =>
	config = JSON.parse(fs.readFileSync configFileLocation, 'ascii')
	if mode? then config.mode = mode
	if httpsPort? then config.server.https.port = httpsPort
	return Object.freeze config


createServer = (serverConfigurationParams, domainName, modelConnection, mailer) =>
	server = Server.create serverConfigurationParams, domainName, modelConnection, mailer
	server.initialize (error) =>
		throw error if error?
		server.start()


startEverything()
