express = require 'express'
knox = require 'knox'

aws_credentials = 
	accessKeyId: 'AKIAJMQW32VH2MIGJ3UQ'
	secretAccessKey: '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'

ddb = require('dynamodb').ddb {
	accessKeyId: aws_credentials.accessKeyId
	secretAccessKey: aws_credentials.secretAccessKey
	endpoint: 'dynamodb.us-west-2.amazonaws.com'
}

s3Client = knox.createClient
 	key: aws_credentials.accessKeyId
 	secret: aws_credentials.secretAccessKey
 	bucket: 'koality_release'

licenseTable = 'license_metadata'
licensePermissionsTable = 'license_permissions'
# License table looks like "key -> (created, expires, is_valid, )"


validateLicenseKey = (licenseKey, serverId, callback) ->
	ddb.getItem licenseTable, licenseKey, null, {}, (error, item) ->
		currentTime = Math.round new Date().getTime() / 1000
		if error?
			callback error
		else if not item?
			callback null, {is_valid: false, reason: 'license key not found'}
		else if not item.is_valid? or not item.expires?
			callback 'found a malformed item for the license key: ' + data.Item
		else if not item.is_valid
			callback null, {is_valid: false, reason: 'invalid key'}
		else if currentTime >= item.expires
			callback null, {is_valid: false, reason: 'key expired'}
		else if not item.server_id?
			console.log 'registering server: ' + serverId + ' for license key: ' + licenseKey
			registerServerForLicenseKey licenseKey, serverId, (error, response) ->
				if error?
					callback error
				else
					_getLicensePermissions licenseKey, callback
		else if item.server_id isnt serverId
			console.log 'license key and server id do not match'
			callback null, {is_valid: false, reason: 'server id mismatch'}
		else
			_getLicensePermissions licenseKey, callback


updateDeploymentInfo = (licenseKey, serverId, userCount, callback) ->
	ddb.updateItem licenseTable, licenseKey, null, { user_count: { value: userCount } }, {}, callback

registerServerForLicenseKey = (licenseKey, serverId, callback) ->
	ddb.updateItem licenseTable, licenseKey, null, { server_id: { value: serverId } }, {}, callback


_checkTable = (tableName, callback) ->
	ddb.describeTable tableName, callback


_createTable = (tableName, primaryKey, callback) ->
	primaryKeyMap = hash: [primaryKey, ddb.schemaTypes().string]
	throughput =
		read: 1
		write: 1

	ddb.createTable tableName, primaryKeyMap, throughput, (error, data) ->
		if error?
			callback error
			return
		callback null, data


_waitForTable = (tableName, callback) ->
	_checkTable tableName, (error, data) ->
		if error?
			console.log 'Attempting to create table: ' + tableName
			_createTable tableName, 'license_key', (error, data) ->
				if error?
					callback error
					return
				setTimeout (() ->
						_waitForTable tableName, callback
					), 3000
			return
		if data.TableStatus == 'ACTIVE'
			callback null, true
			return
		setTimeout (() ->
				_waitForTable tableName, callback
			), 3000


_getLicensePermissions = (licenseKey, callback) ->
	ddb.getItem licensePermissionsTable, licenseKey, null, {}, (error, item) ->
		if error?
			callback error
		else if not item?
			callback null, {is_valid: false, reason: 'no permissions found'}
		else
			response = item
			delete response.license_key
			response.is_valid = true
			callback null, response


main = () ->
	app = express()
	app.use(express.bodyParser())

	app.post '/license/check', (request, response) ->
		licenseKey = request.body.license_key
		serverId = request.body.server_id
		userCount = request.body.user_count

		if not licenseKey? or not serverId? or not userCount?
			response.send 400, error: 'Malformed request'
			return

		updateDeploymentInfo licenseKey, serverId, userCount, (error, result) ->
			if error
				console.error error
				response.send JSON.stringify {is_valid: false, reason: 'error'}
			else
				validateLicenseKey licenseKey, serverId, (error, result) ->
					if error
						console.error error
						response.send JSON.stringify {is_valid: false, reason: 'error'}
					else
						response.send JSON.stringify result


	app.post '/upgrade', (request, response) ->
		licenseKey = request.body.license_key
		serverId = request.body.server_id
		currentVersion = request.body.current_version
		upgradeVersion = request.body.upgrade_version

		if not licenseKey? or not serverId? or not currentVersion? or not upgradeVersion?
			response.send 400, error: 'Malformed request'
			return

		validateLicenseKey licenseKey, serverId, (error, licenseResponse) ->
			if error?
				response.send 400, error: 'Bad license key'
			else
				if licenseResponse.is_valid
					upgradeTarKey = "upgrade/koality-#{upgradeVersion}.tar.gz"
					console.log upgradeTarKey
					s3Client.get(upgradeTarKey).on('response', (s3Response) ->
						if s3Response.statusCode isnt 200
							console.error s3Response.statusCode
							response.send s3Response.statusCode, error: 'Invalid version number'
						else
							response.setHeader 'Content-Type', s3Response.headers['content-type']
							response.setHeader 'Content-Length', s3Response.headers['content-length']
							s3Response.on 'data', (chunk) ->
								response.write chunk
							s3Response.on 'end', () ->
								response.end()
					).end()
				else
					response.send 400, error: 'Bad license key'


	_waitForTable licenseTable, (error, response) ->
		if error?
			console.error error
			return
		if not response
			console.error "Couldn't create the license table"
			return
		_waitForTable licensePermissionsTable, (error, response) ->
			if error?
				console.error error
				return
			if not response
				console.error "Couldn't create the license permissions table"
				return
			console.log 'Server started on http://localhost:9001'
			app.listen 9001


main()