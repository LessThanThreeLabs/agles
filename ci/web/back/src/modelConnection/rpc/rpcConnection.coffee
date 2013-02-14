assert = require 'assert'

MessageIdGenerator = require './messageIdGenerator'
RpcBroker = require './rpcBroker'
RpcHandler = require './rpcHandler'
RpcHandlerFunctionProxy = require './rpcHandlerFunctionProxy'


exports.create = (configurationParams, connection) ->
	return new RpcConnection configurationParams, connection


class RpcConnection
	NOUNS: [
		{localName: 'users', 			rpcName: 'rpc:users'}
		{localName: 'organizations', 	rpcName: 'rpc:organizations'}
		{localName: 'builds', 			rpcName: 'rpc:builds'}
		{localName: 'repos',		 	rpcName: 'rpc:repos'}
		{localName: 'buildConsoles', 	rpcName: 'rpc:build_consoles'} 
		{localName: 'changes', 			rpcName: 'rpc:changes'}
	]

	VERBS: ['create', 'read', 'update', 'delete']

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
		for noun in @NOUNS
			@[noun.localName] = {}
			@_createVerbHandles noun

		callback null


	_createVerbHandles: (noun) ->
		for verb in @VERBS
			route = noun.rpcName + '.' + verb
			handler = RpcHandler.create route, @rpcBroker
			@[noun.localName][verb] = RpcHandlerFunctionProxy.create handler