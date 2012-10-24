fs = require 'fs'


exports.getConfigurationParams = (configurationLocation, encoding = 'ascii') ->
	return JSON.parse(fs.readFileSync configurationLocation, encoding)
