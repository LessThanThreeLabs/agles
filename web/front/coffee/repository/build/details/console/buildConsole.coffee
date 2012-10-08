window.BuildConsole = {}


class BuildConsole.Model extends Backbone.Model
	urlRoot: 'buildOutputs'

	initialize: () ->


class BuildConsole.View extends Backbone.View
	tagName: 'div'
	className: 'buildOutput'
	template: Handlebars.compile ''

	initialize: () ->


	render: () ->
		@$el.html @template()
		return @
