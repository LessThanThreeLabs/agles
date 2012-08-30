fs = require 'fs'


configuration = JSON.parse(fs.readFileSync './config.json', 'ascii')

for param of configuration
	exports[param] = configuration[param]
	