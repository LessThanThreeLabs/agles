window.ChangeOutline = {}


class ChangeOutline.Model extends Backbone.Model
	subscribeUrl: 'changes'
	subscribeId: null

	initialize: () =>
		@subscribeId = globalRouterModel.get 'changeId'
		console.log '>>>> ' + @subscribeId

		@changeOutlineHomeStageModel = new ChangeOutlineHomeStage.Model()

		@changeOutlineStageModels = new Backbone.Collection()
		@changeOutlineStageModels.model = ChangeOutlineStage.Model
		@changeOutlineStageModels.comparator = (changeModel) =>
			return changeModel.get 'beginTime'


	fetchStages: () =>
		@changeOutlineStageModels.reset()

		requestData =
			method: 'getBuildConsolesForChangeId'
			args: changeId: globalRouterModel.get('changeId')
		socket.emit 'buildOutputs:read', requestData, (error, buildOutputs) =>
			console.log buildOutputs
			@changeOutlineStageModels.reset buildOutputs,
				error: (model, error) => console.error error


	onUpdate: (data) =>
		if data.type is 'new build output'
			console.log data.contents
			@changeOutlineStageModels.add data.contents,
				error: (model, error) => console.error error


	getBuildOutputIdForBuildNameIdentifier: (buildNameIdentifier) =>
		changeOutlineStageWithName = @changeOutlineStageModels.find (changeOutlineStageModel) =>
			return changeOutlineStageModel.getNameIdendtifier() is buildNameIdentifier
		return changeOutlineStageWithName?.get 'id'


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
