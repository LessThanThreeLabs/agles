assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new RepositoriesUpdateHandler modelRpcConnection


class RepositoriesUpdateHandler extends Handler
	inviteMembers: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data.repositoryId? or not data.emails?
			callback 400
		else
			callback 'IMPLEMENT THIS!!'


	changeMemberPermissions: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data.repositoryId? or not data.email? or not data.permissions?
			callback 400
		else
			callback 'IMPLEMENT THIS!!'


	removeMember: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data.repositoryId? or not data.userId?
			callback 400
		else
			callback 'IMPLEMENT THIS!!'


	updateForwardUrl: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data.repositoryId? or not data.forwardUrl?
			callback 400
		else
			callback 'IMPLEMENT THIS!!'
