assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new ChangesReadHandler modelRpcConnection


class ChangesReadHandler extends Handler
	setWebsiteSettings: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.domainName?
			callback 400
		else
			@modelRpcConnection.systemSettings.update.set_website_domain userId, websiteDomain (error, result) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, result


	setAwsKeys: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.accessKey? or not data?.secretKey?
			callback 400
		else
			@modelRpcConnection.systemSettings.update.set_aws_keys userId, data.accessKey, data.secretKey, (error, result) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, result


	setInstanceSettings: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.instanceSize? or not data?.numWaiting? or not data?.maxRunning?
			callback 400
		else
			@modelRpcConnection.systemSettings.update.set_instance_settings userId, data.instanceSize, data.numWaiting, data.maxRunning, (error, result) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, result
