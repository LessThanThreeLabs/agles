window.ChangeOutlineStage = {}


ChangeOutlineStage.AllowedTypes =
	SETUP: 'setup'
	COMPILE: 'compile'
	TEST: 'test'


ChangeOutlineStage.AllowedStatuses =
	RUNNING: 'running'
	FAILED: 'failed'
	PASSED: 'passed'


class ChangeOutlineStage.Model extends Backbone.Model
	defaults:
		type: null
		name: null
		status: ChangeOutlineStage.AllowedStatuses.RUNNING
		beginTime: null
		endTime: null
		selected: false
	subscribeUrl: 'buildOutputs'
	subscribeId: null


	initialize: () =>
		@subscribeId = @get 'id'

		if globalRouterModel.get('changeView') is @getNameIdendtifier()
			@set 'selected', true,
				error: (model, error) => console.error error

		@set 'status', @_getStatusFromReturnCode(@get 'returnCode'),
			error: (model, error) => console.error error


	_getStatusFromReturnCode: (returnCode) =>
		if not returnCode?
			return ChangeOutlineStage.AllowedStatuses.RUNNING
		else if returnCode is 0
			return ChangeOutlineStage.AllowedStatuses.PASSED
		else
			return ChangeOutlineStage.AllowedStatuses.FAILED


	validate: (attributes) =>
		foundType = false
		for typeName, typeValue of ChangeOutlineStage.AllowedTypes
			foundType = true if typeValue is attributes.type

		if not foundType
			return new Error 'Invaild type: ' + attributes.type

		foundStatus = false
		for statusName, statusValue of ChangeOutlineStage.AllowedStatuses
			foundStatus = true if statusValue is attributes.status

		if not foundStatus
			return new Error 'Invaild status: ' + attributes.status

		if typeof attributes.name isnt 'string' or attributes.name is ''
			return new Error 'Invalid name: ' + attributes.name

		if attributes.beginTime? and (typeof attributes.beginTime isnt 'number' or attributes.beginTime < 0)
			return new Error 'Invalid begin time: ' + attributes.beginTime

		if attributes.endTime? and (typeof attributes.endTime isnt 'number' or attributes.endTime < 0)
			return new Error 'Invalid end time: ' + attributes.endTime

		return


	getNameIdendtifier: () =>
		return @get('type') + ':' + @get('name')


	onUpdate: (data) =>
		if data.type is 'return code added'
			if data.contents is 0
				@set 'status', ChangeOutlineStage.AllowedStatuses.PASSED,
					error: (model, error) => console.error error
			else
				@set 'status', ChangeOutlineStage.AllowedStatuses.FAILED,
					error: (model, error) => console.error error


class ChangeOutlineStage.View extends Backbone.View
	tagName: 'div'
	className: 'changeOutlineStage'
	template: Handlebars.compile '<div class="changeOutlineStageContents">
			<div class="changeOutlineStageName">{{name}}</div>
			<div class="changeOutlineStageStatus {{status}}">{{status}}</div>
			<div class="changeOutlineStageSpinnerContainer"></div>
		</div>'
	events: 'click': '_clickHandler'
	_spinner: null


	initialize: () =>
		@model.on 'change', @render, @
		
		globalRouterModel.on 'change:changeView', (() =>
			@model.set 'selected', globalRouterModel.get('changeView') is @model.getNameIdendtifier(),
				error: (model, error) => console.error error
		), @

		@model.subscribe()


	onDispose: () =>
		@model.off null, null, @
		globalRouterModel.off null, null, @

		@model.unsubscribe()


	render: () =>
		statusToShow = if @model.get('status') is 'running' then null else @model.get 'status'

		@$el.html @template
			name: @model.get 'name'
			status: statusToShow
		@_fixSelectedState()

		showSpinner = @model.get('status') is 'running'
		setTimeout (() => @_setSpinnerState showSpinner), 0

		return @


	_setSpinnerState: (spinnerOn) =>
		if spinnerOn
			options =
				lines: 17
				length: 7
				width: 2
				radius: 5
				corners: 1
				color: '#A0A0A0'
				speed: 1.0
				trail: 50
				hwaccel: true
				className: 'spinner'
			@$('.changeOutlineStageSpinnerContainer').spin options
		else
			@$('.changeOutlineStageSpinnerContainer').spin false
		


	_fixSelectedState: () =>
		@$el.toggleClass 'selected', @model.get 'selected'


	_clickHandler: (event) =>
		globalRouterModel.set 'changeView', @model.getNameIdendtifier(),
			error: (model, error) => console.error error
