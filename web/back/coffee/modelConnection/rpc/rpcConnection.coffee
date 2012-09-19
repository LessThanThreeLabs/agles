assert = require 'assert'

MessageIdGenerator = require './messageIdGenerator'
RpcHandler = require './rpcHandler'
RpcHandlerFunctionProxy = require './rpcHandlerFunctionProxy'


exports.create = (configurationParams, connection) ->
	return new RpcConnection configurationParams, connection


class RpcConnection
	constructor: (@configurationParams, @connection) ->
		assert.ok @connection? and @configurationParams?
		@messageIdGenerator = MessageIdGenerator.create()


	connect: (callback) ->
		@connection.exchange @configurationParams.rpc.exchange, {}, (exchange) =>
			@exchange = exchange
			@_createHandles callback


	_createHandles: (callback) ->
		await
			errors = {}

			usersHandler = RpcHandler.create @connection, @exchange, 'users', @messageIdGenerator
			@users = RpcHandlerFunctionProxy.create(usersHandler).getProxy()
			usersHandler.connect defer errors.users

			buildsHandler = RpcHandler.create @connection, @exchange, 'builds', @messageIdGenerator
			@builds = RpcHandlerFunctionProxy.create(buildsHandler).getProxy()
			buildsHandler.connect defer errors.builds

		errorsArray = (error for key, error of errors when error?)
		callback if errorsArray.length then errorsArray else null
