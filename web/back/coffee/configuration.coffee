fs = require 'fs'


configuration = null
module.exports = exports = (configurationLocation) ->
	configuration = JSON.parse(fs.readFileSync './config.json', 'ascii')


for param of configuration
	exports[param] = configuration[param]
	