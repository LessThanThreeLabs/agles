window.Header = {}


class Header.Model extends Backbone.Model

	initialize: () ->
		@headerMenuModel = new HeaderMenu.Model()


class Header.View extends Backbone.View
	tagName: 'div'
	className: 'header'
	events: 'click .title': '_handleTitleClick'


	initialize: () ->
		@headerMenuView = new HeaderMenu.View model: @model.headerMenuModel


	onDispose: () =>
		@headerMenuView.dispose()


	render: () ->
		@$el.html '<div class="headerContent"><span class="title">Koality</span></div>'
		@$el.append @headerMenuView.render().el
		return @


	_handleTitleClick: () =>
		window.globalRouterModel.set 'view', 'welcome'
