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


	initialize: () =>
		@changeOutlineView = new ChangeOutline.View model: @model.changeOutlineModel

		globalRouterModel.on 'change:changeView', @_updateStageView, @


	onDispose: () =>
		globalRouterModel.off null, null, @

		@changeOutlineView.dispose()


	render: () =>
		@$el.html @html
		@$('.changeDetailsOutlineContainer').html @changeOutlineView.render().el
		@_updateStageView()
		return @


	_updateStageView: () =>
		if globalRouterModel.get('changeView') is 'home'
			@$('.changeDetailsStageContainer').html 'hello'
		else
			@$('.changeDetailsStageContainer').html 'there'
