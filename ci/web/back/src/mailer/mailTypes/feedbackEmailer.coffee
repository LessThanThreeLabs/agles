assert = require 'assert'


exports.create = (configurationParams, domain, emailer) ->
	return new FeedbackEmailer configurationParams, domain, emailer


class FeedbackEmailer
	constructor: (@configurationParams, @domain, @emailer) ->
		assert.ok @configurationParams?
		assert.ok @domain?
		assert.ok @emailer?


	email: (user, feedback, userAgent, screen) =>
		fromEmail = "#{@configurationParams.feedback.from.name} <#{@configurationParams.feedback.from.email}@#{@domain}>"
		toEmail = @configurationParams.feedback.to.email
		subject = 'Feedback'

		@emailer.sendText fromEmail, toEmail, subject, @_generateEmailBody(user, feedback, userAgent, screen), (error) ->
			console.error error if error?
			callback error if callback?


	_generateEmailBody: (user, feedback, userAgent, screen) =>
		return "User: #{user.firstName} #{user.lastName} (#{user.email})\n\nFeedback: #{feedback}\n\nUser Agent: #{userAgent}\n\nScreen: #{screen.width} x #{screen.height}"
