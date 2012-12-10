assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new ChangesReadHandler modelRpcConnection


class ChangesReadHandler extends Handler

	default: (socket, data, callback) =>
		assert.ok socket.session.userId?
		assert.ok data.id?
		userId = socket.session.userId

		if not userId?
			callback 403
			return

		@modelRpcConnection.changes.read.get_visible_change_from_id userId, data.id, (error, changeData) =>
			if error?
				if error.type is 'InvalidPermissionsError' then callback 403
				else callback 'unable to read change'
			else
				callback null, @_sanitizeChange changeData


	range: (socket, args, callback) =>
		assert.ok args.repositoryId?
		assert.ok args.start?
		assert.ok args.numResults?
		assert.ok args.queryString?
		userId = socket.session.userId

		if not userId?
			callback 403
			return

		@modelRpcConnection.changes.read.query_changes userId, args.repositoryId,
				args.queryString, args.start, args.numResults, (error, changes) =>
					if error?
						if error.type is 'InvalidPermissionsError' then callback 403
						else callback 'unable to get changes'
					else
						sanitizedChanges = (@_sanitizeChange change, args.repositoryId for change in changes)
						callback null, sanitizedChanges


	_sanitizeChange: (change, repositoryId) =>
		id: change.id
		repositoryId: repositoryId
		number: change.number
		status: change.status
		startTime: change.start_time
		endTime: change.end_time


	_sanitizeBuild: (build) =>
		id: build.id
		status: build.status
		changeId: build.change_id
		isPrimary: build.is_primary
		startTime: build.start_time
		endTime: build.end_time
