window.ConsoleCompilationOutput = {}


class ConsoleCompilationOutput.Model extends Backbone.Model
	subscribeUrl: 'changes'
	subscribeId: null

	initialize: () =>
		@subscribeId = globalRouterModel.get 'changeId'

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
			if buildOutput[type]?
				for buildOutputId in buildOutput[type]
					consoleOutputModels.push new ConsoleTextOutput.Model id: buildOutputId

		return consoleOutputModels


	console.log 'NEED TO MAKE IT SO THAT CONSOLES_ADDED FIRED FOR CHANGES, NOT BUILDS'
	onUpdate: (data) =>
		if data.type is 'consoles added'
			console.log 'need to handle consoles added'
			# buildOutputId = data.contents.buildOutputId
			# consoleOutputModel = new ConsoleTextOutput.Model id: buildOutputId
			# @consoleTextOutputModels.add consoleOutputModel,
			# 	error: (model, error) => console.error error


class ConsoleCompilationOutput.View extends Backbone.View
	tagName: 'div'
	className: 'consoleCompilationOutput'
	html: ''
	currentViews: []


	initialize: () =>
		@model.consoleTextOutputModels.on 'reset', @_addInitialOutput, @
		@model.consoleTextOutputModels.on 'add', @_addOutput, @

		globalRouterModel.on 'change:changeId', (() =>
				@model.unsubscribe() if @model.subscribeId?
				@model.subscribeId = globalRouterModel.get 'changeId'
				@model.subscribe() if @model.subscribeId?
				@model.fetchOutput()
			), @

		@model.subscribeId = globalRouterModel.get 'changeId'
		@model.subscribe() if @model.subscribeId?


	onDispose: () =>
		@model.unsubscribe() if @model.subscribeId?
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


	_addInitialOutput: () =>
		@_clear()
		@model.consoleTextOutputModels.each (consoleTextOutputModel) =>
			consoleTextOutputView = new ConsoleTextOutput.View model: consoleTextOutputModel
			@$el.append consoleTextOutputView.render().el
			@currentViews.push consoleTextOutputView


	_addOutput: (consoleTextOutputModel, collection, options) =>
		consoleTextOutputView = new ConsoleTextOutput.View model: consoleTextOutputModel
		@$el.append consoleTextOutputView.render().el
		@currentViews.push consoleTextOutputView


	_removeOutputs: () =>
		for view in @currentViews
			view.dispose()
		@currentViews = []
