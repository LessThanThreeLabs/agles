window.Header = {}


class Header.Model extends Backbone.Model

	initialize: () ->


class Header.View extends Backbone.View
	tagName: 'div'
	className: 'repository'
	template: Handlebars.compile '<div class="header">Blimp</div>'

	initialize: () ->


	render: () ->
		@$el.html @template()
		return @
