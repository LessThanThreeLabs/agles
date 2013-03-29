assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new ChangesReadHandler modelRpcConnection


class ChangesReadHandler extends Handler
	getChanges: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.repositoryId? or not data?.startIndex? or not data?.numToRetrieve?
			callback 400
		else
			if data?.group? and data?.names?
				callback 400
			else if data?.group?
				@_getGroupChanges userId, data, callback
			else if data?.names?
				@_getNameSearchChanges userId, data, callback
			else
				callback 400


	_sanitizeChange: (change) =>
		id: change.id
		number: change.number
		status: change.status
		mergeStatus: change.merge_status
		createTime: change.create_time * 1000
		startTime: change.start_time * 1000
		endTime: change.end_time * 1000


	_getGroupChanges: (userId, data, callback) =>
		if not data.group? or typeof data.group isnt 'string'
			callback 400
		else
			@modelRpcConnection.changes.read.query_changes_group userId, data.repositoryId, data.group, data.startIndex, data.numToRetrieve, (error, changes) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, (@_sanitizeChange change for change in changes)


	_getNameSearchChanges: (userId, data, callback) =>
		if not data.names? or typeof data.names isnt 'object'
			callback 400
		else
			@modelRpcConnection.changes.read.query_changes_filter userId, data.repositoryId, data.names, data.startIndex, data.numToRetrieve, (error, changes) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, (@_sanitizeChange change for change in changes)


	getMetadata: (socket, data, callback) =>
		sanitizeResult = (metadata) ->
			number: metadata.change.number
			status: metadata.change.status
			user:
				email: metadata.user.email
				firstName: metadata.user.first_name
				lastName: metadata.user.last_name
			headCommit:
				message: metadata.commit.message
				sha: metadata.commit.sha
			createTime: metadata.change.create_time * 1000
			startTime: metadata.change.start_time * 1000
			endTime: metadata.change.end_time * 1000
			target: metadata.change.merge_target
			mergeStatus: metadata.change.merge_status

		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.id? or not data?.repositoryId?
			callback 400
		else
			@modelRpcConnection.changes.read.get_change_metadata userId, data.id, (error, metadata) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else if data.repositoryId isnt metadata?.change?.repo_id then callback 403
				else callback null, sanitizeResult metadata


	getChangesFromTimestamp: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.repositories? or not data?.timestamp?
			callback 400
		else
			@modelRpcConnection.changes.read.get_changes_from_timestamp userId, data.repositories, Math.floor(data.timestamp/1000), (error, changes) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, (@_sanitizeChange change for change in changes)
