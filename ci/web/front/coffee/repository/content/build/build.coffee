window.Build = {}


class Build.Model extends Backbone.Model
	ALLOWED_STATUS: ['success', 'waiting', 'failed']

	urlRoot: 'builds'
	defaults:
		status: 'waiting'
		selected: false


	initialize: () =>
		if window.globalRouterModel.get('buildId') is @get('id')
			@set 'selected', true


	toggleSelected: () =>
		@set 'selected', not @get 'selected'


	validate: (attributes) =>
		if attributes.status? and attributes.status not in @ALLOWED_STATUS
			return new Error 'Invalid status'
		return


class Build.View extends Backbone.View
	tagName: 'div'
	className: 'build'
	template: Handlebars.compile '<div class="number">{{number}}</div>
		<div class="statusText">{{status}}</div>'
	events: 'click': '_clickHandler'

	initialize: () =>
		@model.on 'chaneg:status', @_handleStatusChange
		@model.on 'change:selected', @_handleSelected


	render: () =>
		@$el.html @template
			number: @model.get 'number'
			status: @model.get 'status'

		@_handleSelected()
		@_handleStatusChange()

		return @


	_clickHandler: () =>
		@model.toggleSelected()


	_handleSelected: () =>
		if @model.get 'selected' then @$el.addClass 'selected'
		else @$el.removeClass 'selected'


	_handleStatusChange: () =>
		@$el.removeClass @model.ALLOWED_STATUS.join ' '
		@$el.addClass @model.get 'status'
