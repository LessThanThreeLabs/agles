fs = require 'fs'
# nconf = require 'nconf'

# exports.config = nconf.file 'file': './config.json'
exports.config = JSON.parse(fs.readFileSync './config.json', 'ascii')