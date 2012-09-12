assert = require 'assert'

Resource = require './resource'


exports.create = (modelConnection) ->
	return new BuildsResource modelConnection


class BuildsResource extends Resource
	read: (session, data, callback) ->
		if data.id?
			@modelConnection.getBuild session.user, data.repositoryId, data.id, callback
		else if data.range?
			@modelConnection.getBuilds session.user, data.repositoryId, 
				data.range.start, data.range.end, callback
		else
			callback 'Parsing error'
