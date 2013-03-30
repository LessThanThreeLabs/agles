assert = require 'assert'


exports.create = (configurationParams, modelRpcConnection, emailer) ->
	return new ResetPasswordEmailer configurationParams, modelRpcConnection, emailer


class ResetPasswordEmailer
	constructor: (@configurationParams, @modelRpcConnection, @emailer) ->
		assert.ok @configurationParams?
		assert.ok @modelRpcConnection?
		assert.ok @emailer?


	email: (toEmail, newPassword, callback) =>
		assert.ok callback?
		
		@modelRpcConnection.systemSettings.read.get_website_domain_name 1, (error, domain) =>
			if error? then callback error
			else
				fromEmail = "#{@configurationParams.resetPassword.from.name} <#{@configurationParams.resetPassword.from.email}@#{domain}>"
				subject = 'Your new Koality password!'
				body = "Your new password is: #{newPassword}"

				@emailer.sendText fromEmail, toEmail, subject, body, (error) ->
					callback error
