assert = require 'assert'

Emailer = require './emailer'


exports.create = (configurationParams, emailSender, domainRetriever) ->
	return new InitialAdminEmailer configurationParams, emailSender, domainRetriever


class InitialAdminEmailer extends Emailer
	send: (email, firstName, lastName, token, callback) =>
		assert.ok callback?
		
		@getDomain (error, domain) =>
			if error? then callback error
			else
				fromEmail = "#{@configurationParams.from.name} <#{@configurationParams.from.email}@#{domain}>"
				toEmail = "#{firstName} #{lastName} <#{email}>"
				subject = 'Koality admin token'
				body = "Hello #{firstName} #{lastName}, your admin token is: #{token}"

				@emailSender.sendText fromEmail, toEmail, subject, body, (error) ->
					callback error
