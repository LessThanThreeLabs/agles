assert = require 'assert'
Mailgun = require('mailgun').Mailgun


exports.create = (configurationParams) ->
	resetPasswordEmailer = new ResetPasswordEmailer configurationParams
	return resetPasswordEmailer


class ResetPasswordEmailer
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?
		@emailer = new Mailgun @configurationParams.emailer.mailgun.key


	sendEmailToUser: (email, newPassword, callback) =>
		@emailer.sendText @configurationParams.resetPassword.email.from, email,
			'Your new Koality password!', "Your new password is: #{newPassword}", (error) ->
				console.error error if error?
				callback error if callback?
