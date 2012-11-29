window.ConsoleCompilationOutput = {}


class ConsoleCompilationOutput.Model extends Backbone.Model

	initialize: () =>
		@consoleTextOutputModels = new Backbone.Collection()
		@consoleTextOutputModels.model = ConsoleTextOutput.Model
		@consoleTextOutputModels.comparator = (consoleTextOutputModel) =>
			return consoleTextOutputModel.get 'title'


	fetchOutput: () =>
		@consoleTextOutputModels.reset()

		return if not window.globalRouterModel.get('buildId')?

		requestData =
			method: 'buildOutputIds'
			args: 
				buildId: window.globalRouterModel.get('buildId')
		socket.emit 'buildOutputs:read', requestData, (error, buildOutputIds) =>
			if error?
				console.error error
				return

			consoleOutputModels = []
			for buildOutputTypeKey, buildOutputTypeValue of buildOutputIds
				for buildOutputId in buildOutputTypeValue
					consoleOutputModels.push new ConsoleTextOutput.Model id: buildOutputId

			consoleTextOutputModels.reset consoleOutputModels,
				error: (model, error) => console.error error


class ConsoleCompilationOutput.View extends Backbone.View
	tagName: 'div'
	className: 'consoleCompilationOutput'
	html: '&nbsp'


	initialize: () =>
		@model.consoleTextOutputModels.on 'reset', @_addOutput
		window.globalRouterModel.on 'change:buildId', @model.fetchOutput


	onDispose: () =>
		@model.consoleTextOutputModels.off null, null, @
		window.globalRouterModel.off null, null, @


	render: () =>
		@$el.html @html
		@model.fetchOutput()
		return @


	_addOutput: () =>
		@$el.html @html
		for consoleTextOutputModel in @model.consoleTextOutputModels
			consoleTextOutputView = new ConsoleTextOutput.View model: consoleTextOutputModel
			@$el.append consoleTextOutputView.render().el