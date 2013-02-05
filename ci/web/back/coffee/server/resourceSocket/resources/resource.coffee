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
		if not data?
			callback 400
		else if data.method.indexOf '_' is 0
			callback 404
		else if typeof handler[data.method] isnt 'function'
			callback 404
		else
			handler[data.method] socket, data.args, callback
