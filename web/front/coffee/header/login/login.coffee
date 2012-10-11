window.Login = {}


class Login.Model extends Backbone.Model

	initialize: () ->


class Login.View extends Backbone.View
	tagName: 'div'
	className: 'login'
	template: Handlebars.compile 'Login'

	initialize: () ->


	render: () ->
		@$el.html @template()
		return @
