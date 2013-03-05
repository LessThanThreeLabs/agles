assert = require 'assert'
Mailgun = require('mailgun').Mailgun


exports.create = (configurationParams) ->
	feedbackEmailer = new FeedbackEmailer configurationParams
	return feedbackEmailer


class FeedbackEmailer
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?
		@emailer = new Mailgun @configurationParams.emailer.mailgun.key


	sendEmail: (feedback, userAgent, screen) =>
		@emailer.sendText @configurationParams.feedback.email.from,
			@configurationParams.feedback.email.to,
			'Feedback', @_generateEmailBody(feedback, userAgent, screen), (error) ->
				console.error error if error?
				callback error if callback?


	_generateEmailBody: (feedback, userAgent, screen) =>
		return "Feedback: #{feedback}\n\nUser Agent: #{userAgent}\n\nScreen: #{screen.width} x #{screen.height}"
