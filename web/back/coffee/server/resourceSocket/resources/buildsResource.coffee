assert = require 'assert'

Resource = require './resource'


exports.create = (modelRpcConnection) ->
	return new BuildsResource modelRpcConnection


class BuildsResource extends Resource
	read: (socket, data, callback) ->
		if data.id?
			callabck 'Havent implemented this read yet...'
			# @modelRpcConnection.getBuild socket.session.user, data.repositoryId, data.id, callback
		else if data.range? and data.repositoryId?
			fakeBuilds = (createFakeBuild data.repositoryId, number for number in [data.range.start...data.range.end])
			callback null, fakeBuilds
			# @modelRpcConnection.builds.read.get socket.session.user, data.repositoryId,
			# 	data.range.start, data.range.end, callback
		else
			callback 'Parsing error'



createFakeBuild = (repositoryId, number) ->
	fakeBuild =
		id: Math.floor Math.random() * 100000
		repositoryId: repositoryId
		number: number
		status: 'single'
		startTime: 'second breakfast'
		endTime: 'pumping in da club'
		