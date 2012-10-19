assert = require 'assert'

Resource = require '../resource'


exports.create = (configurationParams, stores, modelRpcConnection) ->
	return new RepositoriesResource configurationParams, stores, modelRpcConnection


class RepositoriesResource extends Resource
	@allowedSubscriptionTypes = ['general', 'builds']

	read: (socket, data, callback) ->
		fakeRepository =
			id: data.id
			name: 'Awesome Sauce'
			subname: 'The best repository of all time.  OF ALL TIME!'
		callback null, fakeRepository


	subscribe: (socket, data, callback) ->
		assert.ok data.id? and data.type? and data.type in @allowedSubscriptionTypes
		socket.join 'repositoryId=' + data.id + ' - ' + data.type
		callback null, 'Ok'
		