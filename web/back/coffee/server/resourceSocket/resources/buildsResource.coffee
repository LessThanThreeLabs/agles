assert = require 'assert'

Resource = require './resource'


exports.create = (modelConnection) ->
	return new BuildsResource modelConnection


class BuildsResource extends Resource
	read: (session, data, callback) ->
		assert.ok callback?
		console.log 'looking for build id: ' + data.id
		
		callback null,
			id: data.id
			number: 17
			owner: 'Jordan Potter'
			progress: '52'
			success: false
