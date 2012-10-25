window.Welcome = {}


class Welcome.Model extends Backbone.Model
	initialize: () ->


class Welcome.View extends Backbone.View
	tagName: 'div'
	className: 'welcome'
	template: Handlebars.compile '<img src="img/awesomeFace.png">'

	initialize: () ->

	render: () ->
		@$el.html @template()
		return @
