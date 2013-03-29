assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new SystemSettingsUpdateHandler modelRpcConnection


class SystemSettingsUpdateHandler extends Handler
	setWebsiteSettings: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.domainName?
			callback 400
		else
			@modelRpcConnection.systemSettings.update.set_website_domain_name userId, data.domainName, (error) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback()


	setAwsKeys: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.accessKey? or not data?.secretKey?
			callback 400
		else
			@modelRpcConnection.systemSettings.update.set_aws_keys userId, data.accessKey, data.secretKey, (error) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback()


	setInstanceSettings: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.instanceSize? or not data?.numWaiting? or not data?.maxRunning?
			callback 400
		else
			@modelRpcConnection.systemSettings.update.set_instance_settings userId, data.instanceSize, data.numWaiting, data.maxRunning, (error) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback()
