fs = require 'fs'

Logger = require 'koality-logger'
ModelConnection = require 'koality-model-connection'

environment = require './environment'

CommandLineParser = require './commandLineParser'
Mailer = require './mailer/mailer'
Server = require './server/server'


startEverything = () ->
	process.title = 'webserver'

	commandLineParser = CommandLineParser.create()

	configurationParams = getConfiguration commandLineParser.getConfigFile(),
		commandLineParser.getMode(), commandLineParser.getHttpsPort()

	environment.setEnvironmentMode configurationParams.mode

	domainRetriever = getDomain: (callback) -> callback ''

	mailer = Mailer.create configurationParams.mailer, domainRetriever

	logger = Logger.create mailer.logger, 'warn'

	modelConnection = ModelConnection.create configurationParams.modelConnection.messageBroker, 
		configurationParams.modelConnection.rpc,
		configurationParams.modelConnection.events,
		logger

	if process.env.NODE_ENV is 'production'
		process.on 'uncaughtException', (error) -> logger.error error

	modelConnection.connect (error) ->
		if error?
			logger.fatal error
		else
			domainRetriever.getDomain = (callback) ->
				modelConnection.rpcConnection.systemSettings.read.get_website_domain_name 1, callback

			server = Server.create configurationParams.server, modelConnection, mailer, logger
			server.initialize (error) =>
				if error? then logger.fatal error
				else server.start()


getConfiguration = (configFileLocation = './config.json', mode, httpsPort) ->
	config = JSON.parse(fs.readFileSync configFileLocation, 'ascii')
	if mode? then config.mode = mode
	if httpsPort? then config.server.https.port = httpsPort
	return Object.freeze config


startEverything()
