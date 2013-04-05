assert = require 'assert'

Emailer = require './emailer'


exports.create = (configurationParams, emailSender, domainRetriever) ->
	return new FeedbackEmailer configurationParams, emailSender, domainRetriever


class FeedbackEmailer extends Emailer
	send: (user, feedback, userAgent, screen) =>
		@getDomain (error, domain) =>
			return if error?
			
			fromEmail = "#{@configurationParams.from.name} <#{@configurationParams.from.email}@#{domain}>"
			toEmail = @configurationParams.to.email
			subject = 'Feedback'
			body = "User: #{user.firstName} #{user.lastName} (#{user.email})\n\nFeedback: #{feedback}\n\nUser Agent: #{userAgent}\n\nScreen: #{screen.width} x #{screen.height}"

			@emailSender.sendText fromEmail, toEmail, subject, body, (error) ->
				console.error error if error?
