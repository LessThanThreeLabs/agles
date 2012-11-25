assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new BuildsReadHandler modelRpcConnection


class BuildsReadHandler extends Handler

	# -- GIVEN --
	# data =
	#   id: <integer>
	# -- RETURNED --
	# result =
	#    EVERYTHING for now...
	default: (socket, data, callback) =>
		assert.ok socket.session.userId? and data.id?
		userId = socket.session.userId
		@modelRpcConnection.builds.read.get_visible_build_from_id userId, data.id, (error, buildData) =>
			if error?
				callback "Cannot locate build"
			else
				callback null, buildData


	# -- GIVEN --
	# data =
	#   repositoryId: <integer>
	#   queryString: <string>
	#   start: <integer>
	#   numResults: <integer>
	# -- RETURNED --
	# result = [<buildObjects>, ...]
	range: (socket, args, callback) =>
		assert.ok args.repositoryId? and args.start? and args.numResults? and args.queryString?
		userId = socket.session.userId
		if not userId?
			callback '404'
			return
			
		@modelRpcConnection.builds.read.query_builds userId, args.repositoryId, 
				args.queryString, args.start, args.numResults, (error, builds) =>
					if error?
						callback "Couldn't query for builds"
					else
						sanitizedBuilds = (@_sanitize build, args.repositoryId for build in builds)
						callback null, sanitizedBuilds


	_sanitize: (build, repositoryId) =>
		id: build.id
		repositoryId: repositoryId
		number: build.id
		status: build.status
		startTime: build.start_time
		endTime: build.end_time
		