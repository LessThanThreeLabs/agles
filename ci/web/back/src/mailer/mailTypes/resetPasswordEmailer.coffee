assert = require 'assert'

Emailer = require './emailer'


exports.create = (configurationParams, emailSender, domainRetriever) ->
	return new ResetPasswordEmailer configurationParams, emailSender, domainRetriever


class ResetPasswordEmailer extends Emailer
	send: (toEmail, newPassword, callback) =>
		assert.ok callback?
		
		@getDomain (error, domain) =>
			if error? then callback error
			else
				fromEmail = "#{@configurationParams.from.name} <#{@configurationParams.from.email}@#{domain}>"
				subject = 'Your new Koality password!'
				body = "Your new password is: #{newPassword}"

				@emailSender.sendText fromEmail, toEmail, subject, body, (error) ->
					callback error
