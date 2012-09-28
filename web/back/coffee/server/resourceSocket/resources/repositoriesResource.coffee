assert = require 'assert'

Resource = require './resource'


exports.create = (modelRpcConnection) ->
	return new RepositoriesResource modelRpcConnection


class RepositoriesResource extends Resource
	@allowedSubscriptionTypes = ['general', 'builds']

	read: (socket, data, callback) ->
		fakeRepository =
			id: data.id
			name: 'Awesome Sauce'
		callback null, fakeRepository


	subscribe: (socket, data, callback) ->
		assert.ok data.id? and data.type? and data.type in @allowedSubscriptionTypes
		socket.join 'repositoryId=' + data.id + ' - ' + data.type
		callback null, 'Ok'
		