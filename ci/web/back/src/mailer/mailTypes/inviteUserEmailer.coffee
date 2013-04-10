assert = require 'assert'

Emailer = require './emailer'


exports.create = (configurationParams, emailSender, domainRetriever) ->
	return new InviteUserEmailer configurationParams, emailSender, domainRetriever


class InviteUserEmailer extends Emailer
	send: (toEmail, userToken, callback) =>
		assert.ok callback?
		
		@getDomain (error, domain) =>
			if error? then callback error
			else
				fromEmail = "#{@configurationParams.from.name} <#{@configurationParams.from.email}@#{domain}>"
				subject = 'Welcome to Koality!'
				uri = 'https://' + domain + '/create/account?token=' + userToken
				body = "Click here to create your account: #{uri}"

				@emailSender.sendText fromEmail, toEmail, subject, body, (error) ->
					callback error
