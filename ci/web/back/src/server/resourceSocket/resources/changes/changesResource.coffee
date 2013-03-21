assert = require 'assert'

Resource = require '../resource'
ChangesReadHandler = require './handlers/changesReadHandler'


exports.create = (configurationParams, stores, modelConnection, mailer) ->
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
			@modelConnection.rpcConnection.changes.read.can_hear_change_events userId, data.args.id, (error, permitted) =>
				if error? or not permitted then callback 403
				else
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
