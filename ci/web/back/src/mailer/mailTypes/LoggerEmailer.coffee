assert = require 'assert'


exports.create = (configurationParams, modelRpcConnection, emailer) ->
	return new LoggerEmailer configurationParams, modelRpcConnection, emailer


class LoggerEmailer
	constructor: (@configurationParams, @modelRpcConnection, @emailer) ->
		assert.ok @configurationParams?
		assert.ok @modelRpcConnection?
		assert.ok @emailer?


	send: (body, callback) =>
		@modelRpcConnection.systemSettings.read.get_website_domain_name 1, (error, domain) =>
			return if error?
			
			fromEmail = "#{@configurationParams.logger.from.name} <#{@configurationParams.logger.from.email}@#{domain}>"
			toEmail = @configurationParams.logger.to.email
			subject = 'Logs'

			@emailer.sendText fromEmail, toEmail, subject, body, callback
