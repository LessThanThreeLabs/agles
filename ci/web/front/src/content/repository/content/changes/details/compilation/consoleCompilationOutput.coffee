window.ConsoleCompilationOutput = {}


class ConsoleCompilationOutput.Model extends Backbone.Model

	initialize: () =>
		@consoleTextOutputModels = new Backbone.Collection()
		@consoleTextOutputModels.model = ConsoleTextOutput.Model
		@consoleTextOutputModels.comparator = (consoleTextOutputModel) =>
			return consoleTextOutputModel.get 'title'


	fetchOutput: () =>
		@consoleTextOutputModels.reset()

		return if not globalRouterModel.get('changeId')?

		requestData =
			method: 'getBuildConsoleIds'
			args: 
				changeId: window.globalRouterModel.get('changeId')
		socket.emit 'buildOutputs:read', requestData, (error, results) =>
			if error?
				globalRouterModel.set 'view', 'invalidRepositoryState' if error is 403
				console.error error
			else
				@_processBuildOutputIds results
			

	_processBuildOutputIds: (buildOutputs) =>
		consoleOutputModels = []
		consoleOutputModels = consoleOutputModels.concat @_getConsoleOutputModelsForType buildOutputs, 'compile'
		consoleOutputModels = consoleOutputModels.concat @_getConsoleOutputModelsForType buildOutputs, 'test'

		@consoleTextOutputModels.reset consoleOutputModels,
			error: (model, error) => console.error error


	_getConsoleOutputModelsForType: (buildOutputs, type) =>
		console.log 'WHY DO WE HAVE THIS FUNCTION?....'

		consoleOutputModels = []

		for buildOutput in buildOutputs
			for buildOutputId in buildOutput[type]
				consoleOutputModels.push new ConsoleTextOutput.Model id: buildOutputId

		return consoleOutputModels


class ConsoleCompilationOutput.View extends Backbone.View
	tagName: 'div'
	className: 'consoleCompilationOutput'
	html: ''
	currentViews: []


	initialize: () =>
		@model.consoleTextOutputModels.on 'reset', @_addOutput, @
		globalRouterModel.on 'change:changeId', @model.fetchOutput, @


	onDispose: () =>
		@model.consoleTextOutputModels.off null, null, @
		globalRouterModel.off 'change:changeId', null, @

		@_removeOutputs()


	render: () =>
		@$el.html @html
		@model.fetchOutput()
		return @


	_clear: () =>
		@$el.html @html
		@_removeOutputs()


	_addOutput: () =>
		@_clear()
		@model.consoleTextOutputModels.each (consoleTextOutputModel) =>
			consoleTextOutputView = new ConsoleTextOutput.View model: consoleTextOutputModel
			@$el.append consoleTextOutputView.render().el
			@currentViews.push consoleTextOutputView
			

	_removeOutputs: () =>
		for view in @currentViews
			view.dispose()
		@currentViews = []
