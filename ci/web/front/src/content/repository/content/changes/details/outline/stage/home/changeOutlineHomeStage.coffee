window.ChangeOutlineHomeStage = {}


class ChangeOutlineHomeStage.Model extends Backbone.Model
	defaults:
		selected: false


	initialize: () =>
		if globalRouterModel.get('changeView') is 'home'
			@set 'selected', true,
				error: (model, error) => console.error error


class ChangeOutlineHomeStage.View extends Backbone.View
	tagName: 'div'
	className: 'changeOutlineHomeStage changeOutlineStage'
	html: '<div class="homeImageContainer">
			<img src="/img/icons/home.svg" class="homeImage" />
		</div>'
	events: 'click': '_clickHandler'


	initialize: () =>
		@model.on 'change', @render, @
		globalRouterModel.on 'change:changeView', (() =>
			@model.set 'selected', globalRouterModel.get('changeView') is 'home',
				error: (model, error) => console.error error
		), @


	onDispose: () =>
		@model.off null, null, @
		globalRouterModel.off null, null, @


	render: () =>
		@$el.html @html
		@_fixSelectedState()
		return @


	_fixSelectedState: () =>
		@$el.toggleClass 'selected', @model.get 'selected'


	_clickHandler: (event) =>
		globalRouterModel.set 'changeView', 'home',
			error: (model, error) => console.error error
