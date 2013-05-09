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

licenseTable = 'license'
# License table looks like "key -> (created, expires, is_valid, )"


checkLicenseTable = (callback) ->
	ddb.describeTable licenseTable, callback


createLicenseTable = (callback) ->
	primaryKey = hash: ['license_key', ddb.schemaTypes().string]
	throughput =
		read: 1
		write: 1

	ddb.createTable licenseTable, primaryKey, throughput, (error, data) ->
		if error?
			callback error
			return
		callback null, data


waitForLicenseTable = (callback) ->
	checkLicenseTable (error, data) ->
		if error?
			console.log 'Attempting to create table: ' + licenseTable
			createLicenseTable (error, data) ->
				if error?
					callback error
					return
				setTimeout (() ->
						waitForLicenseTable callback
					), 3000
			return
		if data.TableStatus == 'ACTIVE'
			callback null, true
			return
		setTimeout (() ->
				waitForLicenseTable callback
			), 3000

validateLicenseKey = (key, serverId, callback) ->
	ddb.getItem licenseTable, key, null, {}, (error, item) ->
		if error?
			callback error
			return
		if not item?
			callback 'license key not found'
			return
		if not item.is_valid? or not item.expires?
			callback 'found a malformed item for the license key: ' + data.Item
			return
		currentTime = Math.round new Date().getTime() / 1000
		if not item.is_valid
			callback null, 'invalid'
		if currentTime >= item.expires
			callback null, 'expired'
		if not item.server_id?
			console.log 'registering server: ' + serverId + ' for license key: ' + key
			registerServerForLicenseKey key, serverId, (error, response) ->
				if error?
					callback error
					return
				callback null, 'valid'
			return
		if item.server_id isnt serverId
			console.log 'license key and server id do not match'
			callback null, 'mismatch'
			return
		callback null, 'valid'


registerServerForLicenseKey = (key, serverId, callback) ->
	ddb.updateItem licenseTable, key, null, { server_id: { value: serverId} }, {}, callback


app.post '/license/check', (request, response) ->
	key = request.body.key
	serverId = request.body.server_id

	validateLicenseKey key, serverId, (error, result) ->
		if error
			console.error error
			response.end 'error'
		else
			response.end result


app.post '/upgrade', (request, response) ->
	key = request.body.key
	serverId = request.body.serverId
	currentVersion = request.body.currentVersion
	upgradeVersion = request.body.upgradeVersion

	validateLicenseKey key, serverId (error, valid) ->
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

waitForLicenseTable (error, response) ->
	if error?
		console.error error
		return
	if not response
		console.error "Couldn't create the license table"
		return
	console.log 'Server started'
	app.listen 9001
