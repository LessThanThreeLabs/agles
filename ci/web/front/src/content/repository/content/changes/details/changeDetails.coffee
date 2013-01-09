window.ChangeDetails = {}


class ChangeDetails.Model extends Backbone.Model

	initialize: () =>
		@changeOutlineModel = new ChangeOutline.Model()


class ChangeDetails.View extends Backbone.View
	tagName: 'div'
	className: 'changeDetails'
	html: '<div class="changeDetailsContent">
			<div class="changeDetailsOutlineContainer"></div>
			<div class="changeDetailsStageContainer"></div>
		</div>'
	_currentStageView = null


	initialize: () =>
		@changeOutlineView = new ChangeOutline.View model: @model.changeOutlineModel

		globalRouterModel.on 'change:changeView', @_updateStageView, @


	onDispose: () =>
		globalRouterModel.off null, null, @

		@changeOutlineView.dispose()
		@_currentStageView.dispose() if @_currentStageView?


	render: () =>
		@$el.html @html
		@$('.changeDetailsOutlineContainer').html @changeOutlineView.render().el
		@_updateStageView()
		return @


	_updateStageView: () =>
		@_currentStageView.dispose() if @_currentStageView?

		if globalRouterModel.get('changeView') is 'home'
			@_currentStageView = null
			@$('.changeDetailsStageContainer').html 'hello'
		else
			buildOutputId = @model.changeOutlineModel.getBuildOutputIdForBuildNameIdentifier globalRouterModel.get 'changeView'

			if buildOutputId?
				consoleTextOutputModel = new ConsoleTextOutput.Model id: buildOutputId
				@_currentStageView = new ConsoleTextOutput.View model: consoleTextOutputModel
				@$('.changeDetailsStageContainer').html @_currentStageView.render().el
			else
				@_currentStageView = null
				@$('.changeDetailsStageContainer').html 'bad'
