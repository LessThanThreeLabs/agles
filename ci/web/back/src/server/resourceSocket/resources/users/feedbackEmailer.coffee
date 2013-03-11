assert = require 'assert'
Mailgun = require('mailgun').Mailgun


exports.create = (configurationParams) ->
	feedbackEmailer = new FeedbackEmailer configurationParams
	return feedbackEmailer


class FeedbackEmailer
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?
		@emailer = new Mailgun @configurationParams.emailer.mailgun.key


	sendEmail: (user, feedback, userAgent, screen) =>
		@emailer.sendText @configurationParams.feedback.email.from,
			@configurationParams.feedback.email.to,
			'Feedback', @_generateEmailBody(user, feedback, userAgent, screen), (error) ->
				console.error error if error?
				callback error if callback?


	_generateEmailBody: (user, feedback, userAgent, screen) =>
		return "User: #{user.firstName} #{user.lastName} (#{user.email})\n\nFeedback: #{feedback}\n\nUser Agent: #{userAgent}\n\nScreen: #{screen.width} x #{screen.height}"
