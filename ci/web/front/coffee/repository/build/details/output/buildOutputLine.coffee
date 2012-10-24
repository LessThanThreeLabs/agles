window.BuildOutputLine = {}


class BuildOutputLine.Model extends Backbone.Model

	initialize: () =>


class BuildOutputLine.View extends Backbone.View
	tagName: 'div'
	className: 'buildOutputLine'
	template: Handlebars.compile '<div class="buildOutputLineNumber">{{number}}</div>
		<div class="buildOutputLineText">{{text}}</div>'

	render: () ->
		@$el.html @template
			number: @model.get 'number'
			text: @model.get 'text'
		return @
