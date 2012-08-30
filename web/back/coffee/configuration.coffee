fs = require 'fs'


# configuration = JSON.parse(fs.readFileSync './config.json', 'ascii')

# for param of configuration
# 	exports[param] = configuration[param]


exports.create = (configurationLocation) ->
	return new Configuration configurationLocation


class Configuration
	constructor: (configLocation) ->
		@config = JSON.parse(fs.readFileSync configLocation, 'ascii')

	getMode: () ->
		return @config.mode

	getServerConfiguration: () ->
		return @config.server

	getModelConfiguration: () ->
		return @config.model