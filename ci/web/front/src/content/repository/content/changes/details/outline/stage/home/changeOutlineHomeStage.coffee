window.ChangeOutlineHomeStage = {}


class ChangeOutlineHomeStage.Model extends Backbone.Model


class ChangeOutlineHomeStage.View extends Backbone.View
	tagName: 'div'
	className: 'changeOutlineHomeStage changeOutlineStage'
	html: '<div class="homeIconContainer">icon here</div>'
	events: 'click': '_clickHandler'


	initialize: () =>


	onDispose: () =>


	render: () =>
		@$el.html @html
		return @


	_clickHandler: (event) =>
		globalRouterModel.set 'changeView', 'home',
			error: (model, error) => console.error error
