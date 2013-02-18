express = require 'express'
pg = require 'pg'
fs = require 'fs'

connectionString = "postgres:///license"

app = express()
app.use(express.bodyParser())


validateLicenseKey = (key, callback) ->
	pg.connect connectionString, (error, client) ->
		client.query 'SELECT id FROM license WHERE key = $1', [key], (error, result) ->
			if error
				callback error
			callback null, result.rows.length > 0


app.get '/versions', (request, response) ->
	pg.connect connectionString, (error, client) ->
		client.query 'SELECT version_num, release_date FROM version ORDER BY id ASC', (error, result) ->
			if error
				console.log error
				response.json JSON.stringify []
			else
				response.json JSON.stringify result.rows


app.post '/license_check', (request, response) ->
	key = request.body.key
	validateLicenseKey key, (error, result) ->
		if error
			console.log error
			response.end 'false'
		else
			if result
				response.end 'true'
			else
				response.end 'false'


app.post '/do_upgrade', (request, response) ->
	key = request.body.key
	currentVersion = request.body.currentVersion
	upgradeVersion = request.body.upgradeVersion

	validateLicenseKey key, (error, valid) ->
		if error
			console.log error
			response.send 404
		else
			if valid
				upgradeTarPath = "upgrades/versions/#{upgradeVersion}"
				if fs.existsSync upgradeTarPath
					response.sendfile upgradeTarPath
					return
			response.send 404 


app.listen 9001
