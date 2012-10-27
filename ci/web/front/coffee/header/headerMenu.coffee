window.HeaderMenu = {}


class HeaderMenu.Model extends Backbone.Model

	initialize: () ->
		@loginModel = new Login.Model()


class HeaderMenu.View extends Backbone.View
	tagName: 'div'
	className: 'headerMenu'
	template: Handlebars.compile ''

	initialize: () ->
		@loginView = new Login.View model: @model.loginModel


	render: () ->
		@$el.html @template()
		@$el.append @loginView.render().el
		return @
