assert = require 'assert'


exports.create = (configurationParams, modelRpcConnection, emailer) ->
	return new InviteUserEmailer configurationParams, modelRpcConnection, emailer


class InviteUserEmailer
	constructor: (@configurationParams, @modelRpcConnection, @emailer) ->
		assert.ok @configurationParams?
		assert.ok @modelRpcConnection?
		assert.ok @emailer?


	email: (toEmail, userToken, callback) =>
		assert.ok callback?
		
		@modelRpcConnection.systemSettings.read.get_website_domain_name 1, (error, domain) =>
			if error? then callback error
			else
				fromEmail = "#{@configurationParams.inviteUser.from.name} <#{@configurationParams.inviteUser.from.email}@#{domain}>"
				subject = 'Welcome to Koality!'
				uri = 'https://' + domain + '/create/account?token=' + userToken
				body = "Click here to create your account: #{uri}"

				@emailer.sendText fromEmail, toEmail, subject, body, (error) ->
					callback error
