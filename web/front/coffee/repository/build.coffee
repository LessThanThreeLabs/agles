window.Build = {}


class Build.Model extends Backbone.Model
	urlRoot: 'builds'

	validate: (attributes) ->
		return


class Build.View extends Backbone.View
	tagName: 'div'
	className: 'build'
	template: Handlebars.compile '<div class="number">{{number}}</div>
		<div class="status {{status}}">{{status}}</div>'
	events: 'click': 'clickHandler'

	render: () ->
		@$el.html @template
			number: @model.get 'number'
			status: @model.get 'status'
		return @


	clickHandler: () ->
		@$el.toggleClass 'selected'
