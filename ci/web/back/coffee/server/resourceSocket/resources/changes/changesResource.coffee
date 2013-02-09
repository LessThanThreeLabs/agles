assert = require 'assert'

Resource = require '../resource'
ChangesReadHandler = require './handlers/changesReadHandler'


exports.create = (configurationParams, stores, modelConnection) ->
	readHandler = ChangesReadHandler.create modelConnection.rpcConnection
	return new ChangesResource configurationParams, stores, modelConnection, readHandler


class ChangesResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @readHandler) ->
		super configurationParams, stores, modelConnection
		assert.ok @readHandler


	read: (socket, data, callback) =>
		@_call @readHandler, socket, data, callback


	subscribe: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		if typeof data.method isnt 'string' or typeof data.args?.id isnt 'number'
			callback 400
		else
			console.log 'need to make sure this user is allowed to receive updates for id ' + data.args.id
			eventName = @modelConnection.eventConnection.changes.registerForEvents socket, data.args.id, data.method
			if eventName? then callback null, eventName
			else callback 400


	unsubscribe: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		if typeof data.method isnt 'string' or typeof data.args?.id isnt 'number'
			callback 400
		else
			success = @modelConnection.eventConnection.changes.unregisterForEvents socket, data.args.id, data.method
			if success then callback()
			else callback 400
