window.ConsoleCompilationOutput = {}


class ConsoleCompilationOutput.Model extends Backbone.Model
	defaults:
		consoleTextOutputModels: null


	loadOutput: () =>
		if window.globalRouterModel.get('buildId')?
			@set 'consoleTextOutputModels', (@_createFakeOutputModel num for num in [0...5])
		else
			@set 'consoleTextOutputModels', []


	_createFakeOutputModel: (number) =>
		return new ConsoleTextOutput.Model id: number


	fetchOutput: () =>
		requestData:
			method: 'buildOutputIds'
			args: {}
		socket.emit 'buildOutputs:read', requestData, (error, buildOutputIds) =>
			if error?
				console.error error
				return

			console.log buildOutputIds

			consoleOutputModels = []
			for buildOutputTypeKey, buildOutputTypeValue of buildOutputIds
				for buildOutputId in buildOutputTypeValue.outputIds
					consoleOutputModels.append new ConsoleTextOutput.Model id: buildOutputId

			@set 'consoleTextOutputModels', consoleOutputModels


class ConsoleCompilationOutput.View extends Backbone.View
	tagName: 'div'
	className: 'consoleCompilationOutput'


	initialize: () =>
		window.globalRouterModel.on 'change:buildId', @model.loadOutput
		@model.on 'change:consoleTextOutputModels', @_addOutput


	render: () =>
		@$el.html '&nbsp'
		@model.loadOutput()
		return @


	_addOutput: () =>
		@$el.empty()
		for consoleTextOutputModel in @model.get 'consoleTextOutputModels'
			consoleTextOutputView = new ConsoleTextOutput.View model: consoleTextOutputModel
			@$el.append consoleTextOutputView.render().el