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
