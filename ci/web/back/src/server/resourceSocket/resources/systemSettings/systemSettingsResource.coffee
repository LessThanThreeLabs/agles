assert = require 'assert'

Resource = require '../resource'
SystemSettingsInformationValidator = require './systemSettingsInformationValidator'

SystemSettingsReadHandler = require './handlers/systemSettingsReadHandler'
SystemSettingsUpdateHandler = require './handlers/systemSettingsUpdateHandler'


exports.create = (configurationParams, stores, modelConnection, mailer) ->
	systemSettingsInformationValidator = SystemSettingsInformationValidator.create()

	readHandler = SystemSettingsReadHandler.create modelConnection.rpcConnection
	updateHandler = SystemSettingsUpdateHandler.create modelConnection.rpcConnection, systemSettingsInformationValidator
	return new SystemSettingsResource configurationParams, stores, modelConnection, readHandler, updateHandler


class SystemSettingsResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @readHandler, @updateHandler) ->
		super configurationParams, stores, modelConnection
		assert.ok @readHandler
		assert.ok @updateHandler?


	read: (socket, data, callback) =>
		@_call @readHandler, socket, data, callback


	update: (socket, data, callback) =>
		@_call @updateHandler, socket, data, callback


	subscribe: (socket, data, callback) =>
		callback 403
		

	unsubscribe: (socket, data, callback) =>
		callback 403
