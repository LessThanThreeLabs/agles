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
		assert.ok socket.session.userId? and args.repoId? and args.start? and args.numResults? and args.queryString?
		userId = socket.session.userId
		@modelRpcConnection.builds.read.query_builds userId, args.repoId, 
				args.queryString, args.start, args.numResults, (error, builds) =>
					if error?
						callback "Couldn't query for builds"
					else
						callback null, builds
