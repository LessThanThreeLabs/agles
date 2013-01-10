window.Change = {}


class Change.Model extends Backbone.Model
	ALLOWED_STATUS: ['passed', 'running', 'failed', 'queued']
	subscribeUrl: 'changes'
	subscribeId: null
	urlRoot: 'changes'
	defaults:
		number: null
		status: 'queued'
		selected: false


	initialize: () =>
		@_blah = Math.random()
		@subscribeId = @get 'id'

		if globalRouterModel.get('changeId') is @get('id')
			@set 'selected', true,
				error: (model, error) => console.error error


	toggleSelected: () =>
		@set 'selected', not @get 'selected'


	validate: (attributes) =>
		if typeof attributes.number isnt 'number' or attributes.number < 0
			return new Error 'Invalid number: ' + attributes.number

		if attributes.status not in @ALLOWED_STATUS
			return new Error 'Invalid status: ' + attributes.status

		if typeof attributes.selected isnt 'boolean'
			return new Error 'Invalid selected state: ' + attributes.selected

		return


	onUpdate: (data) =>
		if data.type is 'change started' or data.type is 'change finished'
			attributesToSet =
				status: data.contents.status
			@set attributesToSet,
				error: (model, error) => console.error error


class Change.View extends Backbone.View
	tagName: 'div'
	className: 'change'
	template: Handlebars.compile '<div class="number">{{number}}</div>
		<div class="statusText">{{status}}</div>'
	events: 'click': '_clickHandler'


	initialize: () =>
		@model.on 'change:status', @render, @
		@model.on 'change:selected', @_handleSelected, @

		@model.subscribe()


	onDispose: () =>
		@model.unsubscribe()
		@model.off null, null, @


	render: () =>
		@$el.html @template
			number: @model.get 'number'
			status: @model.get 'status'
			
		@$el.removeClass().addClass('change').addClass @model.get 'status'

		@_handleSelected()

		return @


	_clickHandler: () =>
		@model.toggleSelected()


	_handleSelected: () =>
		if @model.get 'selected' then @$el.addClass 'selected'
		else @$el.removeClass 'selected'
