window.ConsoleTextOutputLine = {}


class ConsoleTextOutputLine.Model extends Backbone.Model
	defaults:
		number: null
		text: null


	validate: (attributes) =>
		if typeof attributes.number isnt 'number' or attributes.number < 0
			return new Error 'Invalid number (make sure it is not a string): ' + attributes.number

		if typeof attributes.text isnt 'string'
			return new Error 'Invalid text (make sure it is a string): ' + attributes.text

		return


class ConsoleTextOutputLine.View extends Backbone.View
	tagName: 'div'
	className: 'consoleTextOutputLine'
	template: Handlebars.compile '<div class="number">{{number}}</div>
		<div class="text">{{text}}</div>'


	initialize: () =>
		@model.on 'change', @render, @


	onDispose: () =>
		@model.off null, null, @


	render: () ->
		@$el.html @template
			number: @model.get 'number'
			text: @model.get 'text'
		return @
