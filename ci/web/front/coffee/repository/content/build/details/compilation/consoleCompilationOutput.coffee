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
		return new ConsoleTextOutput.Model
			id: number
			title: 'hello ' + number


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