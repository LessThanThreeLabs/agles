window.ConsoleCompilationOutput = {}


class ConsoleCompilationOutput.Model extends Backbone.Model
	defaults:
		consoleTextOutputModels: null


	fetchOutput: () =>
		if not window.globalRouterModel.get('buildId')?
			@set 'consoleTextOutputModels', []
			return

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

			@set 'consoleTextOutputModels', consoleOutputModels


class ConsoleCompilationOutput.View extends Backbone.View
	tagName: 'div'
	className: 'consoleCompilationOutput'


	initialize: () =>
		window.globalRouterModel.on 'change:buildId', @model.fetchOutput
		@model.on 'change:consoleTextOutputModels', @_addOutput


	render: () =>
		@$el.html '&nbsp'
		@model.fetchOutput()
		return @


	_addOutput: () =>
		@$el.empty()
		for consoleTextOutputModel in @model.get 'consoleTextOutputModels'
			consoleTextOutputView = new ConsoleTextOutput.View model: consoleTextOutputModel
			@$el.append consoleTextOutputView.render().el