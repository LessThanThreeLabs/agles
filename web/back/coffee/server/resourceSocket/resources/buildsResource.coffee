assert = require 'assert'

Resource = require './resource'


exports.create = (modelRpcConnection) ->
	return new BuildsResource modelRpcConnection


class BuildsResource extends Resource
	read: (socket, data, callback) ->
		if data.id?
			callabck 'Havent implemented this read yet...'
			# @modelRpcConnection.getBuild socket.session.user, data.repositoryId, data.id, callback
		else if data.range? and data.repositoryId? and data.type? and data.queryString?
			numberOffset = Math.floor Math.random() * 10000
			fakeBuilds = (createFakeBuild data.repositoryId, number, numberOffset for number in [data.range.start...data.range.end])
			setTimeout (() => callback null, fakeBuilds), 1000
			# @modelRpcConnection.builds.read.get socket.session.user, data.repositoryId,
			# 	data.range.start, data.range.end, callback
		else
			callback 'Parsing error'



createFakeBuild = (repositoryId, number, numberOffset) ->
	fakeBuild =
		id: Math.floor Math.random() * 100000
		repositoryId: repositoryId
		number: number + numberOffset
		status: getRandomStatus()
		startTime: 'second breakfast'
		endTime: 'pumping in da club'


getRandomStatus = () ->
	return if Math.random() > .35 then 'success' else 'failed'
