window.ChangeDetails = {}


class ChangeDetails.Model extends Backbone.Model

	initialize: () =>
		@changeOutlineModel = new ChangeOutline.Model()


class ChangeDetails.View extends Backbone.View
	tagName: 'div'
	className: 'changeDetails'
	html: '<div class="changeDetailsContent"></div>'


	initialize: () =>
		@changeOutlineView = new ChangeOutline.View model: @model.changeOutlineModel


	onDispose: () =>
		@changeOutlineView.dispose()


	render: () =>
		@$el.html @html
		@$('.changeDetailsContent').html @changeOutlineView.render().el
		return @
