
exports.create = (configurationParams) ->
	return new ModelConnection configurationParams


class ModelConnection
	constructor: (@configurationParams)

	doSomething: () ->
		console.log 'should do something'
