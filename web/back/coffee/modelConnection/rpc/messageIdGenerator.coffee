crypto = require 'crypto'


exports.create = () ->
	return new MessageIdGenerator()


class MessageIdGenerator
	generateUniqueId: (callback) ->
		crypto.randomBytes 32, (error, bytes) ->
			callback error, bytes.toString 'hex'
