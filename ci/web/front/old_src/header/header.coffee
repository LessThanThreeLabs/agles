window.Header = {}


class Header.Model extends Backbone.Model

	initialize: () ->
		@headerMenuModel = new HeaderMenu.Model()


class Header.View extends Backbone.View
	tagName: 'div'
	className: 'header'
	html: '<div class="headerContent"><span class="title">Koality</span></div>'
	events: 'click .title': '_handleTitleClick'


	initialize: () ->
		@headerMenuView = new HeaderMenu.View model: @model.headerMenuModel


	onDispose: () =>
		@headerMenuView.dispose()


	render: () ->
		@$el.html @html
		@$el.append @headerMenuView.render().el
		return @


	_handleTitleClick: () =>
		window.location.href = '/'
