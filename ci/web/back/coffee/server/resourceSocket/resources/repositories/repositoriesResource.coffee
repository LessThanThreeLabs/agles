assert = require 'assert'

Resource = require '../resource'


exports.create = (configurationParams, stores, modelConnection) ->
	return new RepositoriesResource configurationParams, stores, modelConnection


class RepositoriesResource extends Resource
	@allowedSubscriptionTypes = ['general', 'builds']

	read: (socket, data, callback) ->
		fakeRepository =
			id: data.id
			name: 'Awesome Sauce'
			subname: 'The best repository of all time.  OF ALL TIME!'
		callback null, fakeRepository


	subscribe: (socket, data, callback) ->
		console.log 'need to check that the user is allowed to register for these events...'
		@modelConnection.eventConnection.repositories.registerForEvents socket, data.id
		callback null, 'Ok'
		