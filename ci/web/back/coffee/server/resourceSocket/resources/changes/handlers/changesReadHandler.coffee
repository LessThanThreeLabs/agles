assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new ChangesReadHandler modelRpcConnection


class ChangesReadHandler extends Handler
	getChanges: (socket, data, callback) =>
		sanitizeResult = (change) ->
			id: change.id
			number: change.number
			status: change.status
 		
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.repositoryId? or not data.group? or not data.query? or not data.startIndex? or not data.numToRetrieve?
			callback 400
		else
			@modelRpcConnection.changes.read.query_changes userId, data.repositoryId, 
				data.group, data.query, data.startIndex, data.numToRetrieve, (error, changes) =>
					if error?.type is 'InvalidPermissionsError' then callback 403
					else if error? then callback 500
					else callback null, (sanitizeResult change for change in changes)


	getMetadata: (socket, data, callback) =>
		sanitizeResult = (metadata) ->
			user: 
				email: metadata.user.email
				firstName: metadata.user.first_name
				lastName: metadata.user.last_name
			message: metadata.commit.message
			commitTime: metadata.commit.timestamp
			startTime: metadata.change.start_time
			endTime: metadata.change.end_time
			target: metadata.change.merge_target

		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.id?
			callback 400
		else
			@modelRpcConnection.changes.read.get_change_metadata userId, data.id, (error, metadata) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, sanitizeResult metadata
