assert = require 'assert'

MessageIdGenerator = require './messageIdGenerator'
RpcBroker = require './rpcBroker'
RpcHandler = require './rpcHandler'
RpcHandlerFunctionProxy = require './rpcHandlerFunctionProxy'


exports.create = (configurationParams, connection) ->
	return new RpcConnection configurationParams, connection


class RpcConnection
	constructor: (@configurationParams, @connection) ->
		assert.ok @connection? and @configurationParams?
		@messageIdGenerator = MessageIdGenerator.create()


	connect: (callback) ->
		await
			@connection.exchange @configurationParams.rpc.exchange, type: 'direct', defer @exchange
			@connection.exchange @configurationParams.rpc.deadLetter.exchange, type: 'fanout', defer @deadLetterExchange

		@rpcBroker = RpcBroker.create @connection, @exchange, @deadLetterExchange, @messageIdGenerator
		@rpcBroker.connect (error) =>
			if error? then callback error else @_createNounHandles callback


	_createNounHandles: (callback) ->
		for noun in ['users', 'organizations', 'builds', 'repositories']
			@[noun] = {}
			@_createVerbHandles noun

		callback null


	_createVerbHandles: (noun) ->
		for verb in ['create', 'read', 'update', 'delete']
			route = noun + '-' + verb
			handler = RpcHandler.create route, @rpcBroker
			@[noun][verb] = RpcHandlerFunctionProxy.create handler
