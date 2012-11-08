assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new BuildsReadHandler modelRpcConnection


class BuildsReadHandler extends Handler
	default: (socket, data, callback) =>
		assert.ok data.id?
		callback 'havent implemented this yet'


	range: (socket, args, callback) =>
		#assert.ok args.repositoryId? and args.type? and args.startIndexInclusive? and args.endIndexExclusive?
		if args.id?
			callback 'Havent implemented this read yet...'
			# @modelConnection.rpcConnection.getBuild socket.session.user, data.repositoryId, data.id, callback
		else if args.range? and args.repositoryId? and args.type? and args.queryString?
			numberOffset = Math.floor Math.random() * 10000
			fakeBuilds = (createFakeBuild args.repositoryId, number, numberOffset for number in [args.range.start...args.range.end])
			callback null, fakeBuilds
			# @modelConnection.rpcConnection.builds.read.get socket.session.user, data.repositoryId,
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