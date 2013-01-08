window.ChangeOutline = {}


class ChangeOutline.Model extends Backbone.Model
	subscribeUrl: 'changes'
	subscribeId: null

	initialize: () =>
		@subscribeId = globalRouterModel.get 'changeId'

		@changeOutlineHomeStageModel = new ChangeOutlineHomeStage.Model()

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
		socket.emit 'buildOutputs:read', requestData, (error, outputFromAllBuilds) =>
			if error?
				globalRouterModel.set 'view', 'invalidRepositoryState' if error is 403
				console.error error
			else
				@_processBuildOutputIds outputFromAllBuilds


	_processBuildOutputIds: (outputFromAllBuilds) =>
		changeStageModels = []
		changeStageModels = changeStageModels.concat @_getChangeStageModelsForType outputFromAllBuilds, 'setup'
		changeStageModels = changeStageModels.concat @_getChangeStageModelsForType outputFromAllBuilds, 'compile'
		changeStageModels = changeStageModels.concat @_getChangeStageModelsForType outputFromAllBuilds, 'test'

		@changeOutlineStageModels.reset changeStageModels,
			error: (model, error) => console.error error


	_getChangeStageModelsForType: (outputFromAllBuilds, type) =>
		changeStageModels = []

		for outputFromSingleBuild in outputFromAllBuilds
			if outputFromSingleBuild[type]?
				for buildOutputId in outputFromSingleBuild[type]
					changeStageModels.push new ChangeOutlineStage.Model 
						id: buildOutputId
						type: type
						title: 'hello'

		return changeStageModels


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
		@changeOutlineHomeStageView = new ChangeOutlineHomeStage.View model: @model.changeOutlineHomeStageModel

		@model.changeOutlineStageModels.on 'reset', @_addInitialStages, @
		@model.changeOutlineStageModels.on 'add', @_addStage, @

		@model.subscribeId = globalRouterModel.get 'changeId'
		@model.subscribe()
		
		@model.fetchStages()


	onDispose: () =>
		@model.unsubscribe()
		@model.changeOutlineStageModels.off null, null, @

		@changeOutlineHomeStageView.dispose()
		@_removeStages()


	render: () =>
		@$el.html @html
		@$el.append @changeOutlineHomeStageView.render().el
		@_addInitialStages()
		return @


	_addInitialStages: () =>
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
