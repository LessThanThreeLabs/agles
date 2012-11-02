assert = require 'assert'
commander = require 'commander'


exports.create = (configurationParams) ->
	commandLineParser = new CommandLineParser configurationParams
	commandLineParser.initialize()
	return commandLineParser


class CommandLineParser
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	initialize: () =>
		commander.version('0.1.0')
			.option('--httpPort <n>', 'The http port to use', parseInt)
			.option('--httpsPort <n>', 'The https port to use', parseInt)
			.parse(process.argv)


	getHttpPort: () =>
		return commander.httpPort


	getHttpsPort: () =>
		return commander.httpsPort