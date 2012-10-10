window.Header = {}


class Header.Model extends Backbone.Model

	initialize: () ->


class Header.View extends Backbone.View
	tagName: 'div'
	className: 'header'
	template: Handlebars.compile '<div class="title">Blimp</div>'

	initialize: () ->


	render: () ->
		@$el.html @template()
		return @
