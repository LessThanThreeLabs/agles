window.BuildOutput = {}


class BuildOutput.Model extends Backbone.Model
	urlRoot: 'buildOutputs'

	initialize: () ->


class BuildOutput.View extends Backbone.View
	tagName: 'div'
	className: 'buildOutput'
	template: Handlebars.compile '<div class="buildOutputHeader">Console Output:</div>
		<div class="buildOutputText"></div>'

	initialize: () ->
		@model.on 'change:text', (model, text) =>
			for line in text
				displayLine = $ '<div/>',
					class: 'buildOutputLine'
					text: line
				$('.buildOutputText').append displayLine


	render: () ->
		@$el.html @template()
		return @
