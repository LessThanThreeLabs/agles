assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new ChangesReadHandler modelRpcConnection


class ChangesReadHandler extends Handler

	default: (socket, data, callback) =>
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
						sanitizedChanges = (@_sanitizeChange change for change in changes)
						callback null, sanitizedChanges


	getChangeMetadata: (socket, data, callback) =>
		assert.ok data.id?
		userId = socket.session.userId

		if not userId?
			callback 403
			return
		
		@modelRpcConnection.changes.read.get_change_metadata userId, data.id, (error, metadata) =>
			if error?
				if error.type is 'InvalidPermissionsError' then callback 403
				else callback 'unable to get metadata'
			else
				callback null, @_sanitizeMetadata metadata


	_sanitizeMetadata: (metadata) =>
		change: @_sanitizeChange metadata.change 
		commit: @_sanitizeCommit metadata.commit
		user: @_sanitizeUser metadata.user


	_sanitizeChange: (change) =>
		id: change.id
		mergeTarget: change.merge_target
		repositoryId: change.repo_id
		number: change.number
		status: change.status
		startTime: change.start_time
		endTime: change.end_time


	_sanitizeUser: (user) =>
		id: user.id
		email: user.email
		firstName: user.first_name
		lastName: user.lastName


	_sanitizeCommit: (commit) =>
		id: commit.id
		repositoryId: commit.repo_id
		userId: commit.user_id
		message: commit.message
		timestamp: commit.timestamp


	_sanitizeBuild: (build) =>
		id: build.id
		status: build.status
		changeId: build.change_id
		isPrimary: build.is_primary
		startTime: build.start_time
		endTime: build.end_time
