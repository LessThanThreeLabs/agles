assert = require 'assert'

Resource = require './resource'


exports.create = (modelConnection) ->
	return new BuildsResource modelConnection


class BuildsResource extends Resource
	read: (socket, data, callback) ->
		if data.id?
			@modelConnection.getBuild socket.session.user, data.repositoryId, data.id, callback
		else if data.range?
			@modelConnection.getBuilds socket.session.user, data.repositoryId, 
				data.range.start, data.range.end, callback
		else
			callback 'Parsing error'
