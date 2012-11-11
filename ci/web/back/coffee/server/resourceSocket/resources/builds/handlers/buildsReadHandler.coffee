assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new BuildsReadHandler modelRpcConnection


class BuildsReadHandler extends Handler
	default: (socket, data, callback) =>
		assert.ok socket.session.userId? and data.buildId?
		userId = socket.session.userId
		console.log 'feh'
		buildData = @modelRpcConnection.builds.read.get_build_from_id userId, data.buildId
		callback null, buildData


	range: (socket, args, callback) =>
		assert.ok socket.session.userId? and args.repoId? and args.type? and args.startIndexInclusive? and args.endIndexExclusive? and args.queryString?
		userId = socket.session.userId
		console.log "feh2"
		builds = @modelRpcConnection.builds.read.get_builds_in_range userId, args.repoId,
				args.type, args.startIndexInclusive, args.endIndexExclusive, args.queryString
		callback null, builds
