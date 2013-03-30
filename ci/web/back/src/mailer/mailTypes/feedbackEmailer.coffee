assert = require 'assert'


exports.create = (configurationParams, modelRpcConnection, emailer) ->
	return new FeedbackEmailer configurationParams, modelRpcConnection, emailer


class FeedbackEmailer
	constructor: (@configurationParams, @modelRpcConnection, @emailer) ->
		assert.ok @configurationParams?
		assert.ok @modelRpcConnection?
		assert.ok @emailer?


	email: (user, feedback, userAgent, screen) =>
		@modelRpcConnection.systemSettings.read.get_website_domain_name 1, (error, domain) =>
			return if error?
			
			fromEmail = "#{@configurationParams.feedback.from.name} <#{@configurationParams.feedback.from.email}@#{domain}>"
			toEmail = @configurationParams.feedback.to.email
			subject = 'Feedback'
			body = "User: #{user.firstName} #{user.lastName} (#{user.email})\n\nFeedback: #{feedback}\n\nUser Agent: #{userAgent}\n\nScreen: #{screen.width} x #{screen.height}"

			@emailer.sendText fromEmail, toEmail, subject, body, (error) ->
				console.error error if error?
