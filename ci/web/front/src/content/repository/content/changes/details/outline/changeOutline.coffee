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
