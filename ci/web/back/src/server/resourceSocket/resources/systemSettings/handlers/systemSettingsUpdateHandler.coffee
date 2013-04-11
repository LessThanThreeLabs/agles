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
		else if not data?.accessKey? or not data?.secretKey?
			callback 400
		else
			errors = {}
			if not @systemSettingsInformationValidator.isValidAwsId data.accessKey
				errors.domainName = @systemSettingsInformationValidator.getInvalidAwsIdString()
			if not @systemSettingsInformationValidator.isValidAwsSecret data.secretKey
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
		else if not data?.instanceSize? or not data?.numWaiting? or not data?.maxRunning? or not data?.teardownAfterChange?
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

			@modelRpcConnection.systemSettings.update.set_instance_settings userId, data.instanceSize, data.numWaiting, data.maxRunning, data.teardownAfterChange, (error) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback()


	setDeploymentInitialized: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else
			@modelRpcConnection.systemSettings.read.is_deployment_initialized (error, initialized) =>
				if error? or initialized then callback 500
				else
					@modelRpcConnection.systemSettings.update.initialize_deployment userId, (error) =>
						if error?.type is 'InvalidPermissionsError' then callback 403
						else if error? then callback 500
						else callback()
