assert = require 'assert'

Handler = require '../../handler'


exports.create = (configurationParams, modelRpcConnection) ->
	return new RepositoriesReadHandler configurationParams, modelRpcConnection


class RepositoriesReadHandler extends Handler
	constructor: (@configurationParams, modelRpcConnection) ->
		assert.ok @configurationParams?
		super modelRpcConnection
