assert = require 'assert'

Resource = require '../resource'


exports.create = (configurationParams, stores, modelConnection) ->
	return new RepositoriesResource configurationParams, stores, modelConnection


class RepositoriesResource extends Resource
	@allowedSubscriptionTypes = ['general', 'builds']

	read: (socket, data, callback) ->
		fakeRepository =
			id: data.id
			name: 'Agles CI'
			description: 'Dedicated to saving the world, one ci at a time.'
			url: 'https://agles.blimp.com/awesome.git'
		callback null, fakeRepository


	subscribe: (socket, data, callback) ->
		console.log 'need to check that the user is allowed to register for these events...'
		@modelConnection.eventConnection.repositories.registerForEvents socket, data.id
		callback null, 'Ok'
		