window.Build = {}


class Build.Model extends Backbone.Model
	ALLOWED_STATUS: ['passed', 'running', 'failed', 'queued']

	urlRoot: 'builds'
	defaults:
		status: 'queued'
		selected: false


	initialize: () =>
		if window.globalRouterModel.get('buildId') is @get('id')
			@set 'selected', true,
				error: (model, error) => console.error error


	toggleSelected: () =>
		@set 'selected', not @get 'selected'


	validate: (attributes) =>
		if attributes.status not in @ALLOWED_STATUS
			return new Error 'Invalid status'
		return


class Build.View extends Backbone.View
	tagName: 'div'
	className: 'build'
	template: Handlebars.compile '<div class="number">{{number}}</div>
		<div class="statusText">{{status}}</div>'
	events: 'click': '_clickHandler'


	initialize: () =>
		@model.on 'chaneg:status', @render
		@model.on 'change:selected', @_handleSelected


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @template
			number: @model.get 'number'
			status: @model.get 'status'
			
		@$el.addClass @model.get 'status'

		@_handleSelected()

		return @


	_clickHandler: () =>
		@model.toggleSelected()


	_handleSelected: () =>
		if @model.get 'selected' then @$el.addClass 'selected'
		else @$el.removeClass 'selected'
