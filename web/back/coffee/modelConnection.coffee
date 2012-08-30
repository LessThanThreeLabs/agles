
exports.create = (configuration) ->
	return new ModelConnection configuration

class ModelConnection
	constructor: (@configuration) ->
