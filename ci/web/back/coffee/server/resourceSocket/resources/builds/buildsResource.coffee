assert = require 'assert'

Resource = require '../resource'

BuildsReadHandler = require './handlers/buildsReadHandler'

exports.create = (configurationParams, stores, modelConnection) ->
	readHandler = BuildsReadHandler.create modelConnection.rpcConnection
	return new BuildsResource configurationParams, stores, modelConnection, readHandler


class BuildsResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @readHandler) ->
		super configurationParams, stores, modelConnection


	read: (socket, data, callback) =>
		@_call @readHandler, socket, data, callback

	###	if data.id?
			callabck 'Havent implemented this read yet...'
			# @modelConnection.rpcConnection.getBuild socket.session.user, data.repositoryId, data.id, callback
		else if data.range? and data.repositoryId? and data.type? and data.queryString?
			numberOffset = Math.floor Math.random() * 10000
			fakeBuilds = (createFakeBuild data.repositoryId, number, numberOffset for number in [data.range.start...data.range.end])
			callback null, fakeBuilds
			# @modelConnection.rpcConnection.builds.read.get socket.session.user, data.repositoryId,
			# 	data.range.start, data.range.end, callback
		else
			callback 'Parsing error'
###


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
