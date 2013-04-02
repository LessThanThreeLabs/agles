assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection, systemSettingsInformationValidator) ->
	return new SystemSettingsUpdateHandler modelRpcConnection, systemSettingsInformationValidator


class SystemSettingsUpdateHandler extends Handler
	constructor: (modelRpcConnection, @systemSettingsInformationValidator) ->
		super modelRpcConnection
		assert.ok @systemSettingsInformationValidator?


	setWebsiteSettings: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.domainName?
			callback 400
		else
			errors = {}
			if not @systemSettingsInformationValidator.isValidDomainName data.domainName
				errors.domainName = @systemSettingsInformationValidator.getInvalidDomainNameString()

			if Object.keys(errors).length isnt 0
				callback errors
				return

			@modelRpcConnection.systemSettings.update.set_website_domain_name userId, data.domainName, (error) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback()


	setAwsKeys: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.awsId? or not data?.awsSecret?
			callback 400
		else
			errors = {}
			if not @systemSettingsInformationValidator.isValidAwsId data.awsId
				errors.domainName = @systemSettingsInformationValidator.getInvalidAwsIdString()
			if not @systemSettingsInformationValidator.isValidAwsSecret data.awsSecret
				errors.domainName = @systemSettingsInformationValidator.getInvalidAwsSecretString()

			if Object.keys(errors).length isnt 0
				callback errors
				return

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
			errors = {}
			if not @systemSettingsInformationValidator.isValidNumWaitingInstances data.numWaiting
				errors.domainName = @systemSettingsInformationValidator.getInvalidNumWaitingInstancesString()
			if not @systemSettingsInformationValidator.isValidMaxRunningInstances data.maxRunning
				errors.domainName = @systemSettingsInformationValidator.getInvalidMaxRunningInstancesString()

			if Object.keys(errors).length isnt 0
				callback errors
				return

			@modelRpcConnection.systemSettings.update.set_instance_settings userId, data.instanceSize, data.numWaiting, data.maxRunning, (error) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback()
