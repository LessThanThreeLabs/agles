window.ChangeOutline = {}


class ChangeOutline.Model extends Backbone.Model
	subscribeUrl: 'changes'
	subscribeId: null

	initialize: () =>
		@subscribeId = globalRouterModel.get 'changeId'

		@changeOutlineStageModels = new Backbone.Collection()
		@changeOutlineStageModels.model = ChangeOutlineStage.Model
		@changeOutlineStageModels.comparator = (changeModel) =>
			return changeModel.get 'beginTime'


	fetchStages: () =>
		@changeOutlineStageModels.reset()

		requestData =
			method: 'getBuildConsoleIds'
			args:
				changeId: globalRouterModel.get('changeId')
		socket.emit 'buildOutputs:read', requestData, (error, results) =>
			if error?
				globalRouterModel.set 'view', 'invalidRepositoryState' if error is 403
				console.error error
			else
				@_processBuildOutputIds results


	_processBuildOutputIds: (buildOutputs) =>
		console.log 'need to process this stuff...'
	# 	consoleOutputModels = []
	# 	consoleOutputModels = consoleOutputModels.concat @_getConsoleOutputModelsForType buildOutputs, 'compile'
	# 	consoleOutputModels = consoleOutputModels.concat @_getConsoleOutputModelsForType buildOutputs, 'test'

	# 	@consoleTextOutputModels.reset consoleOutputModels,
	# 		error: (model, error) => console.error error


	# _getConsoleOutputModelsForType: (buildOutputs, type) =>
	# 	consoleOutputModels = []

	# 	for buildOutput in buildOutputs
	# 		if buildOutput[type]?
	# 			for buildOutputId in buildOutput[type]
	# 				consoleOutputModels.push new ConsoleTextOutput.Model id: buildOutputId

	# 	return consoleOutputModels


	onUpdate: (data) =>
		console.log 'need to handle update!'
		console.log data
		# if data.type is 'consoles added'
		# 	for subtypeName, buildOutputId of data.contents.console_map
		# 		consoleOutputModel = new ConsoleTextOutput.Model id: buildOutputId
		# 		@consoleTextOutputModels.add consoleOutputModel,
		# 			error: (model, error) => console.error error


class ChangeOutline.View extends Backbone.View
	tagName: 'div'
	className: 'changeOutline'
	html: ''
	currentViews: []


	initialize: () =>
		@model.changeOutlineStageModels.on 'reset', @_addInitialStages, @
		@model.changeOutlineStageModels.on 'add', @_addStage, @

		@model.subscribeId = globalRouterModel.get 'changeId'
		@model.subscribe()
		
		@model.fetchStages()


	onDispose: () =>
		@model.unsubscribe()
		@model.changeOutlineStageModels.off null, null, @

		@_removeStages()


	render: () =>
		@$el.html @html
		@_addInitialStages()
		return @


	_addInitialStages: () =>
		@$el.html @html
		@_removeStages()

		@model.changeOutlineStageModels.each (changeOutlineStageModel) =>
			changeOutlineStageView = new ChangeOutlineStage.View model: changeOutlineStageModel
			@$el.append changeOutlineStageView.render().el
			@currentViews.push changeOutlineStageView


	_addStage: (changeOutlineStageModel, collection, options) =>
		changeOutlineStageView = new ChangeOutlineStage.View model: changeOutlineStageModel
		@$el.append changeOutlineStageView.render().el
		@currentViews.push changeOutlineStageView


	_removeStages: () =>
		for view in @currentViews
			view.dispose()
		@currentViews = []
