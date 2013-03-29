assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new SystemSettingsReadHandler modelRpcConnection


class SystemSettingsReadHandler extends Handler
	getWebsiteSettings: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else
			@modelRpcConnection.systemSettings.read.get_website_domain_name userId, (error, websiteDomain) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, domainName: websiteDomain


	getAwsKeys: (socket, data, callback) =>
		sanitizeResult = (awsKeys) ->
			accessKey: awsKeys.access_key
			secretKey: awsKeys.secret_key

		userId = socket.session.userId
		if not userId?
			callback 403
		else
			@modelRpcConnection.systemSettings.read.get_aws_keys userId, (error, awsKeys) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, sanitizeResult awsKeys


	getAllowedInstanceSizes: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else
			@modelRpcConnection.systemSettings.read.get_allowed_instance_sizes userId, (error, allowedInstanceSizes) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, allowedInstanceSizes


	getInstanceSettings: (socket, data, callback) =>
		sanitizeResult = (instanceSettings) ->
			instanceSize: instanceSettings.instance_size
			numWaiting: instanceSettings.num_waiting
			maxRunning: instanceSettings.max_running

		userId = socket.session.userId
		if not userId?
			callback 403
		else
			@modelRpcConnection.systemSettings.read.get_instance_settings userId, (error, instanceSettings) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, sanitizeResult instanceSettings