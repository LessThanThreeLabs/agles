exports.create = () ->
	return new MessageIdGenerator()


class MessageIdGenerator
	constructor: () ->
		@currentId = 0
		@maxAllowedId = Math.pow 2, 16


	generateUniqueId: () ->
		id = @currentId
		@currentId = if @currentId < @maxAllowedId then @currentId + 1 else 0
		return id.toString()
