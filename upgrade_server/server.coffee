express = require 'express'
pg = require 'pg'
fs = require 'fs'

connectionString = "postgres:///license"

app = express()
app.use(express.bodyParser())


validateLicenseKey = (key, serverId, callback) ->
	pg.connect connectionString, (error, client) ->
		client.query 'SELECT license.id FROM (license JOIN server_id ON license.id = server_id.license_id) WHERE key = $1 AND server_id = $2', [key, serverId], (error, result) ->
			if error
				callback error
			callback null, result.rows.length > 0


app.post '/license/check', (request, response) ->
	key = request.body.key
	serverId = request.body.serverId

	validateLicenseKey key, serverId, (error, result) ->
		if error
			console.log error
			response.end 'false'
		else
			if result
				response.end 'true'
			else
				response.end 'false'


app.post '/upgrade', (request, response) ->
	key = request.body.key
	serverId = request.body.serverId
	currentVersion = request.body.currentVersion
	upgradeVersion = request.body.upgradeVersion

	validateLicenseKey key, serverId (error, valid) ->
		if error
			console.log error
			response.send 404
		else
			if valid
				upgradeTarPath = "upgrade/version/#{upgradeVersion}.tar.gz"
				if fs.existsSync upgradeTarPath
					response.sendfile upgradeTarPath
					return
			response.send 404 


app.listen 9001
