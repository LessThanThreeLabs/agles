ssert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new RepositoriesReadHandler modelRpcConnection


class RepositoriesReadHandler extends Handler
	default: (socket, data, callback) =>
		fakeRepository =
			id: data.id
			name: 'Agles CI'
			description: 'Dedicated to saving the world, one ci at a time.'
			url: 'https://agles.blimp.com/awesome.git'
		callback null, fakeRepository
		