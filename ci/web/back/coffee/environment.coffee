assert = require 'assert'


exports.setEnvironmentMode = (mode) ->
	assert.ok mode == 'development' or mode == 'production'
	process.env.NODE_ENV = mode