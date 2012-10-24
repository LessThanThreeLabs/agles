window.Header = {}


class Header.Model extends Backbone.Model

	initialize: () ->
		@headerMenuModel = new HeaderMenu.Model()


class Header.View extends Backbone.View
	tagName: 'div'
	className: 'header'
	template: Handlebars.compile '<div class="headerContents"><div class="title">Blimp</div></div>'

	initialize: () ->
		@headerMenuView = new HeaderMenu.View model: @model.headerMenuModel


	render: () ->
		@$el.html @template()
		@$el.find('.headerContents').append @headerMenuView.render().el
		return @
