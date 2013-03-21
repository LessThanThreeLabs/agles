assert = require 'assert'


exports.create = (configurationParams, domain, emailer) ->
	return new ResetPasswordEmailer configurationParams, domain, emailer


class ResetPasswordEmailer
	constructor: (@configurationParams, @domain, @emailer) ->
		assert.ok @configurationParams?
		assert.ok @domain?
		assert.ok @emailer?


	email: (toEmail, newPassword, callback) =>
		fromEmail = "#{@configurationParams.resetPassword.from.name} <#{@configurationParams.resetPassword.from.email}@#{@domain}>"
		subject = 'Your new Koality password!'
		body = "Your new password is: #{newPassword}"

		@emailer.sendText fromEmail, toEmail, subject, body, (error) ->
			console.error error if error?
			callback error if callback?
