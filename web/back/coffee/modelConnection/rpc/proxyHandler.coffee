assert = require 'assert'


exports.create = (configurationParams) ->
	return new ProxyHandler configurationParams


class ProxyHandler
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	get: (object, name) ->
		return 'hello'
