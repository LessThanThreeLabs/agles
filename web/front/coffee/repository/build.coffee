window.Build = {}


class Build.Model extends Backbone.Model
	urlRoot: 'builds'
	defaults:
		selected: false

	toggleSelected: () =>
		@set 'selected', not @get 'selected'


class Build.View extends Backbone.View
	tagName: 'div'
	className: 'build'
	template: Handlebars.compile '<div class="number">{{number}}</div>
		<div class="status {{status}}">{{status}}</div>'
	events: 'click': 'clickHandler'

	initialize: () =>
		@model.on 'change:selected', @handleSelected


	render: () =>
		@$el.html @template
			number: @model.get 'number'
			status: @model.get 'status'
		return @


	clickHandler: () =>
		@model.toggleSelected()


	handleSelected: () =>
		if @model.get 'selected' then @$el.addClass 'selected'
		else @$el.removeClass 'selected'
