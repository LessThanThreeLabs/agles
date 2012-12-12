assert = require 'assert'


module.exports = class Resource
	constructor: (@configurationParams, @stores, @modelConnection, @filesCache) ->
		assert.ok @configurationParams? and @stores? and @modelConnection? and @filesCache?


	handleRequest: (request, response) ->
		response.send 'response handler not written yet'
