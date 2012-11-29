window.ConsoleTextOutputLine = {}


class ConsoleTextOutputLine.Model extends Backbone.Model
	defaults:
		number: null
		text: null


class ConsoleTextOutputLine.View extends Backbone.View
	tagName: 'div'
	className: 'consoleTextOutputLine'
	template: Handlebars.compile '<div class="number">{{number}}</div>
		<div class="text">{{text}}</div>'


	initialize: () =>
		@model.on 'change', @render


	onDispose: () =>
		@model.off null, null, @


	render: () ->
		@$el.html @template
			number: @model.get 'number'
			text: @model.get 'text'
		return @
