assert = require 'assert'
commander = require 'commander'


exports.create = () ->
	commandLineParser = new CommandLineParser
	commandLineParser.initialize()
	return commandLineParser


class CommandLineParser
	constructor: () ->

	initialize: () =>
		commander.version('0.1.0')
			.option('--httpPort <n>', 'The http port to use', parseInt)
			.option('--httpsPort <n>', 'The https port to use', parseInt)
			.option('--configFile <file>', 'The configuration file to use')
			.parse(process.argv)


	getHttpPort: () =>
		return commander.httpPort


	getHttpsPort: () =>
		return commander.httpsPort


	getConfigFile: () =>
		return commander.configFile
