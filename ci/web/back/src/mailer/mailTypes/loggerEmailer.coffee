assert = require 'assert'

Emailer = require './emailer'


exports.create = (configurationParams, emailSender, domainRetriever) ->
	return new LoggerEmailer configurationParams, emailSender, domainRetriever


class LoggerEmailer extends Emailer
	send: (body, callback) =>
		console.log body
		
		@getDomain (error, domain) =>
			if error? then callback error
			else
				fromEmail = "#{@configurationParams.from.name} <#{@configurationParams.from.email}@#{domain}>"
				toEmail = @configurationParams.to.email
				subject = 'Logs'

				@emailSender.sendText fromEmail, toEmail, subject, body, callback
