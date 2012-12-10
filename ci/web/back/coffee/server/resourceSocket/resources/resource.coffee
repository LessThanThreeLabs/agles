assert = require 'assert'


module.exports = class Resource
	constructor: (@configurationParams, @stores, @modelConnection) ->
		assert.ok @configurationParams? and @stores? and @modelConnection?


	create: (socket, data, callback) ->
		callback 'create not written yet' if callback?


	read: (socket, data, callback) ->
		callback 'read not written yet' if callback?


	update: (socket, data, callback) ->
		callback 'update not written yet' if callback?


	delete: (socket, data, callback) ->
		callback 'delete not written yet' if callback?


	subscribe: (socket, data, callback) ->
		callback 'subscribe not written yet' if callback?


	unsubscribe: (socket, data, callback) ->
		callback 'unsubscribe not written yet' if callback?


	_call: (handler, socket, data, callback) ->
		assert.ok data?
		if data.method? and data.args?
			if typeof handler[data.method] is 'function'
				handler[data.method] socket, data.args, callback
			else
				callback 'Class #{handler} has no method #{data.method}'
		else
			handler.default socket, data, callback

