ddb = require('dynamodb').ddb {
	accessKeyId: 'AKIAJMQW32VH2MIGJ3UQ'
	secretAccessKey: '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'
	endpoint: 'dynamodb.us-west-2.amazonaws.com'
}
express = require 'express'
# pg = require 'pg'
# fs = require 'fs'

# connectionString = "postgres:///license"

app = express()
app.use(express.bodyParser())

licenseTable = 'license_metadata'
licensePermissionsTable = 'license_permissions'
# License table looks like "key -> (created, expires, is_valid, )"

checkTable = (tableName, callback) ->
	ddb.describeTable tableName, callback


createTable = (tableName, primaryKey, callback) ->
	primaryKeyMap = hash: [primaryKey, ddb.schemaTypes().string]
	throughput =
		read: 1
		write: 1

	ddb.createTable tableName, primaryKeyMap, throughput, (error, data) ->
		if error?
			callback error
			return
		callback null, data


waitForTable = (tableName, callback) ->
	checkTable tableName, (error, data) ->
		if error?
			console.log 'Attempting to create table: ' + tableName
			createTable tableName, 'license_key', (error, data) ->
				if error?
					callback error
					return
				setTimeout (() ->
						waitForTable tableName, callback
					), 3000
			return
		if data.TableStatus == 'ACTIVE'
			callback null, true
			return
		setTimeout (() ->
				waitForTable tableName, callback
			), 3000

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
					getLicensePermissions licenseKey, callback
		else if item.server_id isnt serverId
			console.log 'license key and server id do not match'
			callback null, {is_valid: false, reason: 'server id mismatch'}
		else
			getLicensePermissions licenseKey, callback


getLicensePermissions = (licenseKey, callback) ->
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


registerServerForLicenseKey = (licenseKey, serverId, callback) ->
	ddb.updateItem licenseTable, licenseKey, null, { server_id: { value: serverId} }, {}, callback


app.post '/license/check', (request, response) ->
	licenseKey = request.body.license_key
	serverId = request.body.server_id

	validateLicenseKey licenseKey, serverId, (error, result) ->
		if error
			console.error error
			response.end JSON.stringify {is_valid: false, reason: 'error'}
		else
			response.end JSON.stringify result


app.post '/upgrade', (request, response) ->
	licenseKey = request.body.license_key
	serverId = request.body.server_id
	currentVersion = request.body.currentVersion
	upgradeVersion = request.body.upgradeVersion

	validateLicenseKey licenseKey, serverId (error, valid) ->
		if error
			console.error error
			response.send 404
		else
			if valid
				upgradeTarPath = "upgrade/version/#{upgradeVersion}.tar.gz"
				if fs.existsSync upgradeTarPath
					response.sendfile upgradeTarPath
					return
			response.send 404

waitForTable licenseTable, (error, response) ->
	if error?
		console.error error
		return
	if not response
		console.error "Couldn't create the license table"
		return
	waitForTable licensePermissionsTable, (error, response) ->
		if error?
			console.error error
			return
		if not response
			console.error "Couldn't create the license permissions table"
			return
		console.log 'Server started'
		app.listen 9001
