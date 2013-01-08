window.ChangeOutlineStage = {}


ChangeOutlineStage.AllowedTypes =
	SETUP: 'setup'
	COMPILE: 'compile'
	TEST: 'test'


ChangeOutlineStage.AllowedStatuses =
	QUEUED: 'queued'
	RUNNING: 'running'
	FAILED: 'failed'
	PASSED: 'passed'


class ChangeOutlineStage.Model extends Backbone.Model
	defaults:
		type: null
		title: null
		status: ChangeOutlineStage.AllowedStatuses.QUEUED
		beginTime: null
		endTime: null
	subscribeUrl: 'buildOutputs'
	subscribeId: null


	initialize: () =>
		@subscribeId = @get 'id'


	validate: (attributes) =>
		foundType = false
		for type of ChangeOutlineStage.AllowedTypes
			foundType = true if type is attributes.type

		if not foundType
			return new Error 'Invaild type: ' + attributes.type

		foundStatus = false
		for status of ChangeOutlineStage.AllowedStatuses
			foundStatus = true if status is attributes.status

		if not foundStatus
			return new Error 'Invaild status: ' + attributes.status

		if typeof attributes.title isnt 'string' or attributes.title is ''
			return new Error 'Invalid title: ' + attributes.title

		if attributes.beginTime? and (typeof attributes.beginTime isnt 'number' or attributes.beginTime < 0)
			return new Error 'Invalid begin time: ' + attributes.beginTime

		if attributes.endTime? and (typeof attributes.endTime isnt 'number' or attributes.endTime < 0)
			return new Error 'Invalid end time: ' + attributes.endTime

		return


	onUpdate: (data) =>
		console.log 'need to handle new data...'
		console.log data


class ChangeOutlineStage.View extends Backbone.View
	tagName: 'div'
	className: 'changeOutlineStage'
	template: Handlebars.compile '<div class=changeOutlineStageTitle">{{title}}</div>
		<div class="changeOutlineStageStatus">{{status}}</div>'
	events: 'click': '_clickHandler'


	initialize: () =>
		@model.on 'change', @render, @
		@model.subscribe()


	onDispose: () =>
		@model.off null, null, @
		@model.unsubscribe()


	render: () =>
		@$el.html @template
			title: @model.get 'title'
			status: @model.get 'status'
		return @


	_clickHandler: (event) =>
		globalRouterModel.set 'changeView', @model.get('title'),
			error: (model, error) => console.error error
