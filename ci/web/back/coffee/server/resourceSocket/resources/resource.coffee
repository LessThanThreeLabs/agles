assert = require 'assert'


module.exports = class Resource
	constructor: (@configurationParams, @stores, @modelConnection) ->
		assert.ok @configurationParams?
		assert.ok @stores?
		assert.ok @modelConnection?


	create: (socket, data, callback) ->
		callback 404


	read: (socket, data, callback) ->
		callback 404


	update: (socket, data, callback) ->
		callback 404


	delete: (socket, data, callback) ->
		callback 404


	subscribe: (socket, data, callback) ->
		callback 404


	unsubscribe: (socket, data, callback) ->
		callback 404


	_call: (handler, socket, data, callback) ->
		if not data? or typeof data.method isnt 'string'
			callback 400
		else if data.method[0] is '-'
			callback 404
		else if typeof handler[data.method] isnt 'function'
			callback 404
		else
			handler[data.method] socket, data.args, callback
