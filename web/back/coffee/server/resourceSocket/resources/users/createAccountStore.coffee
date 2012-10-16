assert = require 'assert'
redis = require 'redis'


exports.create = (configurationParams) ->
	return new CreateAccountStore configurationParams


class CreateAccountStore
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?
