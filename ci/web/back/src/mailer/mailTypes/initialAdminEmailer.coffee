assert = require 'assert'


exports.create = (configurationParams, modelRpcConnection, emailer) ->
	return new InitialAdminEmailer configurationParams, modelRpcConnection, emailer


class InitialAdminEmailer
	constructor: (@configurationParams, @modelRpcConnection, @emailer) ->
		assert.ok @configurationParams?
		assert.ok @modelRpcConnection?
		assert.ok @emailer?


	email: (email, firstName, lastName, token, callback) =>
		assert.ok callback?
		
		@modelRpcConnection.systemSettings.read.get_website_domain_name 1, (error, domain) =>
			if error? then callback error
			else
				fromEmail = "#{@configurationParams.initialAdmin.from.name} <#{@configurationParams.initialAdmin.from.email}@#{domain}>"
				toEmail = "#{firstName} #{lastName} <#{email}>"
				subject = 'Koality admin token'
				body = "Hello #{firstName} #{lastName}, your admin token is: #{token}"

				@emailer.sendText fromEmail, toEmail, subject, body, (error) ->
					callback error
