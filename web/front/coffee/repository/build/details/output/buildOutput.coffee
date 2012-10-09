window.BuildOutput = {}


class BuildOutput.Model extends Backbone.Model
	urlRoot: 'buildOutputs'

	initialize: () ->


class BuildOutput.View extends Backbone.View
	tagName: 'div'
	className: 'buildOutput'
	template: Handlebars.compile ''

	initialize: () ->
		@model.on 'change:text', (model, text) =>
			for line in text
				displayLine = $ '<div/>',
					class: 'buildOutputLine'
					text: line
				$('.buildOutput').append displayLine


	render: () ->
		@$el.html @template()
		return @
